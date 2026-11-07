import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/game/battle/battle_types.dart';
import 'package:sky_fighter/game/battle/boss_catalog.dart';

void main() {
  group('Boss 轮换', () {
    test('每 4 波一个 Boss，三种形态按顺序轮换', () {
      expect(bossVariantForWave(4), BossVariant.scorpion);
      expect(bossVariantForWave(8), BossVariant.leviathan);
      expect(bossVariantForWave(12), BossVariant.wraith);
      expect(bossVariantForWave(16), BossVariant.scorpion);
      expect(bossVariantForWave(20), BossVariant.leviathan);
      expect(bossVariantForWave(24), BossVariant.wraith);
    });

    test('首场 Boss 之前按赤蝎形态处理', () {
      expect(bossIndexForWave(0), 0);
      expect(bossIndexForWave(3), 0);
      expect(bossVariantForWave(1), BossVariant.scorpion);
      expect(bossNameForWave(3), isEmpty);
    });

    test('Boss 名称按形态循环取用', () {
      expect(bossNameForWave(4), '赤蝎母舰');
      expect(bossNameForWave(8), '深渊利维坦');
      expect(bossNameForWave(12), '幽影方舟');
      expect(bossNameForWave(16), '雷霆要塞');
      expect(bossNameForWave(20), '终焉之核');
      expect(bossNameForWave(24), '寂灭守望');
      expect(bossNameForWave(28), '虚空旗舰');
      expect(bossNameForWave(32), '混沌母巢');
      expect(bossNameForWave(36), '蚀界之瞳');
      expect(bossNameForWave(40), '赤蝎母舰');
    });

    test('每种形态至少配置三个名称且互不重复', () {
      final names = kBossNames.values.expand((list) => list).toList();
      expect(names.toSet().length, names.length);
      for (final variant in BossVariant.values) {
        expect(kBossNames[variant], hasLength(greaterThanOrEqualTo(3)));
      }
    });

    test('血量系数随形态依次提高', () {
      expect(kBossHpScale[BossVariant.scorpion], 1);
      expect(
        kBossHpScale[BossVariant.wraith]!,
        greaterThan(kBossHpScale[BossVariant.leviathan]!),
      );
    });
  });

  group('Boss 弹幕节奏', () {
    test('间隔随波次缩短但不会低于 1.1 秒', () {
      expect(bossBarrageInterval(4), greaterThan(bossBarrageInterval(8)));
      expect(bossBarrageInterval(40), 1.1);
    });

    test('弹速随波次提升并在 16 波后封顶', () {
      expect(bossBarrageSpeed(4), greaterThan(158));
      expect(bossBarrageSpeed(17), 208);
      expect(bossBarrageSpeed(40), 208);
    });
  });
}
