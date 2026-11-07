import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
}
