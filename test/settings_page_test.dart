import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sky_fighter/game/logic_rate.dart';
import 'package:sky_fighter/pages/settings_page.dart';
import 'package:sky_fighter/providers/settings_provider.dart';
import 'package:sky_fighter/services/storage_service.dart';

Future<SettingsProvider> pumpSettings(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  StorageService.resetForTests();
  final storage = await StorageService.instance;
  final settings = SettingsProvider(storage);
  await tester.binding.setSurfaceSize(const Size(420, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ChangeNotifierProvider<SettingsProvider>.value(
      value: settings,
      child: const MaterialApp(home: SettingsPage()),
    ),
  );
  await tester.pump(const Duration(milliseconds: 250));
  return settings;
}

void main() {
  testWidgets('设置页展示全部区块', (tester) async {
    await pumpSettings(tester);

    expect(find.text('设置'), findsOneWidget);
    expect(find.text('画面与性能'), findsOneWidget);
    expect(find.text('声音与反馈'), findsOneWidget);
    expect(find.text('战绩'), findsOneWidget);
    expect(find.text('关于'), findsOneWidget);
    expect(find.text('逻辑刷新率'), findsOneWidget);
    expect(find.textContaining('v0.2.1'), findsWidgets);
  });

  testWidgets('切换逻辑刷新率', (tester) async {
    final settings = await pumpSettings(tester);
    expect(settings.logicRate, LogicRate.hz60);

    await tester.tap(find.text('30 Hz 省电'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(settings.logicRate, LogicRate.hz30);
  });

  testWidgets('开关同步偏好', (tester) async {
    final settings = await pumpSettings(tester);
    final switches = find.byType(Switch);
    expect(switches, findsNWidgets(4));

    await tester.tap(switches.at(0));
    await tester.pump(const Duration(milliseconds: 200));
    expect(settings.darkMode, isTrue);

    await tester.tap(switches.at(1));
    await tester.pump(const Duration(milliseconds: 200));
    expect(settings.soundEnabled, isFalse);
  });

  testWidgets('查看运行日志', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('查看日志'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('运行日志'), findsOneWidget);
    expect(find.text('关闭'), findsOneWidget);
  });
}
