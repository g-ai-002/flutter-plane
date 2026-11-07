import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/battle/battle_controller.dart';
import '../game/battle/battle_types.dart';
import '../game/logic_rate.dart';
import '../services/sound_service.dart';
import 'battle_visuals.dart';
import 'draw_batches.dart';

/// 战场渲染组件：按固定步长推进逻辑，用 Canvas 绘制星空、战机、弹幕与爆炸。
///
/// 所有图形都是程序化矢量绘制，仓库不存放任何图片、字体或音频资源。
class BattleFieldComponent extends PositionComponent {
  BattleFieldComponent({
    required this.controller,
    required this.logicRate,
    this.fontFamily,
  }) : _clock = FixedStepClock(logicRate.step),
       super(priority: 1);

  final BattleController controller;
  final LogicRate logicRate;
  final String? fontFamily;
  final FixedStepClock _clock;

  final Paint _fill = Paint();
  final Paint _stroke = Paint()..style = PaintingStyle.stroke;
  final Paint _glow = Paint();
  final DotBatch _dots = DotBatch();
  final CapsuleBatch _capsules = CapsuleBatch();
  final Map<String, TextPainter> _textCache = {};

  static const int _whiteArgb = 0xFFFFFFFF;
  static const int _starStreakArgb = 0xFF7FD8FF;
  static final int _playerBulletGlowArgb = kPlayerBulletGlow.toARGB32();
  static final int _playerBulletBodyArgb = kPlayerBulletBody.toARGB32();

  Size _backgroundSize = Size.zero;
  Paint? _backgroundPaint;
  Paint? _nebulaTopLeft;
  Paint? _nebulaBottomRight;

  static final RRect _powerUpBox = RRect.fromRectAndRadius(
    Rect.fromCenter(center: Offset.zero, width: 21, height: 21),
    const Radius.circular(5),
  );

  @override
  void update(double dt) {
    _clock.advance(dt, (span) {
      controller.update(span);
      _flushEvents();
    });
  }

  void _flushEvents() {
    final events = controller.pendingEvents;
    if (events.isEmpty) return;
    var played = 0;
    for (final event in events) {
      // 同一步内重复的事件只播一次，用位掩码去重，避免每步新建 Set。
      final bit = 1 << event.index;
      if (played & bit != 0) continue;
      played |= bit;
      SoundService.play(_soundOf(event));
    }
    controller.clearEvents();
  }

  static GameSound _soundOf(BattleEvent event) => switch (event) {
    BattleEvent.shoot => GameSound.shoot,
    BattleEvent.explosion => GameSound.explosion,
    BattleEvent.bigExplosion => GameSound.bigExplosion,
    BattleEvent.powerUp => GameSound.powerUp,
    BattleEvent.playerHit => GameSound.playerHit,
    BattleEvent.shieldBreak => GameSound.powerUp,
    BattleEvent.bomb => GameSound.bomb,
    BattleEvent.waveStart => GameSound.warning,
    BattleEvent.bossAppear => GameSound.warning,
    BattleEvent.gameOver => GameSound.gameOver,
  };

