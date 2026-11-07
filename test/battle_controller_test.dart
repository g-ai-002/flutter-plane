import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/game/battle/battle_controller.dart';
import 'package:sky_fighter/game/battle/battle_types.dart';
import 'package:sky_fighter/game/battle/wave_director.dart';

BattleController buildController({int highScore = 0}) {
  final controller = BattleController(
    size: const Size(400, 700),
    highScore: highScore,
    seed: 42,
  );
  controller.start();
  return controller;
}

void advance(
  BattleController controller,
  double seconds, {
  double step = 1 / 60,
}) {
  var remaining = seconds;
  while (remaining > 0) {
    final dt = remaining < step ? remaining : step;
    controller.update(dt);
    remaining -= dt;
  }
}

void main() {
  group('BattleController 基础流程', () {
    test('开始后进入战斗并自动开火', () {
      final controller = buildController();
      addTearDown(controller.dispose);
      expect(controller.phase, BattlePhase.playing);
      expect(controller.score, 0);
      expect(controller.player.lives, 3);

      advance(controller, 0.3);
      expect(controller.playerBullets, isNotEmpty);
      expect(controller.playerBullets.first.vy, lessThan(0));
    });

    test('玩家移动被限制在战场内', () {
      final controller = buildController();
      addTearDown(controller.dispose);
      controller.movePlayerBy(const Offset(-9999, -9999));
      expect(controller.player.x, 16);
      expect(controller.player.y, 44);

      controller.movePlayerBy(const Offset(9999, 9999));
      expect(controller.player.x, 384);
      expect(controller.player.y, 674);
    });

    test('第一波敌机按时抵达', () {
      final controller = buildController();
      addTearDown(controller.dispose);
      advance(controller, 1.5);
      expect(controller.enemies, isNotEmpty);
      expect(controller.wave, 1);
    });

    test('击中与击破敌机累计得分与连击', () {
      final controller = buildController();
      addTearDown(controller.dispose);
      final enemy = Enemy(
        kind: EnemyKind.scout,
        pattern: EnemyPattern.straight,
        x: 200,
        y: 120,
        difficulty: 1,
      );
      controller.enemies.add(enemy);
      controller.playerBullets.add(
        Bullet(
          x: 200,
          y: 128,
          vx: 0,
          vy: -500,
          radius: 3.4,
          damage: 10,
          fromPlayer: true,
        ),
      );

      advance(controller, 0.03);
      expect(enemy.dead, isTrue);
      expect(controller.kills, 1);
      expect(controller.combo, 1);
      expect(controller.score, 60);
      expect(controller.popups.any((popup) => popup.text == '+60'), isTrue);
    });

    test('连击倍率随击破数提升', () {
      final controller = buildController();
      addTearDown(controller.dispose);
      controller.combo = 12;
      expect(controller.multiplier, 2);
      controller.combo = 30;
      expect(controller.multiplier, 3);
      controller.combo = 60;
      expect(controller.multiplier, 4);
    });

    test('高速子弹不会穿透小敌机', () {
      final controller = buildController();
      addTearDown(controller.dispose);
      final enemy = Enemy(
        kind: EnemyKind.scout,
        pattern: EnemyPattern.straight,
        x: 200,
        y: 200,
        difficulty: 1,
      );
      controller.enemies.add(enemy);
      // 一帧跨越 60 像素，若不使用扫掠检测会直接穿过半径 11 的敌机。
      controller.playerBullets.add(
        Bullet(
          x: 200,
          y: 240,
          vx: 0,
          vy: -3600,
          radius: 3,
          damage: 1,
          fromPlayer: true,
        ),
      );
      controller.update(1 / 60);
      expect(enemy.hp, lessThan(enemy.maxHp));
    });
  });

  group('补给与炸弹', () {
    test('拾取火力补给提升弹道等级', () {
      final controller = buildController();
      addTearDown(controller.dispose);
      controller.powerUps.add(
        PowerUp(
          x: controller.player.x,
          y: controller.player.y,
          kind: PowerUpKind.weapon,
        ),
      );
      advance(controller, 0.02);
      expect(controller.player.weaponLevel, 2);
      expect(controller.powerUps, isEmpty);
    });

    test('满级火力拾取转为分数', () {
      final controller = buildController();
      addTearDown(controller.dispose);
      controller.player.weaponLevel = Player.maxWeaponLevel;
      controller.powerUps.add(
        PowerUp(
          x: controller.player.x,
          y: controller.player.y,
          kind: PowerUpKind.weapon,
        ),
      );
      advance(controller, 0.02);
      expect(controller.player.weaponLevel, Player.maxWeaponLevel);
      expect(controller.score, 300);
    });

    test('护盾抵挡一次伤害', () {
      final controller = buildController();
      addTearDown(controller.dispose);
      controller.player.shield = 8;
      controller.enemyBullets.add(
        Bullet(
          x: controller.player.x,
          y: controller.player.y + 10,
          vx: 0,
          vy: -100,
          radius: 5,
          damage: 1,
          fromPlayer: false,
        ),
      );
      advance(controller, 0.02);
      expect(controller.player.lives, 3);
      expect(controller.player.shield, 0);
      expect(controller.player.invuln, greaterThan(0));
    });

    test('炸弹清空敌弹并伤害全场敌机', () {
      final controller = buildController();
      addTearDown(controller.dispose);
      final enemy = Enemy(
        kind: EnemyKind.bomber,
        pattern: EnemyPattern.straight,
        x: 120,
        y: 80,
        difficulty: 1,
      );
      controller.enemies.add(enemy);
      controller.enemyBullets.add(
        Bullet(
          x: 100,
          y: 100,
          vx: 0,
          vy: 100,
          radius: 4,
          damage: 1,
          fromPlayer: false,
        ),
      );
      final bombsBefore = controller.player.bombs;
      controller.useBomb();

      expect(controller.player.bombs, bombsBefore - 1);
      expect(controller.enemyBullets, isEmpty);
      expect(enemy.hp, lessThan(enemy.maxHp));
    });

    test('炸弹耗尽后无法释放', () {
      final controller = buildController();
      addTearDown(controller.dispose);
      controller.player.bombs = 0;
      controller.useBomb();
      expect(controller.player.bombs, 0);
      expect(controller.flash, 0);
    });
  });

  group('受伤与结算', () {
    test('生命耗尽进入结算并记录存活时间', () {
      final controller = buildController();
      addTearDown(controller.dispose);
      controller.player.lives = 1;
      controller.enemies.add(
        Enemy(
          kind: EnemyKind.scout,
          pattern: EnemyPattern.straight,
          x: controller.player.x,
          y: controller.player.y,
          difficulty: 1,
        ),
      );

      advance(controller, 0.05);
      expect(controller.phase, BattlePhase.gameOver);
      expect(controller.player.lives, 0);
      expect(controller.player.alive, isFalse);
      expect(controller.survived.inMilliseconds, greaterThan(0));
    });

    test('受伤后短暂无敌且火力降一级', () {
      final controller = buildController();
      addTearDown(controller.dispose);
      controller.player.weaponLevel = 4;
      controller.enemies.add(
        Enemy(
          kind: EnemyKind.scout,
          pattern: EnemyPattern.straight,
          x: controller.player.x,
          y: controller.player.y,
          difficulty: 1,
        ),
      );
      advance(controller, 0.03);
      expect(controller.player.lives, 2);
      expect(controller.player.weaponLevel, 3);
      expect(controller.player.invuln, greaterThan(0));
    });

    test('暂停时逻辑停止推进', () {
      final controller = buildController();
      addTearDown(controller.dispose);
      advance(controller, 0.2);
      final y = controller.playerBullets.first.y;
      controller.pause();
      advance(controller, 0.5);
      expect(controller.playerBullets.first.y, y);
      controller.resume();
      advance(controller, 0.1);
      expect(controller.phase, BattlePhase.playing);
    });

    test('游戏结束后只更新特效', () {
      final controller = buildController();
      addTearDown(controller.dispose);
      controller.player.lives = 1;
      controller.enemies.add(
        Enemy(
          kind: EnemyKind.scout,
          pattern: EnemyPattern.straight,
          x: controller.player.x,
          y: controller.player.y,
          difficulty: 1,
        ),
      );
      advance(controller, 0.05);
      final particleCount = controller.particles.length;
      advance(controller, 0.5);
      expect(controller.phase, BattlePhase.gameOver);
      expect(controller.particles.length, lessThanOrEqualTo(particleCount));
    });
  });

  group('波次与 Boss', () {
    test('每 4 波出现 Boss 波', () {
      final director = WaveDirector(seed: 7);
      final bossWaves = <int>[];
      for (var i = 0; i < 8; i++) {
        director.startNextWave();
        if (director.bossWave) bossWaves.add(director.wave);
        // 清空生成队列，避免影响下一波。
        while (director.spawning) {
          director.update(10);
        }
      }
      expect(bossWaves, [4, 8]);
    });

    test('Boss 入场后循环发射弹幕', () {
      final controller = buildController();
      addTearDown(controller.dispose);
      final boss = Enemy(
        kind: EnemyKind.boss,
        pattern: EnemyPattern.hover,
        x: 200,
        y: -60,
        difficulty: 1,
      );
      controller.enemies.add(boss);
      advance(controller, 3.2);
      expect(boss.entered, isTrue);
      expect(controller.enemyBullets, isNotEmpty);
      expect(controller.bossHpRatio, greaterThan(0));
    });
  });

  group('世界尺寸', () {
    test('缩放窗口后玩家仍在战场内', () {
      final controller = buildController();
      addTearDown(controller.dispose);
      controller.resize(const Size(400, 900));
      expect(controller.size.height, 900);
      expect(controller.player.y, lessThanOrEqualTo(900 - 26));
      expect(controller.stars, isNotEmpty);
    });
  });
}
