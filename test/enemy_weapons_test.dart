import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/game/battle/battle_types.dart';
import 'package:sky_fighter/game/battle/enemy_weapons.dart';

void main() {
  group('敌机弹道', () {
    test('瞄准齐射以目标为中心对称展开', () {
      final shots = buildAimedVolley(
        origin: const Offset(200, 100),
        target: const Offset(200, 600),
        speed: 200,
        count: 3,
        spread: 0.2,
      );

      expect(shots, hasLength(3));
      expect(shots[1].vx, closeTo(0, 0.0001));
      expect(shots[1].vy, closeTo(200, 0.0001));
      expect(shots[0].vx, closeTo(-shots[2].vx, 0.0001));
      expect(shots.every((shot) => shot.kind == BulletKind.aimed), isTrue);
      expect(shots.every((shot) => shot.y == 106), isTrue);
    });

    test('零发射数返回空列表', () {
      expect(
        buildAimedVolley(
          origin: Offset.zero,
          target: const Offset(0, 100),
          speed: 100,
          count: 0,
          spread: 0.2,
        ),
        isEmpty,
      );
    });

    test('Boss 四段弹幕数量与外观固定', () {
      final boss = Enemy(
        kind: EnemyKind.boss,
        pattern: EnemyPattern.hover,
        x: 200,
        y: 90,
        difficulty: 1,
      )..entered = true;
      const target = Offset(200, 600);
      final counts = [
        for (var cycle = 0; cycle < 4; cycle++)
          buildBossBarrage(
            boss: boss,
            target: target,
            cycle: cycle,
            speed: 160,
          ).length,
      ];

      expect(counts, [3, 18, 5, 10]);
      for (var cycle = 0; cycle < 4; cycle++) {
        final shots = buildBossBarrage(
          boss: boss,
          target: target,
          cycle: cycle,
          speed: 160,
        );
        expect(shots.every((shot) => shot.kind == BulletKind.boss), isTrue);
        expect(shots.every((shot) => shot.radius == 5), isTrue);
        expect(shots.every((shot) => !shot.fromPlayer), isTrue);
      }
    });

    test('Boss 环形弹幕速度一致且从机身发出', () {
      final boss = Enemy(
        kind: EnemyKind.boss,
        pattern: EnemyPattern.hover,
        x: 200,
        y: 90,
        difficulty: 1,
      );
      final shots = buildBossBarrage(
        boss: boss,
        target: const Offset(40, 600),
        cycle: 1,
        speed: 200,
      );

      expect(shots, hasLength(18));
      for (final shot in shots) {
        expect(shot.x, 200);
        expect(shot.y, 90);
        expect(shot.vx * shot.vx + shot.vy * shot.vy, closeTo(170 * 170, 0.01));
      }
    });
  });
}
