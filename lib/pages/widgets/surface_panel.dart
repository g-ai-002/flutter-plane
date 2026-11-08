import 'package:flutter/material.dart';

/// 统一的内容卡片外观：主题表面色、细描边与圆角。
///
/// 首页战绩格、设置分区、成就概要与成就条目共用这一层容器，只通过参数
/// 调整透明度、圆角与描边色，避免同一个 `BoxDecoration` 在四处各写一遍。
class SurfacePanel extends StatelessWidget {
  const SurfacePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 12),
    this.radius = 16,
    this.opacity = 0.86,
    this.borderColor,
    this.borderOpacity = 0.7,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double opacity;
  final Color? borderColor;
  final double borderOpacity;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: (borderColor ?? colors.outline).withValues(
            alpha: borderOpacity,
          ),
        ),
      ),
      child: child,
    );
  }
}
