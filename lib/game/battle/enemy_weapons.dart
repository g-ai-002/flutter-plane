import 'dart:math' as math;
import 'dart:ui';

import 'battle_types.dart';

Bullet _enemyBullet({
  required double x,
  required double y,
  required double angle,
  required double speed,
  required int kind,
}) {
  return Bullet(
    x: x,
    y: y,
    vx: math.cos(angle) * speed,
    vy: math.sin(angle) * speed,
    radius: kind == BulletKind.boss
        ? 5
        : (kind == BulletKind.plasma ? 4.6 : 4.2),
    damage: 1,
    fromPlayer: false,
    kind: kind,
  );
}

/// 以敌机为圆心均匀铺开的环形弹幕，可整体旋转。
List<Bullet> buildRadialVolley({
  required Offset origin,
  required int count,
  required double speed,
  int kind = BulletKind.spread,
  double phase = 0,
}) {
  if (count <= 0) return const [];
  return [
    for (var i = 0; i < count; i++)
      _enemyBullet(
        x: origin.dx,
        y: origin.dy,
        angle: phase + i * 2 * math.pi / count,
        speed: speed,
        kind: kind,
      ),
  ];
}

/// 朝目标点发射一簇扇形弹。
List<Bullet> buildAimedVolley({
  required Offset origin,
  required Offset target,
  required double speed,
  required int count,
  required double spread,
  int kind = BulletKind.aimed,
  double muzzleOffsetY = 6,
}) {
  if (count <= 0) return const [];
  final base = aimDirection(origin, target).direction;
  return [
    for (var i = 0; i < count; i++)
      _enemyBullet(
        x: origin.dx,
        y: origin.dy + muzzleOffsetY,
        angle: base + (i - (count - 1) / 2) * spread,
        speed: speed,
        kind: kind,
      ),
  ];
}

/// Boss 弹幕入口：按形态选择弹幕库，两种 Boss 共享同一个四段循环节奏。
List<Bullet> buildBossBarrage({
  required Enemy boss,
  required Offset target,
  required int cycle,
  required double speed,
  BossVariant variant = BossVariant.scorpion,
}) {
  return variant == BossVariant.leviathan
      ? _buildLeviathanBarrage(boss, target, cycle, speed)
      : _buildScorpionBarrage(boss, target, cycle, speed);
}

/// 赤蝎母舰：瞄准散射、环形弹幕、五连扇射、侧翼扫射。
List<Bullet> _buildScorpionBarrage(
  Enemy boss,
  Offset target,
  int cycle,
  double speed,
) {
  final origin = Offset(boss.x, boss.y);
  switch (cycle % 4) {
    case 0:
      return buildAimedVolley(
        origin: origin,
        target: target,
        speed: speed + 40,
        count: 3,
        spread: 0.15,
        kind: BulletKind.boss,
        muzzleOffsetY: 0,
      );
    case 1:
      final base = boss.age * 0.6;
      const count = 18;
      return [
        for (var i = 0; i < count; i++)
          _enemyBullet(
            x: boss.x,
            y: boss.y,
            angle: base + i * 2 * math.pi / count,
            speed: speed * 0.85,
            kind: BulletKind.boss,
          ),
      ];
    case 2:
      return buildAimedVolley(
        origin: origin,
        target: target,
        speed: speed + 60,
        count: 5,
        spread: 0.19,
        kind: BulletKind.boss,
        muzzleOffsetY: 0,
      );
    default:
      return [
        for (var side = -1; side <= 1; side += 2)
          for (var i = 0; i < 5; i++)
            _enemyBullet(
              x: boss.x + side * 26,
              y: boss.y + 12,
              angle: side * (0.42 + i * 0.18) + math.pi / 2,
              speed: speed,
              kind: BulletKind.boss,
            ),
      ];
  }
}

/// 深渊利维坦：双螺旋、交叉扇射、带缺口的弹幕墙、疏密相间的环形雨。
List<Bullet> _buildLeviathanBarrage(
  Enemy boss,
  Offset target,
  int cycle,
  double speed,
) {
  switch (cycle % 4) {
    case 0:
      final base = boss.age * 1.35;
      return [
        for (var arm = 0; arm < 2; arm++)
          for (var i = 0; i < 6; i++)
            _enemyBullet(
              x: boss.x,
              y: boss.y,
              angle: base + arm * math.pi + i * 0.26,
              speed: speed * 0.95,
              kind: BulletKind.plasma,
            ),
      ];
    case 1:
      return [
        for (final side in [-1, 1])
          ...buildAimedVolley(
            origin: Offset(boss.x + side * 32.0, boss.y + 10),
            target: target,
            speed: speed + 25,
            count: 6,
            spread: 0.1,
            kind: BulletKind.plasma,
            muzzleOffsetY: 0,
          ),
      ];
    case 2:
      // 九列弹幕墙留出一个缺口，逼迫玩家横向转移。
      final gap = ((target.dx - 22) / 44.5).round().clamp(0, 8);
      return [
        for (var i = 0; i < 9; i++)
          if (i != gap)
            _enemyBullet(
              x: 22 + i * 44.5,
              y: boss.y + 12,
              angle: math.pi / 2,
              speed: speed * 0.92,
              kind: BulletKind.plasma,
            ),
      ];
    default:
      final base = boss.age * 0.35;
      const count = 20;
      return [
        for (var i = 0; i < count; i++)
          _enemyBullet(
            x: boss.x,
            y: boss.y,
            angle: base + i * 2 * math.pi / count,
            speed: speed * (i.isEven ? 0.72 : 1.02),
            kind: BulletKind.plasma,
          ),
      ];
  }
}
