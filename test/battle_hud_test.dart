import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/game/battle/battle_controller.dart';
import 'package:sky_fighter/game/battle/battle_types.dart';
import 'package:sky_fighter/pages/widgets/battle_hud.dart';

Future<void> pumpHud(WidgetTester tester, BattleController controller) async {
  await tester.binding.setSurfaceSize(const Size(400, 820));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF05070F),
        body: BattleHud(
          controller: controller,
          field: const Rect.fromLTWH(0, 0, 400, 820),
          stage: const Size(400, 820),
          onPause: () {},
          onBomb: () {},
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('紧凑布局展示得分、生命与炸弹', (tester) async {
    final controller = BattleController(size: const Size(400, 820));
    addTearDown(controller.dispose);
    await pumpHud(tester, controller);

    expect(find.text('得分'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('最高 0'), findsOneWidget);
    expect(find.text('×3'), findsOneWidget);
    expect(find.text('×2'), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(find.byIcon(Icons.local_fire_department_rounded), findsWidgets);
  });

  testWidgets('连击达到阈值时展示倍率', (tester) async {
    final controller = BattleController(size: const Size(400, 820))..combo = 30;
    addTearDown(controller.dispose);
    await pumpHud(tester, controller);

    expect(find.text('30 连击'), findsOneWidget);
    // 生命图标同样是 ×3，连击倍率与生命各一处。
    expect(find.text('×3'), findsNWidgets(2));
  });

  testWidgets('急速射击生效时展示倒计时', (tester) async {
    final controller = BattleController(size: const Size(400, 820));
    addTearDown(controller.dispose);
    controller.player.rapid = 5.4;
    await pumpHud(tester, controller);

    expect(find.byIcon(Icons.timer_rounded), findsOneWidget);
    expect(find.text('6s'), findsOneWidget);
  });

  testWidgets('Boss 出现时展示名称与血条', (tester) async {
    final controller = BattleController(size: const Size(400, 820))..wave = 4;
    controller.enemies.add(
      Enemy(
        kind: EnemyKind.boss,
        pattern: EnemyPattern.hover,
        x: 200,
        y: 100,
        difficulty: 1,
      ),
    );
    addTearDown(controller.dispose);
    await pumpHud(tester, controller);

    expect(find.text('赤蝎母舰'), findsOneWidget);
    expect(find.text('第 4 波'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('宽屏把 HUD 放到战场两侧', (tester) async {
    final controller = BattleController(size: const Size(400, 820));
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(1200, 860));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BattleHud(
            controller: controller,
            field: const Rect.fromLTWH(400, 0, 400, 820),
            stage: const Size(1200, 860),
            onPause: () {},
            onBomb: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('战机状态'), findsOneWidget);
    expect(find.text('火力'), findsOneWidget);
    expect(find.text('待命'), findsOneWidget);
  });
}
