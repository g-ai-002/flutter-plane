import 'package:flutter/material.dart';

/// 数值与标签的统计文本，首页卡片、设置页与结算遮罩共用同一套排版。
///
/// [labelFirst] 为 true 时标签在上、数值在下；默认数值在上，便于扫读。
class StatText extends StatelessWidget {
  const StatText({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.labelFirst = false,
    this.valueSize = 19,
    this.labelSize = 10.5,
    this.valueColor,
    this.labelColor,
    this.letterSpacing = 0.3,
    this.alignment = CrossAxisAlignment.start,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool labelFirst;
  final double valueSize;
  final double labelSize;
  final Color? valueColor;
  final Color? labelColor;
  final double letterSpacing;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final labelWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: labelColor ?? colors.onSurfaceVariant),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: labelSize,
            color: labelColor ?? colors.onSurfaceVariant,
            letterSpacing: letterSpacing,
          ),
        ),
      ],
    );
    final valueWidget = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: valueSize,
        fontWeight: FontWeight.w800,
        height: 1.15,
        color: valueColor ?? colors.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: labelFirst
          ? [labelWidget, const SizedBox(height: 3), valueWidget]
          : [valueWidget, const SizedBox(height: 2), labelWidget],
    );
  }
}
