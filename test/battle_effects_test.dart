import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/game/battle/battle_effects.dart';
import 'package:sky_fighter/game/battle/battle_types.dart';

BattleEffects buildEffects() => BattleEffects(math.Random(7), math.Random(11));

void main() {
  group('战场特效', () {
    test('星空数量随战场面积收敛在上下限内', () {
      final effects = buildEffects();

      effects.resetStars(const Size(40, 60));
      expect(effects.stars.length, 40);
      expect(
        effects.stars.every(
          (star) => star.x >= 0 && star.x <= 40 && star.y >= 0 && star.y <= 60,
        ),
        isTrue,
      );

      effects.resetStars(const Size(400, 900));
      expect(effects.stars.length, 69);
      expect(effects.stars.every((star) => star.speed > 0), isTrue);
    });

    test('星星驶出底部后从顶部重新进入', () {
      final effects = buildEffects()..resetStars(const Size(400, 700));
      final star = effects.stars.first..y = 710;
      effects.updateStars(1 / 60, const Size(400, 700));

      expect(star.y, -4);
      expect(star.x, inInclusiveRange(0, 400));
    });

    test('粒子数量不超过上限并会随生命周期清理', () {
      final effects = buildEffects();
      for (var i = 0; i < 40; i++) {
        effects.burst(
          Offset(i.toDouble(), 100),
          count: 20,
          color: 0xFFFFFFFF,
          life: 0.1,
        );
      }
      expect(effects.particles.length, BattleEffects.maxParticles);

      effects.update(0.2);
      expect(effects.particles, isEmpty);
    });

    test('尾焰粒子单独限流', () {
      final effects = buildEffects();
      for (var i = 0; i < 500; i++) {
        effects.addPlayerTrail(const Offset(200, 600), shielded: false);
      }
      expect(effects.particles.length, BattleEffects.maxTrailParticles);
    });

    test('大型爆炸追加烟雾、冲击环与碎片', () {
      final effects = buildEffects();
      effects.explode(const Offset(200, 300), big: true, color: 0xFFFF5252);

      final kinds = effects.particles.map((particle) => particle.kind).toSet();
      expect(
        kinds,
        containsAll([
          ParticleKind.spark,
          ParticleKind.smoke,
          ParticleKind.ring,
          ParticleKind.debris,
        ]),
      );
      expect(effects.particles.length, 46);
    });

    test('飘字到期移除且数量受控', () {
      final effects = buildEffects();
      for (var i = 0; i < BattleEffects.maxPopups + 10; i++) {
        effects.addPopup(ScorePopup(x: 100, y: 100, text: '+$i'));
      }
      expect(effects.popups.length, BattleEffects.maxPopups);

      effects.update(0.9);
      expect(effects.popups, isEmpty);
    });

    test('清空只移除粒子与飘字，保留星空', () {
      final effects = buildEffects()
        ..resetStars(const Size(400, 700))
        ..addPopup(ScorePopup(x: 10, y: 10, text: '+1'))
        ..addPlayerTrail(const Offset(200, 600), shielded: true);

      effects.clear();

      expect(effects.particles, isEmpty);
      expect(effects.popups, isEmpty);
      expect(effects.stars, isNotEmpty);
    });

    test('死亡粒子进入回收池并被后续爆炸复用', () {
      final effects = buildEffects();
      effects.burst(
        const Offset(200, 300),
        count: 30,
        color: 0xFFFF5252,
        life: 0.1,
      );
      final first = List<Particle>.of(effects.particles);

      effects.update(0.2);
      expect(effects.particles, isEmpty);
      expect(effects.pooledParticles, 30);

      effects.burst(
        const Offset(120, 260),
        count: 30,
        color: 0xFF7FD8FF,
        life: 0.4,
      );
      expect(effects.particles.length, 30);
      // 池里的对象被原地重置后重新上场，不产生新的对象。
      expect(effects.particles.any(first.contains), isTrue);
      expect(effects.pooledParticles, 0);
      expect(effects.particles.first.color, 0xFF7FD8FF);
    });

    test('回收池容量有限，超量粒子不会被无限缓存', () {
      final effects = buildEffects();
      for (var i = 0; i < 40; i++) {
        effects.burst(
          const Offset(200, 300),
          count: 20,
          color: 0xFFFFFFFF,
          life: 0.1,
        );
      }
      effects.update(0.2);
      expect(effects.particles, isEmpty);
      expect(
        effects.pooledParticles,
        lessThanOrEqualTo(BattleEffects.maxPooledParticles),
      );
    });

    test('同一步的粒子衰减保持一致，与阻力系数无关地更新位置', () {
      final effects = buildEffects();
      effects.particles.addAll([
        Particle(
          x: 100,
          y: 100,
          vx: 100,
          vy: 0,
          life: 1,
          size: 2,
          color: 0xFFFFFFFF,
          drag: 2.2,
        ),
        Particle(
          x: 200,
          y: 100,
          vx: 100,
          vy: 0,
          life: 1,
          size: 5,
          color: 0xFF2A3358,
          kind: ParticleKind.smoke,
          drag: 1.1,
        ),
      ]);

      effects.update(0.1);
      final spark = effects.particles[0];
      final smoke = effects.particles[1];
      expect(spark.vx, closeTo(100 * math.exp(-2.2 * 0.1), 1e-9));
      expect(smoke.vx, closeTo(100 * math.exp(-1.1 * 0.1), 1e-9));
      expect(spark.x, greaterThan(100));
      expect(smoke.x, greaterThan(spark.x));
    });
  });
}
