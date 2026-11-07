import 'dart:math' as math;

import 'battle_tuning.dart';
import 'battle_types.dart';

/// 单发子弹相对机身的横向偏移与发射角度（弧度，0 为正上方）。
class PlayerShot {
  const PlayerShot(this.offsetX, this.angle);

  final double offsetX;
  final double angle;
}

/// 五级弹道：等级即索引，0 级占位以便直接按等级取值。
const List<List<PlayerShot>> kPlayerWeaponPatterns = [
  [],
  [PlayerShot(0, 0)],
  [PlayerShot(-5, 0), PlayerShot(5, 0)],
  [
    PlayerShot(-6, 0),
    PlayerShot(6, 0),
    PlayerShot(-11, -0.16),
    PlayerShot(11, 0.16),
  ],
  [
    PlayerShot(-7, 0),
    PlayerShot(0, 0),
    PlayerShot(7, 0),
    PlayerShot(-13, -0.17),
    PlayerShot(13, 0.17),
  ],
  [
    PlayerShot(-8, 0),
    PlayerShot(0, 0),
    PlayerShot(8, 0),
    PlayerShot(-13, -0.14),
    PlayerShot(13, 0.14),
    PlayerShot(-16, -0.3),
    PlayerShot(16, 0.3),
  ],
  [
    PlayerShot(-9, 0),
    PlayerShot(0, 0),
    PlayerShot(9, 0),
    PlayerShot(-14, -0.13),
    PlayerShot(14, 0.13),
    PlayerShot(-18, -0.28),
    PlayerShot(18, 0.28),
    PlayerShot(-21, -0.43),
    PlayerShot(21, 0.43),
  ],
];

/// 按当前火力等级生成一帧的玩家弹道。
List<Bullet> buildPlayerShots(Player player) {
  final shots = <Bullet>[];
  appendPlayerShots(player, shots);
  return shots;
}

/// 按当前火力等级把弹道追加到已有列表，战斗循环里避免每帧中转列表。
void appendPlayerShots(Player player, List<Bullet> out) {
  final level = player.weaponLevel.clamp(1, Player.maxWeaponLevel);
  final muzzleY = player.y - 16;
  for (final shot in kPlayerWeaponPatterns[level]) {
    out.add(
      Bullet(
        x: player.x + shot.offsetX,
        y: muzzleY,
        vx: math.sin(shot.angle) * kPlayerBulletSpeed,
        vy: -math.cos(shot.angle) * kPlayerBulletSpeed,
        radius: 3.4,
        damage: 1,
        fromPlayer: true,
      ),
    );
  }
}

/// 僚机的一帧弹道：左右僚机的弹道略微向外展开，避免与主机弹道重叠。
void appendWingmanShots(Wingman wingman, List<Bullet> out) {
  final angle = wingman.side * kWingmanSpreadAngle;
  out.add(
    Bullet(
      x: wingman.x,
      y: wingman.y - 9,
      vx: math.sin(angle) * kWingmanBulletSpeed,
      vy: -math.cos(angle) * kWingmanBulletSpeed,
      radius: 3,
      damage: kWingmanBulletDamage,
      fromPlayer: true,
    ),
  );
}
