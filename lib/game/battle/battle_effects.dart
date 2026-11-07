import 'dart:math' as math;
import 'dart:ui';

import 'battle_types.dart';

/// 战场特效：粒子、飘字与星空。
///
/// 与战斗判定解耦，只负责视觉元素的生命周期与生成参数，便于单独测试与调优。
class BattleEffects {
  BattleEffects(this._rng, this._starRng);

  static const int maxTrailParticles = 420;
  static const int maxParticles = 460;
  static const int maxPopups = 60;

  final math.Random _rng;
  final math.Random _starRng;

  final List<Particle> particles = [];
  final List<ScorePopup> popups = [];
  final List<Star> stars = [];

  void clear() {
    particles.clear();
    popups.clear();
  }

  void resetStars(Size world) {
    stars.clear();
    final count = (world.width * world.height / 5200).round().clamp(40, 110);
    for (var i = 0; i < count; i++) {
      stars.add(
        Star(
          x: _starRng.nextDouble() * world.width,
          y: _starRng.nextDouble() * world.height,
          speed: 18 + _starRng.nextDouble() * 72,
          size: 0.6 + _starRng.nextDouble() * 1.5,
          alpha: 0.18 + _starRng.nextDouble() * 0.6,
        ),
      );
    }
  }

  void update(double dt) {
    for (final particle in particles) {
      particle.life -= dt;
      final damping = math.exp(-particle.drag * dt);
      particle.vx *= damping;
      particle.vy *= damping;
      particle.x += particle.vx * dt;
      particle.y += particle.vy * dt;
    }
    particles.removeWhere((particle) => particle.dead);

    for (final popup in popups) {
      popup.life -= dt;
      popup.y -= 24 * dt;
    }
    popups.removeWhere((popup) => popup.dead);
  }

  void updateStars(double dt, Size world) {
    for (final star in stars) {
      star.y += star.speed * dt;
      if (star.y > world.height + 4) {
        star.y = -4;
        star.x = _starRng.nextDouble() * world.width;
      }
    }
  }

  /// 战机尾焰：持续小颗粒，护盾展开时换成蓝色。
  void addPlayerTrail(Offset position, {required bool shielded}) {
    particles.add(
      Particle(
        x: position.dx + (_rng.nextDouble() - 0.5) * 6,
        y: position.dy + 14,
        vx: (_rng.nextDouble() - 0.5) * 14,
        vy: 90,
        life: 0.26,
        size: 2.4 + _rng.nextDouble() * 1.6,
        color: shielded ? 0xFF7FD8FF : 0xFF4FD1FF,
        kind: ParticleKind.trail,
        drag: 2.4,
      ),
    );
    _trim(maxTrailParticles);
  }

  void addPopup(ScorePopup popup) {
    popups.add(popup);
    if (popups.length > maxPopups) {
      popups.removeRange(0, popups.length - maxPopups);
    }
  }

  /// 敌机爆炸：火花、烟雾、冲击环，大型目标追加碎片。
  void explode(Offset position, {required bool big, required int color}) {
    burst(
      position,
      count: big ? 26 : 12,
      color: color,
      speed: big ? 240 : 150,
      size: big ? 3.4 : 2.2,
      life: big ? 0.8 : 0.5,
    );
    burst(
      position,
      count: big ? 10 : 4,
      color: 0xFF2A3358,
      speed: big ? 90 : 55,
      size: big ? 9 : 5,
      kind: ParticleKind.smoke,
      life: big ? 1.1 : 0.7,
    );
    burst(
      position,
      count: 2,
      color: 0xFFFFFFFF,
      speed: 40,
      size: big ? 18 : 9,
      kind: ParticleKind.ring,
      life: 0.36,
    );
    if (big) {
      burst(
        position,
        count: 8,
        color: 0xFFFFD54F,
        speed: 190,
        size: 3,
        kind: ParticleKind.debris,
        life: 0.9,
      );
    }
  }

  void spark(Offset position, int color) {
    burst(position, count: 3, color: color, speed: 90, size: 1.8, life: 0.22);
  }

  /// 向四周随机方向喷射粒子，速度、大小与寿命都带随机抖动。
  void burst(
    Offset position, {
    required int count,
    required int color,
    double speed = 160,
    double size = 2.6,
    ParticleKind kind = ParticleKind.spark,
    double life = 0.5,
  }) {
    for (var i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final velocity = speed * (0.3 + _rng.nextDouble() * 0.9);
      particles.add(
        Particle(
          x: position.dx,
          y: position.dy,
          vx: math.cos(angle) * velocity,
          vy: math.sin(angle) * velocity,
          life: life * (0.6 + _rng.nextDouble() * 0.7),
          size: size * (0.7 + _rng.nextDouble() * 0.7),
          color: color,
          kind: kind,
          drag: kind == ParticleKind.smoke ? 1.1 : 2.2,
        ),
      );
    }
    _trim(maxParticles);
  }

  void _trim(int limit) {
    if (particles.length > limit) {
      particles.removeRange(0, particles.length - limit);
    }
  }
}