  @override
  void render(Canvas canvas) {
    final world = controller.size;
    if (world.width <= 0 || world.height <= 0) return;
    final sx = size.x / world.width;
    final sy = size.y / world.height;
    if (sx <= 0 || sy <= 0) return;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.x, size.y));
    canvas.scale(sx, sy);
    _drawBackground(canvas, world);

    final shake = controller.shake;
    canvas.save();
    if (shake > 0.1) {
      final t = controller.elapsed;
      canvas.translate(
        math.sin(t * 71.3) * shake,
        math.cos(t * 59.7) * shake * 0.7,
      );
    }
    _drawStars(canvas);
    _drawPowerUps(canvas);
    _drawBullets(canvas);
    _drawEnemies(canvas);
    _drawPlayer(canvas);
    _drawParticles(canvas);
    _drawPopups(canvas);
    canvas.restore();

    if (controller.flash > 0.01) {
      _fill.color = Colors.white.withValues(
        alpha: controller.flash.clamp(0.0, 0.85) * 0.55,
      );
      canvas.drawRect(Rect.fromLTWH(0, 0, world.width, world.height), _fill);
    }
    canvas.restore();
  }

  // ------------------------------------------------------------ 背景与星空

  void _drawBackground(Canvas canvas, Size world) {
    if (_backgroundPaint == null || _backgroundSize != world) {
      _backgroundSize = world;
      final rect = Rect.fromLTWH(0, 0, world.width, world.height);
      _backgroundPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF070B1E), Color(0xFF0C1734), Color(0xFF05070F)],
          stops: [0, 0.52, 1],
        ).createShader(rect);
      _nebulaTopLeft = Paint()
        ..shader =
            const RadialGradient(colors: [Color(0x335C2E91), Color(0x00000000)])
                .createShader(
                  Rect.fromCircle(
                    center: Offset(world.width * 0.18, world.height * 0.18),
                    radius: world.width * 0.85,
                  ),
                );
      _nebulaBottomRight = Paint()
        ..shader =
            const RadialGradient(colors: [Color(0x2E1A6E8C), Color(0x00000000)])
                .createShader(
                  Rect.fromCircle(
                    center: Offset(world.width * 0.9, world.height * 0.78),
                    radius: world.width * 0.8,
                  ),
                );
    }
    final rect = Rect.fromLTWH(0, 0, world.width, world.height);
    canvas.drawRect(rect, _backgroundPaint!);
    canvas.drawRect(rect, _nebulaTopLeft!);
    canvas.drawRect(rect, _nebulaBottomRight!);
  }

  void _drawStars(Canvas canvas) {
    for (final star in controller.stars) {
      _dots.add(_whiteArgb, star.x, star.y, star.size, star.alpha);
      if (star.speed > 62) {
        _capsules.add(
          _starStreakArgb,
          star.x,
          star.y - 3.5,
          3.5,
          star.size * 0.9,
          star.alpha * 0.5,
        );
      }
    }
    _capsules.flush(canvas);
    _dots.flush(canvas);
  }

  // ------------------------------------------------------------ 玩家

  void _drawPlayer(Canvas canvas) {
    final player = controller.player;
    if (!player.alive) return;
    if (player.invuln > 0 && (controller.elapsed * 12).floor().isEven) return;

    canvas.save();
    canvas.translate(player.x, player.y);
    canvas.rotate(player.tilt * 0.16);

    // 尾焰
    final flicker = 10 + math.sin(controller.elapsed * 42) * 4;
    final flame = Path()
      ..moveTo(-4, 11)
      ..lineTo(0, 11 + flicker)
      ..lineTo(4, 11)
      ..close();
    _fill.color = const Color(0xBB2B6BFF);
    canvas.drawPath(flame, _fill);
    _fill.color = const Color(0xE67FD8FF);
    canvas.save();
    canvas.scale(0.55, 0.75);
    canvas.translate(0, 5);
    canvas.drawPath(flame, _fill);
    canvas.restore();

    final path = playerHullPath;
    _fill.color = kPlayerHullShadow;
    canvas.save();
    canvas.scale(1.18);
    canvas.drawPath(path, _fill);
    canvas.restore();
    _fill.color = kPlayerHull;
    canvas.drawPath(path, _fill);
    _stroke
      ..color = kPlayerTrim
      ..strokeWidth = 1.5;
    canvas.drawPath(path, _stroke);

    // 座舱与高光
    _fill.color = const Color(0xFFDDF7FF);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, -5), width: 5.4, height: 10),
      _fill,
    );
    _fill.color = const Color(0xCC7FD8FF);
    canvas.drawRect(const Rect.fromLTWH(-9.5, 3.4, 19, 2.2), _fill);

    if (player.shield > 0) {
      final pulse = 0.55 + 0.25 * math.sin(controller.elapsed * 9);
      _stroke
        ..color = const Color(0xFF7FD8FF).withValues(alpha: pulse)
        ..strokeWidth = 1.8;
      canvas.drawCircle(Offset.zero, 24, _stroke);
      _fill.color = const Color(0xFF7FD8FF).withValues(alpha: 0.08);
      canvas.drawCircle(Offset.zero, 24, _fill);
      _stroke
        ..color = const Color(0xFFB7F4FF).withValues(alpha: pulse * 0.8)
        ..strokeWidth = 2.2;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: 27),
        controller.elapsed * 2.2,
        1.1,
        false,
        _stroke,
      );
    }
    canvas.restore();
  }

  // ------------------------------------------------------------ 敌机

  void _drawEnemies(Canvas canvas) {
    for (final enemy in controller.enemies) {
      if (enemy.dead) continue;
      final visual = kEnemyVisuals[enemy.kind]!;
      canvas.save();
      canvas.translate(enemy.x, enemy.y);
      final appear = (enemy.age / 0.28).clamp(0.0, 1.0);
      final pulse = 0.9 + 0.1 * math.sin(enemy.age * 6);
      final hit = enemy.hitFlash > 0;

      if (enemy.isBoss) {
        _drawBoss(canvas, enemy, visual, appear, pulse, hit);
        canvas.restore();
        continue;
      }

      _fill.color = (hit ? Colors.white : visual.hull).withValues(
        alpha: appear,
      );
      canvas.drawPath(visual.path, _fill);
      _stroke
        ..color = (hit ? Colors.white : visual.trim).withValues(alpha: appear)
        ..strokeWidth = visual.strokeWidth;
      canvas.drawPath(visual.path, _stroke);

      // 核心与引擎光
      _fill.color = visual.core.withValues(alpha: appear * pulse);
      canvas.drawCircle(
        Offset(0, visual.coreOffsetY),
        visual.coreRadius,
        _fill,
      );
      _glow.color = kEnemyEngineGlow.withValues(alpha: appear * 0.8);
      canvas.drawCircle(Offset(0, enemy.radius * 0.62), 2.4, _glow);
      canvas.restore();
    }
  }

  void _drawBoss(
    Canvas canvas,
    Enemy boss,
    EnemyVisual visual,
    double appear,
    double pulse,
    bool hit,
  ) {
    _fill.color = (hit ? Colors.white : visual.hull).withValues(alpha: appear);
    canvas.drawPath(visual.path, _fill);
    _stroke
      ..color = (hit ? Colors.white : visual.trim).withValues(alpha: appear)
      ..strokeWidth = visual.strokeWidth;
    canvas.drawPath(visual.path, _stroke);

    // 侧翼炮塔
    _fill.color = kBossTurret.withValues(alpha: appear);
    for (final side in [-1, 1]) {
      canvas.drawCircle(Offset(side * 30.0, 8), 6.5, _fill);
      _stroke
        ..color = kBossTrim.withValues(alpha: appear)
        ..strokeWidth = 1.2;
      canvas.drawCircle(Offset(side * 30.0, 8), 6.5, _stroke);
    }
    // 核心
    _glow.color = kBossCoreGlow.withValues(alpha: appear * pulse * 0.35);
    canvas.drawCircle(Offset.zero, 20, _glow);
    _fill.color = visual.core.withValues(alpha: appear * pulse);
    canvas.drawCircle(Offset.zero, visual.coreRadius, _fill);
    _fill.color = Colors.white.withValues(alpha: appear * 0.9);
    canvas.drawCircle(Offset.zero, 4, _fill);

    // 受损裂纹
    if (boss.hpRatio < 0.5) {
      _stroke
        ..color = const Color(0xFFFF5252).withValues(alpha: appear * 0.8)
        ..strokeWidth = 1.2;
      canvas.drawLine(const Offset(-12, -4), const Offset(-4, 6), _stroke);
      canvas.drawLine(const Offset(18, 2), const Offset(26, 14), _stroke);
    }
  }

  // ------------------------------------------------------------ 弹幕

  void _drawBullets(Canvas canvas) {
    // 玩家弹：辉光 → 弹体 → 弹芯，三层各自合并成一次绘制。
    for (final bullet in controller.playerBullets) {
      _dots.add(_playerBulletGlowArgb, bullet.x, bullet.y, 8, 0.28);
    }
    _dots.flush(canvas);
    for (final bullet in controller.playerBullets) {
      _capsules.add(_playerBulletBodyArgb, bullet.x, bullet.y, 4, 6, 1);
      _capsules.add(_whiteArgb, bullet.x, bullet.y, 2.9, 2.2, 1);
    }
    _capsules.flush(canvas);

    // 敌弹：辉光、弹体、弹芯同样按颜色分桶批量绘制。
    for (final bullet in controller.enemyBullets) {
      _dots.add(
        enemyBulletArgb(bullet.kind),
        bullet.x,
        bullet.y,
        bullet.radius * 2.4,
        0.26,
      );
    }
    _dots.flush(canvas);
    for (final bullet in controller.enemyBullets) {
      _dots.add(
        enemyBulletArgb(bullet.kind),
        bullet.x,
        bullet.y,
        bullet.radius,
        1,
      );
    }
    _dots.flush(canvas);
    for (final bullet in controller.enemyBullets) {
      _dots.add(_whiteArgb, bullet.x, bullet.y, bullet.radius * 0.42, 0.85);
    }
    _dots.flush(canvas);
  }

  // ------------------------------------------------------------ 补给

  void _drawPowerUps(Canvas canvas) {
    for (final item in controller.powerUps) {
      final color = kPowerUpColors[item.kind]!;
      canvas.save();
      canvas.translate(item.x, item.y);
      canvas.rotate(item.age * 1.8);
      _fill.color = color.withValues(alpha: 0.18);
      canvas.drawCircle(Offset.zero, 17, _fill);
      _fill.color = const Color(0xFF101A33);
      canvas.drawRRect(_powerUpBox, _fill);
      _stroke
        ..color = color
        ..strokeWidth = 1.8;
      canvas.drawRRect(_powerUpBox, _stroke);
      canvas.restore();

      final label = kPowerUpLabels[item.kind]![0];
      final painter = _text(
        label,
        size: 11,
        color: color,
        weight: FontWeight.w700,
      );
      painter.paint(
        canvas,
        Offset(item.x - painter.width / 2, item.y - painter.height / 2),
      );
    }
  }

  // ------------------------------------------------------------ 粒子与飘字

  void _drawParticles(Canvas canvas) {
    for (final particle in controller.particles) {
      final fade = (1 - particle.progress).clamp(0.0, 1.0);
      switch (particle.kind) {
        case ParticleKind.spark:
        case ParticleKind.trail:
          _dots.add(
            particle.color,
            particle.x,
            particle.y,
            particle.size * (0.5 + fade * 0.5),
            fade,
          );
        case ParticleKind.smoke:
          _dots.add(
            particle.color,
            particle.x,
            particle.y,
            particle.size * (1 + particle.progress * 1.6),
            fade * 0.4,
          );
        case ParticleKind.ring:
          _stroke
            ..color = Color(particle.color).withValues(alpha: fade * 0.8)
            ..strokeWidth = 1.6;
          canvas.drawCircle(
            Offset(particle.x, particle.y),
            particle.size * (1 + particle.progress * 4),
            _stroke,
          );
        case ParticleKind.debris:
          _fill.color = Color(particle.color).withValues(alpha: fade);
          canvas.save();
          canvas.translate(particle.x, particle.y);
          canvas.rotate(particle.progress * 6);
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size * 2.2,
              height: particle.size * 0.9,
            ),
            _fill,
          );
          canvas.restore();
      }
    }
    _dots.flush(canvas);
  }

  void _drawPopups(Canvas canvas) {
    for (final popup in controller.popups) {
      final alpha = ((popup.life / 0.8) * 4).ceil() / 4;
      final color = Color(popup.color ?? 0xFFE8F6FF)
          .withValues(alpha: alpha.clamp(0.0, 1.0));
      final painter = _text(popup.text, size: 13, color: color);
      painter.paint(
        canvas,
        Offset(popup.x - painter.width / 2, popup.y - painter.height / 2),
      );
    }
  }

  TextPainter _text(
    String text, {
    double size = 12,
    Color color = Colors.white,
    FontWeight weight = FontWeight.w600,
  }) {
    final key = '$text|$size|${color.toARGB32()}|${weight.value}';
    final cached = _textCache[key];
    if (cached != null) return cached;
    if (_textCache.length > 90) {
      // 只淘汰最早的一条，避免缓存满了就整体清空导致下一帧集中重建。
      _textCache.remove(_textCache.keys.first);
    }
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          color: color,
          fontWeight: weight,
          letterSpacing: 0.4,
          fontFamily: fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    _textCache[key] = painter;
    return painter;
  }
}
