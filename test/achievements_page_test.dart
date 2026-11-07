import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sky_fighter/pages/achievements_page.dart';
import 'package:sky_fighter/providers/settings_provider.dart';
import 'package:sky_fighter/services/storage_service.dart';

void main() {
  testWidgets('成就页展示解锁进度与成就列表', (tester) async {
    SharedPreferences.setMockInitialValues({
      'runs': 1,
      'achievements': ['first_run'],
      'lifetime_kills': 12,
      'best_combo': 8,
    });
    StorageService.resetForTests();
    final storage = await StorageService.instance;
    final settings = SettingsProvider(storage);
    await tester.binding.setSurfaceSize(const Size(400, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settings,
        child: const MaterialApp(home: AchievementsPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('成就'), findsWidgets);
    expect(find.text('已解锁 1 / 13'), findsOneWidget);
    expect(find.text('初次出击'), findsOneWidget);
    expect(find.text('已解锁'), findsOneWidget);
    expect(find.text('千分新星'), findsOneWidget);
    expect(find.textContaining('0 / 5,000'), findsOneWidget);
    expect(find.text('累计击破'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
  });
}
