import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sky_fighter/pages/home_page.dart';
import 'package:sky_fighter/providers/settings_provider.dart';
import 'package:sky_fighter/pages/widgets/space_backdrop.dart';
import 'package:sky_fighter/services/storage_service.dart';
import 'package:sky_fighter/utils/constants.dart';

Future<SettingsProvider> pumpHome(
  WidgetTester tester, {
  Size size = const Size(400, 820),
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  StorageService.resetForTests();
  final storage = await StorageService.instance;
  final settings = SettingsProvider(storage);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ChangeNotifierProvider<SettingsProvider>.value(
      value: settings,
      child: const MaterialApp(home: HomePage()),
    ),
  );
  await tester.pump(const Duration(milliseconds: 350));
  return settings;
}

void main() {
  testWidgets('首页展示标题、战绩与入口', (tester) async {
    await pumpHome(
      tester,
      prefs: {'high_score': 12345, 'best_wave': 6, 'runs': 3},
    );

    expect(find.text('苍穹战机'), findsWidgets);
    expect(find.text('开始战斗'), findsOneWidget);
    expect(find.text('玩法说明'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('12,345'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.textContaining('v${AppConstants.version}'), findsOneWidget);
  });

  testWidgets('玩法说明弹窗展示操作与规则', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('玩法说明'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('操作'), findsOneWidget);
    expect(find.text('目标'), findsOneWidget);
    expect(find.text('补给'), findsOneWidget);
    expect(find.text('连击'), findsOneWidget);

    await tester.tap(find.text('明白了'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('操作'), findsNothing);
  });

  testWidgets('设置按钮进入设置页', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('设置'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('画面与性能'), findsOneWidget);
    expect(find.text('逻辑刷新率'), findsOneWidget);
  });

  testWidgets('首页展示每日挑战入口与今日进度', (tester) async {
    await pumpHome(tester);

    expect(find.text('每日挑战'), findsWidgets);
    expect(find.textContaining('今日尚未出战'), findsOneWidget);
    expect(find.byIcon(Icons.event_available_rounded), findsOneWidget);
  });

  testWidgets('成就入口进入成就页', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byTooltip('成就'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('已解锁 0 / 13'), findsOneWidget);
    expect(find.text('初次出击'), findsOneWidget);
  });

  testWidgets('深色模式按钮即时切换主题', (tester) async {
    final settings = await pumpHome(tester);
    expect(settings.darkMode, isFalse);

    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pump(const Duration(milliseconds: 350));

    expect(settings.darkMode, isTrue);
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
  });

  testWidgets('宽屏使用两栏布局', (tester) async {
    await pumpHome(tester, size: const Size(1280, 860));
    expect(find.byType(PlaneEmblem), findsOneWidget);
    expect(find.text('开始战斗'), findsOneWidget);
  });

  testWidgets('竖屏首页内容垂直居中并铺满可用宽度', (tester) async {
    const height = 900.0;
    await pumpHome(tester, size: const Size(400, height));

    final top = tester.getTopLeft(find.byIcon(Icons.rocket_launch_rounded)).dy;
    final bottom = tester
        .getBottomLeft(find.textContaining('v${AppConstants.version}'))
        .dy;
    // 上下留白接近相等，说明内容块在可视区域内居中而不是贴着顶部。
    expect((top - (height - bottom)).abs(), lessThan(40));

    // 按钮铺满扣除内边距后的宽度，窄屏没有多余的横向留白。
    final button = tester.getRect(
      find.ancestor(
        of: find.text('开始战斗'),
        matching: find.byType(InkWell),
      ),
    );
    expect(button.width, greaterThan(300));
  });

  testWidgets('手机尺寸下背景铺满全屏且内容垂直居中', (tester) async {
    const size = Size(390, 844);
    await pumpHome(tester, size: size);

    // 背景不受 SafeArea 约束，直接铺到屏幕四边，保持沉浸感。
    expect(
      tester.getRect(find.byType(SpaceBackdrop)),
      const Rect.fromLTWH(0, 0, 390, 844),
    );

    final top = tester.getTopLeft(find.byIcon(Icons.rocket_launch_rounded)).dy;
    final bottom = tester
        .getBottomLeft(find.textContaining('v${AppConstants.version}'))
        .dy;
    expect(bottom, lessThanOrEqualTo(size.height));
    expect((top - (size.height - bottom)).abs(), lessThan(40));
  });

  testWidgets('首页徽标旋转只重绘自身图层，绘制资源只构建一次', (tester) async {
    PlaneEmblem.assetBuilds = 0;
    await pumpHome(tester);

    final emblem = find.byType(PlaneEmblem);
    final customPaint = find.descendant(
      of: emblem,
      matching: find.byType(CustomPaint),
    );
    expect(customPaint, findsOneWidget);
    // 徽标动画被 RepaintBoundary 包住，旋转不会带动整页重绘。
    expect(
      find.ancestor(of: customPaint, matching: find.byType(RepaintBoundary)),
      findsWidgets,
    );
    expect(PlaneEmblem.assetBuilds, 1);

    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    // 连续动画帧复用同一份渐变与画笔，不再逐帧新建。
    expect(PlaneEmblem.assetBuilds, 1);
    expect(tester.takeException(), isNull);
  });
}
