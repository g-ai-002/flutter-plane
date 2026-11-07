import 'dart:typed_data';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/flame/battle_field_component.dart';
import 'package:sky_fighter/game/battle/battle_controller.dart';
import 'package:sky_fighter/game/battle/battle_types.dart';
import 'package:sky_fighter/game/logic_rate.dart';

/// 统计绘制调用的画布：批绘制的调用数与点数都能直接断言。
class CountingCanvas implements Canvas {
  int rawPointsCalls = 0;
  int rawPointCount = 0;
  int linePointCount = 0;
  int circleCalls = 0;
  int pictureCalls = 0;
  int rectCalls = 0;
  int saveCalls = 0;
  int rotateCalls = 0;

  @override
  void drawRawPoints(PointMode mode, Float32List points, Paint paint) {
    rawPointsCalls++;
    rawPointCount += points.length ~/ 2;
    if (mode == PointMode.lines) linePointCount += points.length ~/ 2;
  }

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    circleCalls++;
  }

  @override
  void drawPicture(Picture picture) {
    pictureCalls++;
  }

  @override
  void drawRect(Rect rect, Paint paint) {
    rectCalls++;
  }

  @override
  void save() {
    saveCalls++;
  }

  @override
  void rotate(double radians) {
    rotateCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

BattleController _controllerWithBullets() {
  final controller = BattleController(size: const Size(400, 700), seed: 11)
    ..start();
  // 星空单独有测试，这里清空以便精确统计弹幕的绘制调用。
  controller.stars.clear();
  controller.player.shield = 0;
  controller.player.invuln = 0;

  for (var i = 0; i < 6; i++) {
    controller.enemies.add(
      Enemy(
        kind: EnemyKind.values[i % EnemyKind.values.length],
        pattern: EnemyPattern.straight,
        x: 40 + i * 60,
        y: 100 + i * 20,
        difficulty: 1,
      ),
    );
  }
  for (var i = 0; i < 90; i++) {
    controller.playerBullets.add(
      Bullet(
        x: 20 + (i % 18) * 20,
        y: 300 + (i ~/ 18) * 40,
        vx: 0,
        vy: -560,
        radius: 3.4,
        damage: 1,
        fromPlayer: true,
      ),
    );
  }
  for (var i = 0; i < 150; i++) {
    controller.enemyBullets.add(
      Bullet(
        x: 20 + (i % 20) * 18,
        y: 200 + (i ~/ 20) * 30,
        vx: 0,
        vy: 160,
        radius: 4.2,
        damage: 1,
        fromPlayer: false,
        kind: 1 + i % 3,
      ),
    );
  }
  return controller;
}

void main() {
  testWidgets('密集弹幕按颜色分桶批绘制，绘制调用远少于弹数', (tester) async {
    final controller = _controllerWithBullets();
    addTearDown(controller.dispose);

    final component = BattleFieldComponent(
      controller: controller,
      logicRate: LogicRate.hz60,
    );
    component.size = Vector2(400, 700);

    final canvas = CountingCanvas();
    component.render(canvas);

    // 240 颗子弹的三层外观如果逐颗绘制需要 700+ 次调用，批绘制应压到个位数级别。
    expect(canvas.rawPointsCalls, lessThanOrEqualTo(12));
    expect(canvas.rawPointCount, greaterThanOrEqualTo(600));
    // 剩余圆形调用只来自 6 架敌机的核心/引擎光与 Boss 炮塔，与弹数无关。
    expect(canvas.circleCalls, lessThanOrEqualTo(24));
    expect(tester.takeException(), isNull);
  });

  testWidgets('战场背景只录制一次，后续帧复用同一张 Picture', (tester) async {
    final controller = BattleController(size: const Size(400, 700), seed: 5)
      ..start();
    addTearDown(controller.dispose);
    // 跳过战机与星空，只观察背景层的绘制方式。
    controller.player.alive = false;
    controller.stars.clear();

    final component = BattleFieldComponent(
      controller: controller,
      logicRate: LogicRate.hz60,
    );
    component.size = Vector2(400, 700);
    addTearDown(component.onRemove);

    final canvas = CountingCanvas();
    component.render(canvas);
    component.render(canvas);

    // 两帧各提交一次 Picture，但背景渐变不再逐帧重绘（没有 drawRect）。
    expect(canvas.pictureCalls, 2);
    expect(canvas.rectCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('爆炸碎片并入线段批绘制，不再逐颗变换画布', (tester) async {
    final controller = BattleController(size: const Size(400, 700), seed: 9)
      ..start();
    addTearDown(controller.dispose);
    controller.player.alive = false;
    controller.stars.clear();
    controller.enemies.clear();
    controller.playerBullets.clear();
    controller.enemyBullets.clear();
    controller.powerUps.clear();
    controller.popups.clear();
    for (var i = 0; i < 3; i++) {
      controller.particles.add(
        Particle(
          x: 80 + i * 60,
          y: 300,
          vx: 0,
          vy: 0,
          life: 0.6,
          size: 3,
          color: 0xFFFFD54F,
          kind: ParticleKind.debris,
        ),
      );
    }

    final component = BattleFieldComponent(
      controller: controller,
      logicRate: LogicRate.hz60,
    );
    component.size = Vector2(400, 700);
    addTearDown(component.onRemove);

    final canvas = CountingCanvas();
    component.render(canvas);

    // 只剩渲染入口与震屏两次保存，碎片本身不再 save / translate / rotate。
    expect(canvas.saveCalls, 2);
    expect(canvas.rotateCalls, 0);
    expect(canvas.linePointCount, 6);
    expect(tester.takeException(), isNull);
  });

  testWidgets('战场为空时也能安全渲染', (tester) async {
    final controller = BattleController(size: const Size(400, 700), seed: 3)
      ..start();
    addTearDown(controller.dispose);
    final component = BattleFieldComponent(
      controller: controller,
      logicRate: LogicRate.hz30,
    );
    component.size = Vector2(400, 700);

    final canvas = CountingCanvas();
    component.render(canvas);

    // 星空本身也走批绘制。
    expect(canvas.rawPointsCalls, greaterThan(0));
    expect(canvas.rawPointsCalls, lessThanOrEqualTo(40));
    expect(tester.takeException(), isNull);
  });

  testWidgets('飘字与补给的文字、颜色缓存逐帧复用', (tester) async {
    final controller = BattleController(size: const Size(400, 700), seed: 17)
      ..start();
    addTearDown(controller.dispose);
    controller.player.alive = false;
    controller.stars.clear();
    controller.enemies.clear();
    controller.playerBullets.clear();
    controller.enemyBullets.clear();
    controller.particles.clear();
    for (var i = 0; i < 6; i++) {
      controller.popups.add(
        ScorePopup(x: 60 + i * 20, y: 300, text: '+${i * 10}'),
      );
    }
    for (final kind in PowerUpKind.values) {
      controller.powerUps.add(PowerUp(x: 40, y: 200, kind: kind));
    }

    final component = BattleFieldComponent(
      controller: controller,
      logicRate: LogicRate.hz60,
    );
    component.size = Vector2(400, 700);
    addTearDown(component.onRemove);
    final canvas = CountingCanvas();

    component.render(canvas);
    final textPainters = component.cachedTextPainters;
    final colors = component.cachedColors;
    expect(textPainters, greaterThan(0));
    expect(colors, greaterThan(0));

    for (var i = 0; i < 6; i++) {
      component.render(canvas);
    }
    // 同一批飘字与补给连续绘制，缓存命中后不再新增排版与颜色。
    expect(component.cachedTextPainters, textPainters);
    expect(component.cachedColors, colors);
    expect(tester.takeException(), isNull);
  });

  testWidgets('飘字的四档淡出最多只缓存四种颜色', (tester) async {
    final controller = BattleController(size: const Size(400, 700), seed: 19)
      ..start();
    addTearDown(controller.dispose);
    controller.player.alive = false;
    controller.stars.clear();
    controller.enemies.clear();
    controller.playerBullets.clear();
    controller.enemyBullets.clear();
    controller.particles.clear();
    controller.powerUps.clear();
    final popup = ScorePopup(x: 200, y: 320, text: '+200');
    controller.popups.add(popup);

    final component = BattleFieldComponent(
      controller: controller,
      logicRate: LogicRate.hz60,
    );
    component.size = Vector2(400, 700);
    addTearDown(component.onRemove);
    final canvas = CountingCanvas();

    for (final life in [0.8, 0.6, 0.4, 0.2, 0.8, 0.6, 0.4, 0.2]) {
      popup.life = life;
      component.render(canvas);
    }

    expect(component.cachedColors, 4);
    expect(component.cachedTextPainters, 4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('屏幕外的补给不再进入绘制', (tester) async {
    final controller = BattleController(size: const Size(400, 700), seed: 23)
      ..start();
    addTearDown(controller.dispose);
    controller.player.alive = false;
    controller.stars.clear();
    controller.enemies.clear();
    controller.playerBullets.clear();
    controller.enemyBullets.clear();
    controller.particles.clear();
    controller.popups.clear();
    for (var i = 0; i < 4; i++) {
      controller.powerUps.add(
        PowerUp(x: 460 + 60.0 * i, y: 200, kind: PowerUpKind.weapon),
      );
    }

    final component = BattleFieldComponent(
      controller: controller,
      logicRate: LogicRate.hz60,
    );
    component.size = Vector2(400, 700);
    addTearDown(component.onRemove);
    final canvas = CountingCanvas();
    component.render(canvas);

    expect(canvas.circleCalls, 0);
    expect(tester.takeException(), isNull);
  });
}
