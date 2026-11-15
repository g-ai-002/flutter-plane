import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sky_fighter/utils/display_mode.dart';

/// 记录系统 UI 模式的平台调用。
List<String> recordSystemUiMode(WidgetTester tester) {
  final modes = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'SystemChrome.setEnabledSystemUIMode') {
        modes.add('${call.arguments}');
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return modes;
}

void main() {
  testWidgets('沉浸式作用域在挂载时隐藏系统栏，卸载时恢复', (tester) async {
    final modes = recordSystemUiMode(tester);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ImmersiveFullscreen(child: Text('战场'))),
      ),
    );
    await tester.pump();
    expect(modes.last, contains('immersiveSticky'));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(modes.last, contains('edgeToEdge'));
  });

  testWidgets('平板上不隐藏系统栏', (tester) async {
    final modes = recordSystemUiMode(tester);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(834, 1112);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ImmersiveFullscreen(child: Text('战场'))),
      ),
    );
    await tester.pump();
    expect(modes, isEmpty);
  });
}
