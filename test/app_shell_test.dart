import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sky_fighter/app.dart';
import 'package:sky_fighter/services/storage_service.dart';

/// 指定视口尺寸并启动完整应用，返回记录下来的系统 UI 模式调用。
Future<List<String>> pumpApp(WidgetTester tester, Size size) async {
  final calls = <MethodCall>[];
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    calls.add(call);
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );

  // MediaQuery 读取的是 view 的物理尺寸，只改 surface 不会影响沉浸式判定。
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  SharedPreferences.setMockInitialValues({});
  StorageService.resetForTests();
  final storage = await StorageService.instance;

  await tester.pumpWidget(SkyFighterApp(storage: storage));
  await tester.pump();

  return calls
      .where((call) => call.method == 'SystemChrome.setEnabledSystemUIMode')
      .map((call) => '${call.arguments}')
      .toList();
}

void main() {
  testWidgets('手机尺寸下启动首页即进入沉浸式全屏', (tester) async {
    final modes = await pumpApp(tester, const Size(390, 844));
    expect(modes.any((args) => args.contains('immersiveSticky')), isTrue);
  });

  testWidgets('桌面窗口保持系统默认外观', (tester) async {
    final modes = await pumpApp(tester, const Size(1440, 900));
    expect(modes.any((args) => args.contains('immersiveSticky')), isFalse);
  });
}
