import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/flame/sky_fighter_game.dart';
import 'package:sky_fighter/game/battle/battle_controller.dart';
import 'package:sky_fighter/game/battle/battle_types.dart';
import 'package:sky_fighter/game/logic_rate.dart';

BattleController populatedController() {
  final controller = BattleController(size: const Size(400, 700), seed: 8)
    ..start();
  controller.enemies.addAll([
    Enemy(
      kind: EnemyKind.scout,
      pattern: EnemyPattern.sine,
      x: 60,
      y: 80,
      difficulty: 1,
    ),
    Enemy(
      kind: EnemyKind.fighter,
      pattern: EnemyPattern.straight,
      x: 140,
      y: 140,
      difficulty: 1,
    ),
    Enemy(
      kind: EnemyKind.bomber,
      pattern: EnemyPattern.dive,
      x: 220,
      y: 120,
      difficulty: 1,
    )..hp = 12,
    Enemy(
      kind: EnemyKind.elite,
      pattern: EnemyPattern.hover,
      x: 300,
      y: 160,
      difficulty: 1,
    )..hitFlash = 0.05,
    Enemy(
      kind: EnemyKind.interceptor,
      pattern: EnemyPattern.dive,
      x: 70,
      y: 200,
      difficulty: 1,
    ),
    Enemy(
      kind: EnemyKind.drone,
      pattern: EnemyPattern.chase,
      x: 250,
      y: 220,
      difficulty: 1,
    ),
    Enemy(
      kind: EnemyKind.fortress,
      pattern: EnemyPattern.hover,
      x: 330,
      y: 260,
      difficulty: 1,
    )..entered = true,
    Enemy(
      kind: EnemyKind.boss,
      pattern: EnemyPattern.hover,
      x: 200,
      y: 90,
      difficulty: 1,
      variant: BossVariant.leviathan,
    )..entered = true,
  ]);
  controller.playerBullets.addAll([
    Bullet(
      x: 190,
      y: 300,
      vx: 0,
      vy: -560,
      radius: 3.4,
      damage: 1,
      fromPlayer: true,
    ),
    Bullet(
      x: 120,
      y: 260,
      vx: 80,
      vy: -560,
      radius: 3.4,
      damage: 1,
      fromPlayer: true,
    ),
  ]);
  controller.enemyBullets.addAll([
    Bullet(
      x: 100,
      y: 200,
      vx: 0,
      vy: 150,
      radius: 4.2,
      damage: 1,
      fromPlayer: false,
    ),
    Bullet(
      x: 160,
      y: 220,
      vx: 60,
      vy: 140,
      radius: 4.2,
      damage: 1,
      fromPlayer: false,
      kind: 2,
    ),
    Bullet(
      x: 260,
      y: 240,
      vx: -40,
      vy: 150,
      radius: 5,
      damage: 1,
      fromPlayer: false,
      kind: 3,
    ),
    Bullet(
      x: 300,
      y: 260,
      vx: -30,
      vy: 140,
      radius: 4.6,
      damage: 1,
      fromPlayer: false,
      kind: 4,
    ),
  ]);
  controller.powerUps.addAll([
    PowerUp(x: 90, y: 380, kind: PowerUpKind.weapon),
    PowerUp(x: 150, y: 400, kind: PowerUpKind.shield),
    PowerUp(x: 230, y: 420, kind: PowerUpKind.bomb),
    PowerUp(x: 310, y: 440, kind: PowerUpKind.star),
    PowerUp(x: 350, y: 460, kind: PowerUpKind.rapid),
  ]);
  controller.particles.addAll([
    Particle(
      x: 120,
      y: 480,
      vx: 30,
      vy: -20,
      life: 0.5,
      size: 3,
      color: 0xFFFFB347,
    ),
    Particle(
      x: 180,
      y: 500,
      vx: 0,
      vy: 10,
      life: 0.8,
      size: 8,
      color: 0xFF2A3358,
      kind: ParticleKind.smoke,
    ),
    Particle(
      x: 240,
      y: 520,
      vx: 0,
      vy: 0,
      life: 0.3,
      size: 12,
      color: 0xFFFFFFFF,
      kind: ParticleKind.ring,
    ),
    Particle(
      x: 300,
      y: 540,
      vx: 40,
      vy: -40,
      life: 0.7,
      size: 3,
      color: 0xFFFFD54F,
      kind: ParticleKind.debris,
    ),
  ]);
  controller.popups.addAll([
    ScorePopup(x: 200, y: 400, text: '+120'),
    ScorePopup(x: 200, y: 430, text: '火力 3 级', color: 0xFFFFB347),
  ]);
  controller.player.shield = 5;
  controller.combo = 20;
  controller.flash = 0.2;
  controller.shake = 6;
  return controller;
}

void main() {
  testWidgets('战场渲染覆盖全部实体与特效', (tester) async {
    final controller = populatedController();
    addTearDown(controller.dispose);
    final game = SkyFighterGame(
      controller: controller,
      logicRate: LogicRate.hz60,
    );
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GameWidget(game: game)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 120));

    expect(tester.takeException(), isNull);
    expect(controller.phase, BattlePhase.playing);
  });
}
