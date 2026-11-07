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
    radius: kind == BulletKind.boss ? 5 : 4.2,
    damage: 1,
    fromPlayer: false,
    kind: kind,
  );
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

/// Boss 的四段弹幕循环：瞄准散射、环形弹幕、五连扇射、侧翼扫射。
List<Bullet> buildBossBarrage({
  required Enemy boss,
  required Offset target,
  required int cycle,
  required double speed,
}) {
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
