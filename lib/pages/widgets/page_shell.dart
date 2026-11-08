import 'package:flutter/material.dart';

import 'space_backdrop.dart';

/// 二级页面外壳：深空背景、透明 AppBar 与统一的内边距滚动区。
///
/// 设置页与成就页共享同一套脚手架，页面只声明标题与内容，避免各自维护
/// 一份 `Scaffold + Stack + SafeArea + ListView` 后出现间距或背景不一致。
class PageShell extends StatelessWidget {
  const PageShell({
    super.key,
    required this.title,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(16, 60, 16, 28),
  });

  final String title;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(title)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SpaceBackdrop(brightness: theme.brightness),
          SafeArea(
            child: ListView(padding: padding, children: children),
          ),
        ],
      ),
    );
  }
}
