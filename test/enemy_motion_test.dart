import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/game/battle/battle_types.dart';
import 'package:sky_fighter/game/battle/enemy_motion.dart';

Enemy buildEnemy(EnemyKind kind, EnemyPattern pattern, {double phase = 0}) =>
    Enemy(
      kind: kind,
      pattern: pattern,
      x: 200,
      y: 100,
      difficulty: 1,
      driftPhase: phase,
    );

void main() {
  group('敌机移动', () {
    test('直落模式只改变纵向位置', () {
      final enemy = buildEnemy(EnemyKind.scout, EnemyPattern.straight);
      final vy = enemy.vy;
      advanceEnemy(enemy, 0.5);

      expect(enemy.x, 200);
      expect(enemy.y, closeTo(100 + vy * 0.5, 0.0001));
    });

    test('正弦模式围绕基准横坐标摆动', () {
      final enemy = buildEnemy(EnemyKind.scout, EnemyPattern.sine, phase: 0.1);
      advanceEnemy(enemy, 0.4);

      expect(enemy.x, isNot(200));
      expect(enemy.x, inInclusiveRange(200 - 26, 200 + 26));
    });

    test('俯冲模式持续加速但不超过上限', () {
      final enemy = buildEnemy(EnemyKind.fighter, EnemyPattern.dive);
      for (var i = 0; i < 240; i++) {
        advanceEnemy(enemy, 1 / 60);
      }
      expect(enemy.vy, lessThanOrEqualTo(190));
      expect(enemy.y, greaterThan(100));
    });

    test('追踪模式横向对齐玩家并持续加速俯冲', () {
      final enemy = buildEnemy(EnemyKind.drone, EnemyPattern.chase);
      for (var i = 0; i < 30; i++) {
        advanceEnemy(enemy, 1 / 60, targetX: 60);
      }
      expect(enemy.x, lessThan(200));
      expect(enemy.vy, greaterThan(kEnemyFallSpeed));
      final settledX = enemy.x;
      for (var i = 0; i < 60; i++) {
        advanceEnemy(enemy, 1 / 60, targetX: 60);
      }
      expect(enemy.x, closeTo(60, 0.5));
      expect(enemy.x, lessThan(settledX));
    });

    test('悬停模式先下降再巡航', () {
      final enemy = buildEnemy(EnemyKind.elite, EnemyPattern.hover, phase: 0.3);
      expect(enemy.entered, isFalse);

      for (var i = 0; i < 60; i++) {
        advanceEnemy(enemy, 1 / 60);
      }
      expect(enemy.entered, isTrue);
      expect(enemy.y, closeTo(enemy.hoverY, 8));

      for (var i = 0; i < 120; i++) {
        advanceEnemy(enemy, 1 / 60);
      }
      expect(enemy.hoverTimer, greaterThan(0));
      expect(enemy.x, inInclusiveRange(enemy.baseX - 32, enemy.baseX + 32));
    });
  });

  group('Boss 移动', () {
    test('入场下潜到 92 后停止', () {
      final boss = buildEnemy(EnemyKind.boss, EnemyPattern.hover);
      boss.y = -60;

      expect(advanceBossEntry(boss, 0.1), isFalse);
      for (var i = 0; i < 120; i++) {
        advanceBossEntry(boss, 1 / 60);
      }
      expect(boss.entered, isTrue);
      expect(boss.y, 92);
      expect(advanceBossEntry(boss, 0.1), isTrue);
    });

    test('就位后在中线附近巡航且不越界', () {
      final boss = buildEnemy(EnemyKind.boss, EnemyPattern.hover)
        ..entered = true
        ..age = 3;
      hoverBoss(boss, const Size(400, 700));

      expect(boss.y, inInclusiveRange(86, 98));
      expect(boss.x, inInclusiveRange(200 - 118, 200 + 118));
    });

    test('窄战场收敛巡航幅度', () {
      final boss = buildEnemy(EnemyKind.boss, EnemyPattern.hover)
        ..entered = true
        ..age = 3;
      hoverBoss(boss, const Size(120, 700));

      expect(boss.x, inInclusiveRange(2, 118));
    });
  });
}
