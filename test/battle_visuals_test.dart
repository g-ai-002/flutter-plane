import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/flame/battle_visuals.dart';
import 'package:sky_fighter/game/battle/battle_types.dart';

void main() {
  group('敌机外观配置', () {
    test('每种敌机都有轮廓与配色', () {
      for (final kind in EnemyKind.values) {
        final visual = kEnemyVisuals[kind];
        expect(visual, isNotNull, reason: '缺少 $kind 的外观配置');
        expect(visual!.path.getBounds().isEmpty, isFalse);
        expect(visual.coreRadius, greaterThan(0));
      }
    });

    test('Boss 轮廓比普通敌机更大', () {
      final bossBounds = kEnemyVisuals[EnemyKind.boss]!.path.getBounds();
      final scoutBounds = kEnemyVisuals[EnemyKind.scout]!.path.getBounds();
      expect(bossBounds.width, greaterThan(scoutBounds.width * 3));
      expect(bossBounds.height, greaterThan(scoutBounds.height * 3));
    });

    test('玩家与 Boss 轮廓闭合且尺寸稳定', () {
      expect(playerHullPath.getBounds().width, 28);
      expect(bossHullPath.getBounds().width, 92);
    });
  });

  group('弹道与补给配色', () {
    test('敌弹外观覆盖全部非玩家弹种', () {
      expect(kEnemyBulletColors.keys, containsAll([1, 2, 3]));
      expect(kEnemyBulletColors.values.toSet(), hasLength(3));
    });

    test('补给配色覆盖全部类型', () {
      for (final kind in PowerUpKind.values) {
        expect(kPowerUpColors[kind], isNotNull);
      }
    });
  });

  group('敌机开火配置', () {
    test('可开火敌机都配置了弹数、弹速与散射角', () {
      for (final kind in [
        EnemyKind.fighter,
        EnemyKind.bomber,
        EnemyKind.elite,
      ]) {
        final spec = kEnemySpecs[kind]!;
        expect(spec.fireCount, greaterThan(0), reason: '$kind 应能开火');
        expect(spec.bulletSpeed, greaterThan(0));
        expect(spec.fireInterval, greaterThan(0));
      }
      expect(kEnemySpecs[EnemyKind.bomber]!.fireSpread, greaterThan(0));
      expect(kEnemySpecs[EnemyKind.elite]!.fireCount, greaterThan(1));
    });

    test('侦察机与 Boss 不走进普通开火分支', () {
      expect(kEnemySpecs[EnemyKind.scout]!.fireCount, 0);
      expect(kEnemySpecs[EnemyKind.boss]!.fireCount, 0);
    });
  });
}
