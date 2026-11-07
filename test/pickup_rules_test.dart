import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/game/battle/battle_tuning.dart';
import 'package:sky_fighter/game/battle/battle_types.dart';
import 'package:sky_fighter/game/battle/pickup_rules.dart';

Player buildPlayer() => Player(x: 200, y: 600);

void main() {
  group('火力补给', () {
    test('未满级时提升一级并提示当前等级', () {
      final player = buildPlayer();
      final outcome = applyPickup(PowerUpKind.weapon, player, multiplier: 1);
      expect(player.weaponLevel, 2);
      expect(outcome.text, '火力 2 级');
      expect(outcome.score, 0);
    });

    test('满级后折算成分数', () {
      final player = buildPlayer()..weaponLevel = Player.maxWeaponLevel;
      final outcome = applyPickup(PowerUpKind.weapon, player, multiplier: 4);
      expect(player.weaponLevel, Player.maxWeaponLevel);
      expect(outcome.score, kWeaponCapScore);
      expect(outcome.text, '+$kWeaponCapScore');
    });
  });

  group('护盾、炸弹与急速', () {
    test('护盾取较长剩余时间，不会缩短已有护盾', () {
      final player = buildPlayer()..shield = kShieldPickupDuration + 3;
      applyPickup(PowerUpKind.shield, player, multiplier: 1);
      expect(player.shield, kShieldPickupDuration + 3);

      final fresh = buildPlayer();
      applyPickup(PowerUpKind.shield, fresh, multiplier: 1);
      expect(fresh.shield, kShieldPickupDuration);
    });

    test('炸弹上限内补充，满额后折算分数', () {
      final player = buildPlayer()..bombs = 1;
      applyPickup(PowerUpKind.bomb, player, multiplier: 1);
      expect(player.bombs, 2);

      player.bombs = Player.maxBombs;
      final outcome = applyPickup(PowerUpKind.bomb, player, multiplier: 1);
      expect(player.bombs, Player.maxBombs);
      expect(outcome.score, kBombCapScore);
    });

    test('急速补给累加且不超过上限', () {
      final player = buildPlayer();
      applyPickup(PowerUpKind.rapid, player, multiplier: 1);
      expect(player.rapid, kRapidPickupDuration);

      player.rapid = kRapidMaxDuration - 1;
      applyPickup(PowerUpKind.rapid, player, multiplier: 1);
      expect(player.rapid, kRapidMaxDuration);
    });
  });

  group('分数与僚机', () {
    test('分数补给按连击倍率结算', () {
      final player = buildPlayer();
      final outcome = applyPickup(PowerUpKind.star, player, multiplier: 3);
      expect(outcome.score, kStarPickupScore * 3);
      expect(outcome.text, '+${kStarPickupScore * 3}');
    });

    test('僚机未满编时请求生成僚机', () {
      final player = buildPlayer();
      final outcome = applyPickup(PowerUpKind.wingman, player, multiplier: 1);
      expect(player.wingmen, 1);
      expect(outcome.spawnWingman, isTrue);
    });

    test('僚机满编后折算分数且不再生成', () {
      final player = buildPlayer()..wingmen = Player.maxWingmen;
      final outcome = applyPickup(PowerUpKind.wingman, player, multiplier: 1);
      expect(player.wingmen, Player.maxWingmen);
      expect(outcome.spawnWingman, isFalse);
      expect(outcome.score, kWingmanCapScore);
    });
  });

  test('所有补给类型都有可展示的提示', () {
    for (final kind in PowerUpKind.values) {
      final outcome = applyPickup(kind, buildPlayer(), multiplier: 1);
      expect(outcome.text, isNotEmpty, reason: '$kind 缺少提示');
    }
  });
}
