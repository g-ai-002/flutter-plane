import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sky_fighter/flame/sky_fighter_game.dart';
import 'package:sky_fighter/game/battle/battle_types.dart';
import 'package:sky_fighter/pages/game_page.dart';
import 'package:sky_fighter/providers/settings_provider.dart';
import 'package:sky_fighter/services/storage_service.dart';

Future<SettingsProvider> pumpGame(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  StorageService.resetForTests();
  final storage = await StorageService.instance;
  final settings = SettingsProvider(storage);
  await tester.binding.setSurfaceSize(const Size(400, 820));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ChangeNotifierProvider<SettingsProvider>.value(
      value: settings,
      child: const MaterialApp(home: GamePage()),
    ),
  );
  // Flame 引擎与战斗控制器在首帧后初始化。
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
  return settings;
}

void main() {
  testWidgets('进入战斗后展示 HUD', (tester) async {
    await pumpGame(tester);

    expect(find.text('得分'), findsOneWidget);
    expect(find.text('最高 0'), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
  });

  testWidgets('暂停与继续战斗', (tester) async {
    await pumpGame(tester);

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('战斗暂停'), findsOneWidget);
    expect(find.text('继续战斗'), findsOneWidget);
    expect(find.text('重新开始'), findsOneWidget);

    await tester.tap(find.text('继续战斗'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('战斗暂停'), findsNothing);
  });

  testWidgets('暂停后可重新开始', (tester) async {
    await pumpGame(tester);

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('重新开始'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('战斗暂停'), findsNothing);
    expect(find.text('得分'), findsOneWidget);
  });

  testWidgets('结算面板出现后停止引擎重绘，重开时恢复', (tester) async {
    await pumpGame(tester);
    final game =
        tester
                .widget<GameWidget<SkyFighterGame>>(
                  find.byType(GameWidget<SkyFighterGame>),
                )
                .game!;
    final controller = game.controller;
    controller.player
      ..lives = 1
      ..invuln = 0;
    controller.enemyBullets.add(
      Bullet(
        x: controller.player.x,
        y: controller.player.y,
        vx: 0,
        vy: 0,
        radius: 4.2,
        damage: 1,
        fromPlayer: false,
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.phase, BattlePhase.gameOver);
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump();

    expect(find.text('战机坠毁'), findsOneWidget);
    expect(game.paused, isTrue);

    await tester.tap(find.text('再来一局'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(game.paused, isFalse);
    expect(controller.phase, BattlePhase.playing);
  });
}
