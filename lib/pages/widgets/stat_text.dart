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

/// 一组等宽统计条目，可选用竖线分隔。
///
/// 设置页战绩、成就页累计战绩与结算面板共用这份排版，避免各自维护
/// `Row + Expanded + StatText` 后出现字号或对齐方式不一致。
class StatStrip extends StatelessWidget {
  const StatStrip({
    super.key,
    required this.entries,
    this.valueSize = 19,
    this.labelSize = 10.5,
    this.valueColor,
    this.labelColor,
    this.alignment = CrossAxisAlignment.start,
    this.dividerColor,
    this.dividerHeight = 26,
  });

  final List<StatStripEntry> entries;
  final double valueSize;
  final double labelSize;
  final Color? valueColor;
  final Color? labelColor;
  final CrossAxisAlignment alignment;
  final Color? dividerColor;
  final double dividerHeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          Expanded(
            child: StatText(
              label: entries[i].label,
              value: entries[i].value,
              valueSize: valueSize,
              labelSize: labelSize,
              valueColor: valueColor,
              labelColor: labelColor,
              alignment: alignment,
            ),
          ),
          if (dividerColor != null && i < entries.length - 1)
            Container(width: 1, height: dividerHeight, color: dividerColor),
        ],
      ],
    );
  }
}

/// [StatStrip] 的一项：标签与已格式化的数值。
class StatStripEntry {
  const StatStripEntry({required this.label, required this.value});

  final String label;
  final String value;
}
