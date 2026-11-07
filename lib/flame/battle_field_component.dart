import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/battle/battle_controller.dart';
import '../game/battle/battle_types.dart';
import '../game/logic_rate.dart';
import '../services/sound_service.dart';

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
  final Map<String, TextPainter> _textCache = {};

  Size _backgroundSize = Size.zero;
  Paint? _backgroundPaint;
  Paint? _nebulaTopLeft;
  Paint? _nebulaBottomRight;

  Path? _playerPath;
  Path? _scoutPath;
  Path? _fighterPath;
  Path? _bomberPath;
  Path? _elitePath;
  Path? _bossPath;

  @override
  void update(double dt) {
    _clock.advance(dt, (span) {
      controller.update(span);
      _flushEvents();
    });
  }

  void _flushEvents() {
    final events = controller.drainEvents().toSet();
    for (final event in events) {
      switch (event) {
        case BattleEvent.shoot:
          SoundService.play(GameSound.shoot);
        case BattleEvent.explosion:
          SoundService.play(GameSound.explosion);
        case BattleEvent.bigExplosion:
          SoundService.play(GameSound.bigExplosion);
        case BattleEvent.powerUp:
          SoundService.play(GameSound.powerUp);
        case BattleEvent.playerHit:
          SoundService.play(GameSound.playerHit);
        case BattleEvent.shieldBreak:
          SoundService.play(GameSound.powerUp);
        case BattleEvent.bomb:
          SoundService.play(GameSound.bomb);
        case BattleEvent.waveStart:
          SoundService.play(GameSound.warning);
        case BattleEvent.bossAppear:
          SoundService.play(GameSound.warning);
        case BattleEvent.gameOver:
          SoundService.play(GameSound.gameOver);
      }
    }
  }

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
      _fill.color = Colors.white.withValues(alpha: star.alpha);
      canvas.drawCircle(Offset(star.x, star.y), star.size, _fill);
      if (star.speed > 62) {
        _glow.color = const Color(0xFF7FD8FF)
            .withValues(alpha: star.alpha * 0.5);
        _glow.strokeWidth = star.size * 0.9;
        canvas.drawLine(
          Offset(star.x, star.y - 7),
          Offset(star.x, star.y),
          _glow,
        );
      }
    }
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

    final path = _playerPath ??= _buildPlayerPath();
    _fill.color = const Color(0xFF10306B);
    canvas.save();
    canvas.scale(1.18);
    canvas.drawPath(path, _fill);
    canvas.restore();
    _fill.color = const Color(0xFF2FA8FF);
    canvas.drawPath(path, _fill);
    _stroke
      ..color = const Color(0xFF9BE8FF)
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

  Path _buildPlayerPath() => Path()
    ..moveTo(0, -17)
    ..lineTo(4.5, -6)
    ..lineTo(14, 3)
    ..lineTo(14, 8.5)
    ..lineTo(5, 7)
    ..lineTo(3.2, 12)
    ..lineTo(-3.2, 12)
    ..lineTo(-5, 7)
    ..lineTo(-14, 8.5)
    ..lineTo(-14, 3)
    ..lineTo(-4.5, -6)
    ..close();

  // ------------------------------------------------------------ 敌机

  void _drawEnemies(Canvas canvas) {
    for (final enemy in controller.enemies) {
      if (enemy.dead) continue;
      canvas.save();
      canvas.translate(enemy.x, enemy.y);
      final appear = (enemy.age / 0.28).clamp(0.0, 1.0);
      final pulse = 0.9 + 0.1 * math.sin(enemy.age * 6);
      final hit = enemy.hitFlash > 0;

      if (enemy.isBoss) {
        _drawBoss(canvas, enemy, appear, pulse, hit);
        canvas.restore();
        continue;
      }

      final path = switch (enemy.kind) {
        EnemyKind.scout => _scoutPath ??= _buildScoutPath(),
        EnemyKind.fighter => _fighterPath ??= _buildFighterPath(),
        EnemyKind.bomber => _bomberPath ??= _buildBomberPath(),
        EnemyKind.elite => _elitePath ??= _buildElitePath(),
        EnemyKind.boss => _buildElitePath(),
      };

      final base = hit ? Colors.white : _hullColor(enemy.kind);
      _fill.color = base.withValues(alpha: appear);
      canvas.drawPath(path, _fill);
      _stroke
        ..color = (hit ? Colors.white : _trimColor(enemy.kind)).withValues(
          alpha: appear,
        )
        ..strokeWidth = enemy.kind == EnemyKind.elite ? 2 : 1.4;
      canvas.drawPath(path, _stroke);

      // 核心与引擎光
      _fill.color = _coreColor(enemy.kind).withValues(alpha: appear * pulse);
      canvas.drawCircle(
        Offset(0, enemy.kind == EnemyKind.elite ? 2 : 0),
        enemy.kind == EnemyKind.elite ? 5.5 : 3.2,
        _fill,
      );
      _glow.color = const Color(0xFFFF8A5C).withValues(alpha: appear * 0.8);
      canvas.drawCircle(Offset(0, enemy.radius * 0.62), 2.4, _glow);
      canvas.restore();
    }
  }

  void _drawBoss(
    Canvas canvas,
    Enemy boss,
    double appear,
    double pulse,
    bool hit,
  ) {
    final path = _bossPath ??= _buildBossPath();
    _fill.color = (hit ? Colors.white : const Color(0xFF3A1F4F)).withValues(
      alpha: appear,
    );
    canvas.drawPath(path, _fill);
    _stroke
      ..color = (hit ? Colors.white : const Color(0xFFFF6B9D)).withValues(
        alpha: appear,
      )
      ..strokeWidth = 2.2;
    canvas.drawPath(path, _stroke);

    // 侧翼炮塔
    _fill.color = const Color(0xFF6B2E63).withValues(alpha: appear);
    for (final side in [-1, 1]) {
      canvas.drawCircle(Offset(side * 30.0, 8), 6.5, _fill);
      _stroke
        ..color = const Color(0xFFFF8FB8).withValues(alpha: appear)
        ..strokeWidth = 1.2;
      canvas.drawCircle(Offset(side * 30.0, 8), 6.5, _stroke);
    }
    // 核心
    _glow.color = const Color(0xFFFFD54F)
        .withValues(alpha: appear * pulse * 0.35);
    canvas.drawCircle(Offset.zero, 20, _glow);
    _fill.color = const Color(0xFFFFD54F).withValues(alpha: appear * pulse);
    canvas.drawCircle(Offset.zero, 9, _fill);
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

  Path _buildScoutPath() => Path()
    ..moveTo(0, 12)
    ..lineTo(-11, -3)
    ..lineTo(-4, -7)
    ..lineTo(0, -3)
    ..lineTo(4, -7)
    ..lineTo(11, -3)
    ..close();

  Path _buildFighterPath() => Path()
    ..moveTo(0, 15)
    ..lineTo(-6, 3)
    ..lineTo(-16, -3)
    ..lineTo(-9, -9)
    ..lineTo(0, -5)
    ..lineTo(9, -9)
    ..lineTo(16, -3)
    ..lineTo(6, 3)
    ..close();

  Path _buildBomberPath() => Path()
    ..moveTo(0, 20)
    ..lineTo(-10, 10)
    ..lineTo(-20, 3)
    ..lineTo(-14, -8)
    ..lineTo(0, -12)
    ..lineTo(14, -8)
    ..lineTo(20, 3)
    ..lineTo(10, 10)
    ..close();

  Path _buildElitePath() => Path()
    ..moveTo(0, 25)
    ..lineTo(-9, 11)
    ..lineTo(-23, 4)
    ..lineTo(-16, -7)
    ..lineTo(-20, -16)
    ..lineTo(0, -11)
    ..lineTo(20, -16)
    ..lineTo(16, -7)
    ..lineTo(23, 4)
    ..lineTo(9, 11)
    ..close();

  Path _buildBossPath() => Path()
    ..moveTo(0, 38)
    ..lineTo(-15, 27)
    ..lineTo(-37, 19)
    ..lineTo(-46, 3)
    ..lineTo(-30, -5)
    ..lineTo(-38, -22)
    ..lineTo(-12, -14)
    ..lineTo(0, -27)
    ..lineTo(12, -14)
    ..lineTo(38, -22)
    ..lineTo(30, -5)
    ..lineTo(46, 3)
    ..lineTo(37, 19)
    ..lineTo(15, 27)
    ..close();

  Color _hullColor(EnemyKind kind) => switch (kind) {
    EnemyKind.scout => const Color(0xFF6E2431),
    EnemyKind.fighter => const Color(0xFF7C2A33),
    EnemyKind.bomber => const Color(0xFF5E1F3A),
    EnemyKind.elite => const Color(0xFF5A1B4C),
    EnemyKind.boss => const Color(0xFF3A1F4F),
  };

  Color _trimColor(EnemyKind kind) => switch (kind) {
    EnemyKind.scout => const Color(0xFFFF9E6B),
    EnemyKind.fighter => const Color(0xFFFF7A59),
    EnemyKind.bomber => const Color(0xFFFF6B8B),
    EnemyKind.elite => const Color(0xFFFF6BC4),
    EnemyKind.boss => const Color(0xFFFF6B9D),
  };

  Color _coreColor(EnemyKind kind) => switch (kind) {
    EnemyKind.scout => const Color(0xFFFFD166),
    EnemyKind.fighter => const Color(0xFFFFB347),
    EnemyKind.bomber => const Color(0xFFFF8A80),
    EnemyKind.elite => const Color(0xFFFF8FD1),
    EnemyKind.boss => const Color(0xFFFFD54F),
  };

  // ------------------------------------------------------------ 弹幕

  void _drawBullets(Canvas canvas) {
    for (final bullet in controller.playerBullets) {
      _glow.color = const Color(0xFF4FD1FF).withValues(alpha: 0.28);
      canvas.drawCircle(Offset(bullet.x, bullet.y), 8, _glow);
      _fill.color = const Color(0xFFB7F4FF);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(bullet.x, bullet.y),
            width: 6,
            height: 14,
          ),
          const Radius.circular(3),
        ),
        _fill,
      );
      _fill.color = Colors.white;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(bullet.x, bullet.y),
            width: 2.2,
            height: 8,
          ),
          const Radius.circular(1.1),
        ),
        _fill,
      );
    }
    for (final bullet in controller.enemyBullets) {
      final color = switch (bullet.kind) {
        1 => const Color(0xFFFF9E6B),
        2 => const Color(0xFFFF6BC4),
        _ => const Color(0xFFFFD54F),
      };
      _glow.color = color.withValues(alpha: 0.26);
      canvas.drawCircle(Offset(bullet.x, bullet.y), bullet.radius * 2.4, _glow);
      _fill.color = color;
      canvas.drawCircle(Offset(bullet.x, bullet.y), bullet.radius, _fill);
      _fill.color = Colors.white.withValues(alpha: 0.85);
      canvas.drawCircle(
        Offset(bullet.x, bullet.y),
        bullet.radius * 0.42,
        _fill,
      );
    }
  }

  // ------------------------------------------------------------ 补给

  void _drawPowerUps(Canvas canvas) {
    for (final item in controller.powerUps) {
      final color = switch (item.kind) {
        PowerUpKind.weapon => const Color(0xFFFFB347),
        PowerUpKind.shield => const Color(0xFF7FD8FF),
        PowerUpKind.bomb => const Color(0xFFFF6B6B),
        PowerUpKind.star => const Color(0xFFFFD54F),
      };
      canvas.save();
      canvas.translate(item.x, item.y);
      canvas.rotate(item.age * 1.8);
      _fill.color = color.withValues(alpha: 0.18);
      canvas.drawCircle(Offset.zero, 17, _fill);
      _fill.color = const Color(0xFF101A33);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 21, height: 21),
          const Radius.circular(5),
        ),
        _fill,
      );
      _stroke
        ..color = color
        ..strokeWidth = 1.8;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 21, height: 21),
          const Radius.circular(5),
        ),
        _stroke,
      );
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
      final color = Color(particle.color).withValues(alpha: fade);
      switch (particle.kind) {
        case ParticleKind.spark:
        case ParticleKind.trail:
          _fill.color = color;
          canvas.drawCircle(
            Offset(particle.x, particle.y),
            particle.size * (0.5 + fade * 0.5),
            _fill,
          );
        case ParticleKind.smoke:
          _fill.color = color.withValues(alpha: fade * 0.4);
          canvas.drawCircle(
            Offset(particle.x, particle.y),
            particle.size * (1 + particle.progress * 1.6),
            _fill,
          );
        case ParticleKind.ring:
          _stroke
            ..color = color.withValues(alpha: fade * 0.8)
            ..strokeWidth = 1.6;
          canvas.drawCircle(
            Offset(particle.x, particle.y),
            particle.size * (1 + particle.progress * 4),
            _stroke,
          );
        case ParticleKind.debris:
          _fill.color = color;
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
    if (_textCache.length > 90) _textCache.clear();
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
