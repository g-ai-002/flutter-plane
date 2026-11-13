import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/game/battle/battle_controller.dart';
import 'package:sky_fighter/game/battle/battle_types.dart';
import 'package:sky_fighter/game/challenge/daily_challenge.dart';
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

  testWidgets('僚机编队生效时展示数量', (tester) async {
    final controller = BattleController(size: const Size(400, 820));
    addTearDown(controller.dispose);
    controller.player.wingmen = 2;
    await pumpHud(tester, controller);

    expect(find.byIcon(Icons.flight_rounded), findsOneWidget);
    expect(find.text('×2'), findsNWidgets(2));
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

  testWidgets('Boss 血条随独立通知器更新，无需重建整棵 HUD', (tester) async {
    final controller = BattleController(size: const Size(400, 820))..start();
    addTearDown(controller.dispose);
    final boss = Enemy(
      kind: EnemyKind.boss,
      pattern: EnemyPattern.hover,
      x: 200,
      y: 100,
      difficulty: 1,
    );
    controller.wave = 4;
    controller.enemies.add(boss);
    await pumpHud(tester, controller);
    expect(find.text('100%'), findsOneWidget);

    boss.hp = boss.maxHp * 0.5;
    // 只推进逻辑，不触发控制器对 HUD 主体的通知。
    for (var i = 0; i < 12; i++) {
      controller.update(1 / 60);
    }
    await tester.pump();

    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('紧凑布局左侧竖排数量提示，Boss 血条缩小靠右', (tester) async {
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

    final score = tester.getRect(find.byKey(const ValueKey('hud-score')));
    final status = tester.getRect(find.byKey(const ValueKey('hud-status')));
    final boss = tester.getRect(find.byKey(const ValueKey('hud-boss')));
    final lives = tester.getRect(find.byKey(const ValueKey('hud-stat-生命')));
    final bombs = tester.getRect(find.byKey(const ValueKey('hud-stat-炸弹')));

    // 得分在上、数量提示在下，二者留出间距。
    expect(status.top - score.bottom, greaterThanOrEqualTo(8));
    // 生命与炸弹上下排列，且左边缘对齐。
    expect(bombs.top, greaterThan(lives.bottom));
    expect((lives.left - bombs.left).abs(), lessThan(1));
    expect(status.height, greaterThan(status.width));
    // 数量提示只占左侧窄条，不越过屏幕中线。
    expect(status.left, lessThan(16));
    expect(status.right, lessThan(400 / 2));
    // 血条靠右、尺寸收小，不压在得分与数量提示上。
    expect(boss.right, lessThanOrEqualTo(400 - 8));
    expect(boss.left, greaterThan(400 / 2));
    expect(boss.width, lessThan(400 * 0.4));
    expect(boss.left, greaterThan(score.right));
    expect(boss.left, greaterThan(status.right));
  });

  testWidgets('满状态与连击下左侧竖排仍不越过中线', (tester) async {
    final controller = BattleController(size: const Size(320, 640))
      ..wave = 4
      ..combo = 30;
    controller.player
      ..wingmen = 2
      ..rapid = 5;
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BattleHud(
            controller: controller,
            field: const Rect.fromLTWH(0, 0, 320, 640),
            stage: const Size(320, 640),
            onPause: () {},
            onBomb: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    final status = tester.getRect(find.byKey(const ValueKey('hud-status')));
    final labels = ['生命', '炸弹', '火力', '僚机', '急速'];
    final tops = [
      for (final label in labels)
        tester.getRect(find.byKey(ValueKey('hud-stat-$label'))).top,
    ];

    expect(status.right, lessThan(320 / 2));
    for (var i = 1; i < tops.length; i++) {
      expect(tops[i], greaterThan(tops[i - 1]));
    }
  });

  testWidgets('宽屏 Boss 血条放在战场右侧留白', (tester) async {
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

    final boss = tester.getRect(find.byKey(const ValueKey('hud-boss')));
    expect(boss.left, greaterThanOrEqualTo(800));
    expect(boss.right, lessThanOrEqualTo(1200));
    expect(boss.width, lessThanOrEqualTo(190));
  });

  testWidgets('窄屏顶部 HUD 在满状态与连击下不溢出', (tester) async {
    final controller = BattleController(size: const Size(320, 640))
      ..wave = 4
      ..combo = 30;
    controller.player
      ..wingmen = 2
      ..rapid = 5;
    controller.enemies.add(
      Enemy(
        kind: EnemyKind.boss,
        pattern: EnemyPattern.hover,
        x: 160,
        y: 100,
        difficulty: 1,
      ),
    );
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BattleHud(
            controller: controller,
            field: const Rect.fromLTWH(0, 0, 320, 640),
            stage: const Size(320, 640),
            onPause: () {},
            onBomb: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('hud-boss')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Boss 中途出现时血条跟随 HUD 重建自动显示', (tester) async {
    final controller = BattleController(size: const Size(400, 820))..start();
    // 跳过开场提示，避免提示淡出掩盖 Boss 出现带来的唯一一次通知。
    controller.elapsed = BattleController.hintDuration + 1;
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(400, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => BattleHud(
              controller: controller,
              field: const Rect.fromLTWH(0, 0, 400, 820),
              stage: const Size(400, 820),
              onPause: () {},
              onBomb: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('hud-boss')), findsNothing);

    controller.wave = 4;
    final boss = Enemy(
      kind: EnemyKind.boss,
      pattern: EnemyPattern.hover,
      x: 200,
      y: 100,
      difficulty: 1,
    );
    controller.enemies.add(boss);
    for (var i = 0; i < 12; i++) {
      controller.update(1 / 60);
    }
    await tester.pump();

    expect(find.text('赤蝎母舰'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    controller.enemies.remove(boss);
    for (var i = 0; i < 12; i++) {
      controller.update(1 / 60);
    }
    await tester.pump();

    expect(find.byKey(const ValueKey('hud-boss')), findsNothing);
  });

  testWidgets('每日挑战展示战场修正', (tester) async {
    final controller = BattleController(
      size: const Size(400, 820),
      challenge: const DailyChallenge(
        dateKey: '20261108',
        seed: 7,
        modifier: ChallengeModifier.barrage,
      ),
    )..start();
    addTearDown(controller.dispose);
    await pumpHud(tester, controller);

    expect(find.text('挑战 · 弹幕压制'), findsOneWidget);
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

  testWidgets('宽屏面板展示完整的急速倒计时', (tester) async {
    final controller = BattleController(size: const Size(400, 820));
    addTearDown(controller.dispose);
    controller.player.rapid = 5.4;
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

    expect(find.text('急速'), findsOneWidget);
    expect(find.text('6 秒'), findsOneWidget);
    expect(find.byIcon(Icons.timer_rounded), findsOneWidget);
  });
}
