import 'dart:math' as math;

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
