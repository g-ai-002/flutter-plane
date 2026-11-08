import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/pages/widgets/stat_text.dart';
import 'package:sky_fighter/pages/widgets/surface_panel.dart';

void main() {
  testWidgets('统计条按条目渲染并可选择分隔线', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatStrip(
            entries: [
              StatStripEntry(label: '最高分', value: '12,345'),
              StatStripEntry(label: '最远波次', value: '8'),
              StatStripEntry(label: '出击次数', value: '3'),
            ],
            dividerColor: Color(0x22FFFFFF),
          ),
        ),
      ),
    );

    expect(find.text('最高分'), findsOneWidget);
    expect(find.text('12,345'), findsOneWidget);
    expect(find.text('最远波次'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('出击次数'), findsOneWidget);
    expect(find.byType(StatText), findsNWidgets(3));
    // 三条目之间两条竖线，最后一条之后不再绘制。
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints ==
                const BoxConstraints.tightFor(width: 1, height: 26),
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('内容卡片使用主题表面色与自定义描边', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SurfacePanel(
            radius: 12,
            opacity: 0.5,
            borderColor: Color(0xFFFFC451),
            borderOpacity: 0.8,
            child: Text('内容'),
          ),
        ),
      ),
    );

    expect(find.text('内容'), findsOneWidget);
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(SurfacePanel),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(12));
    expect(decoration.border, isNotNull);
  });
}
