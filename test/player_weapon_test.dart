import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/game/battle/battle_types.dart';
import 'package:sky_fighter/game/battle/player_weapon.dart';

void main() {
  group('玩家弹道', () {
    test('一级火力单发直射', () {
      final player = Player(x: 200, y: 600);
      final shots = buildPlayerShots(player);

      expect(shots, hasLength(1));
      expect(shots.single.x, 200);
      expect(shots.single.y, 584);
      expect(shots.single.vx, 0);
      expect(shots.single.vy, -kPlayerBulletSpeed);
      expect(shots.single.fromPlayer, isTrue);
    });

    test('三级火力四发且左右对称', () {
      final player = Player(x: 200, y: 600)..weaponLevel = 3;
      final shots = buildPlayerShots(player);

      expect(shots, hasLength(4));
      expect(shots.map((shot) => shot.x), containsAll([194, 206, 189, 211]));
      final left = shots.firstWhere((shot) => shot.x < 200 && shot.vx < 0);
      final right = shots.firstWhere((shot) => shot.x > 200 && shot.vx > 0);
      expect(left.vx, closeTo(-right.vx, 0.0001));
      expect(left.vy, closeTo(right.vy, 0.0001));
    });

    test('五级火力七发并保持散射速度', () {
      final player = Player(x: 200, y: 600)..weaponLevel = 5;
      final shots = buildPlayerShots(player);

      expect(shots, hasLength(7));
      for (final shot in shots) {
        expect(
          math.sqrt(shot.vx * shot.vx + shot.vy * shot.vy),
          closeTo(kPlayerBulletSpeed, 0.001),
        );
        expect(shot.vy, lessThan(0));
      }
    });

    test('等级越界时收敛到有效弹道', () {
      final low = Player(x: 200, y: 600)..weaponLevel = 0;
      expect(buildPlayerShots(low), hasLength(1));

      final high = Player(x: 200, y: 600)
        ..weaponLevel = Player.maxWeaponLevel + 3;
      expect(buildPlayerShots(high), hasLength(7));
    });
  });
}
