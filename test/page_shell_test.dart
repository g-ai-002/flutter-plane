import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/pages/widgets/page_shell.dart';
import 'package:sky_fighter/pages/widgets/space_backdrop.dart';

void main() {
  testWidgets('页面外壳提供标题、背景与可滚动内容', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: PageShell(
          title: '测试页',
          children: [
            for (var i = 0; i < 30; i++)
              SizedBox(height: 60, child: Text('条目 $i')),
          ],
        ),
      ),
    );

    expect(find.text('测试页'), findsOneWidget);
    expect(find.byType(SpaceBackdrop), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('条目 0'), findsOneWidget);
  });
}
