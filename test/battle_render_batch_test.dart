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
  int circleCalls = 0;

  @override
  void drawRawPoints(PointMode mode, Float32List points, Paint paint) {
    rawPointsCalls++;
    rawPointCount += points.length ~/ 2;
  }

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    circleCalls++;
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
}
