import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/game/battle/battle_tuning.dart';
import 'package:sky_fighter/game/battle/battle_types.dart';

void main() {
  group('难度曲线', () {
    test('首波为基准难度，之后逐波线性提高', () {
      expect(waveDifficulty(0), 1);
      expect(waveDifficulty(1), 1);
      expect(waveDifficulty(2), closeTo(1.09, 1e-9));
      expect(waveDifficulty(11), closeTo(1.9, 1e-9));
    });

    test('敌机射速随难度同步加快', () {
      expect(enemyFireIntervalScale(1), 1);
      expect(enemyFireIntervalScale(2), lessThan(1));
      expect(enemyFireIntervalScale(11), lessThan(enemyFireIntervalScale(2)));
    });
  });

  group('玩家火力', () {
    test('火力等级越高射击间隔越短', () {
      final first = playerFireInterval(1, rapid: false);
      final fifth = playerFireInterval(5, rapid: false);
      expect(first, kBaseFireInterval);
      expect(fifth, lessThan(first));
    });

    test('急速射击按固定系数缩短间隔', () {
      final normal = playerFireInterval(3, rapid: false);
      final rapid = playerFireInterval(3, rapid: true);
      expect(rapid, closeTo(normal * kRapidFireIntervalScale, 1e-9));
    });

    test('异常火力等级按 1 级处理，不会出现负间隔', () {
      expect(playerFireInterval(0, rapid: false), kBaseFireInterval);
      expect(playerFireInterval(1, rapid: false), greaterThan(0));
    });
  });

  group('连击倍率', () {
    test('按 12 / 30 / 60 三档提升', () {
      expect(comboMultiplier(0), 1);
      expect(comboMultiplier(11), 1);
      expect(comboMultiplier(12), 2);
      expect(comboMultiplier(29), 2);
      expect(comboMultiplier(30), 3);
      expect(comboMultiplier(59), 3);
      expect(comboMultiplier(60), 4);
      expect(comboMultiplier(999), 4);
    });
  });

  group('掉落映射', () {
    test('随机数落在对应区间时返回对应补给', () {
      expect(powerUpKindForRoll(0), PowerUpKind.weapon);
      expect(powerUpKindForRoll(0.35), PowerUpKind.weapon);
      expect(powerUpKindForRoll(0.36), PowerUpKind.shield);
      expect(powerUpKindForRoll(0.56), PowerUpKind.bomb);
      expect(powerUpKindForRoll(0.68), PowerUpKind.star);
      expect(powerUpKindForRoll(0.79), PowerUpKind.rapid);
      expect(powerUpKindForRoll(0.9), PowerUpKind.wingman);
      expect(powerUpKindForRoll(0.999), PowerUpKind.wingman);
    });

    test('全部补给类型都能掉落', () {
      final kinds = {for (var i = 0; i < 100; i++) powerUpKindForRoll(i / 100)};
      expect(kinds, containsAll(PowerUpKind.values));
    });
  });

  group('边界与节奏', () {
    test('玩家边界与出生位置自洽', () {
      expect(kPlayerSideMargin, greaterThan(0));
      expect(kPlayerTopLimit, greaterThan(kPlayerSideMargin));
      expect(kPlayerStartBottomOffset, greaterThan(kPlayerBottomMargin));
    });

    test('开场提示与波次间隔均为正数', () {
      expect(kBattleHintDuration, greaterThan(0));
      expect(kFirstWaveGap, greaterThan(0));
      expect(kBetweenWaveGap, greaterThanOrEqualTo(kFirstWaveGap));
      expect(kHudRefreshInterval, inInclusiveRange(0.05, 0.2));
    });
  });
}
