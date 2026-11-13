import 'package:flutter/material.dart';

import '../../game/battle/battle_controller.dart';
import '../../game/battle/battle_types.dart';
import '../../game/battle/rules_text.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'hud_stats.dart';

/// 战斗 HUD：得分、生命、炸弹、波次、连击与 Boss 血条。
///
/// 全部元素悬浮在战场四周，不参与战场尺寸计算，提示变化不会推动战场布局。
class BattleHud extends StatelessWidget {
  const BattleHud({
    super.key,
    required this.controller,
    required this.field,
    required this.stage,
    required this.onPause,
    required this.onBomb,
  });

  final BattleController controller;
  final Rect field;
  final Size stage;
  final VoidCallback onPause;
  final VoidCallback onBomb;

  static const Color _ink = Color(0xF2FFFFFF);
  static const Color _muted = Color(0x99FFFFFF);

  @override
  Widget build(BuildContext context) {
    final leftMargin = field.left;
    final rightMargin = stage.width - field.right;
    final wide = leftMargin >= 176 && rightMargin >= 176;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (wide)
          ..._wideLayout(leftMargin, rightMargin)
        else
          ..._compactLayout(),
        _hint(),
      ],
    );
  }

  // ---------------------------------------------------------------- 紧凑布局
  // 窄屏把得分与数量提示沿左边缘竖排，Boss 血条缩成右侧小血条，
  // 屏幕中线留给弹幕与战机。

  List<Widget> _compactLayout() => [
    Positioned(
      left: 10,
      top: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _scorePanel(compact: true),
          const SizedBox(height: 10),
          _statusColumn(),
          if (controller.combo >= 2) ...[
            const SizedBox(height: 8),
            _comboBadge(),
          ],
        ],
      ),
    ),
    Positioned(
      right: 8,
      top: 8,
      child: _roundButton(
        icon: Icons.pause_rounded,
        tooltip: '暂停',
        onTap: onPause,
      ),
    ),
    if (controller.boss != null)
      Positioned(
        right: 10,
        top: 62,
        // 小血条只占右侧窄条，宽度随屏幕收回，不越过中线。
        width: (stage.width * 0.32).clamp(112.0, 148.0),
        child: _bossBarContent(compact: true),
      ),
    Positioned(left: 10, bottom: 10, child: _wavePanel(compact: true)),
    Positioned(right: 12, bottom: 12, child: _bombButton()),
  ];

  // ---------------------------------------------------------------- 宽屏布局
  // 桌面与大平板把 HUD 放进战场两侧的留白，战场本身保持干净。

  List<Widget> _wideLayout(double leftMargin, double rightMargin) {
    final panelWidth = (leftMargin - 32).clamp(150.0, 210.0);
    return [
      Positioned(
        left: 16,
        top: 18,
        width: panelWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _scorePanel(),
            const SizedBox(height: 10),
            _wavePanel(column: true),
            const SizedBox(height: 10),
            _statusPanel(),
            if (controller.combo >= 2) ...[
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerLeft, child: _comboBadge()),
            ],
          ],
        ),
      ),
      Positioned(
        right: 16,
        top: 18,
        width: (rightMargin - 32).clamp(120.0, 190.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: _roundButton(
                icon: Icons.pause_rounded,
                tooltip: '暂停',
                onTap: onPause,
              ),
            ),
            const SizedBox(height: 14),
            Align(alignment: Alignment.centerRight, child: _bombButton()),
            if (controller.boss != null) ...[
              const SizedBox(height: 14),
              _bossBarContent(compact: true),
            ],
          ],
        ),
      ),
    ];
  }

  // ---------------------------------------------------------------- 组件

  Widget _panel({Key? key, required Widget child, EdgeInsets? padding}) =>
      Container(
        key: key,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xC20A1326),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x33FFFFFF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );

  Widget _scorePanel({bool compact = false}) => _panel(
    key: const ValueKey('hud-score'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '得分',
          style: TextStyle(
            fontSize: 9.5,
            letterSpacing: 2.4,
            fontWeight: FontWeight.w600,
            color: _muted,
          ),
        ),
        Text(
          formatScore(controller.score),
          style: TextStyle(
            fontSize: compact ? 21 : 27,
            height: 1.18,
            fontWeight: FontWeight.w800,
            color: _ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          '最高 ${formatScore(controller.highScore)}',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: appAmber,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    ),
  );

  /// 会随战斗变化的状态条目来自 [hudStatsFor]，紧凑竖列与宽屏面板不会
  /// 各自维护一份而出现数值不一致。
  List<HudStat> _statusStats() => hudStatsFor(controller.player);

  /// 紧凑布局的数量提示：沿左边缘竖排，占用宽度不随条目增多而扩张。
  Widget _statusColumn() {
    final stats = _statusStats();
    return _panel(
      key: const ValueKey('hud-status'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < stats.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 5),
              child: Row(
                key: ValueKey('hud-stat-${stats[i].label}'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    stats[i].icon,
                    size: stats[i].stripIconSize,
                    color: stats[i].color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    stats[i].shortValue,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusPanel() {
    final stats = _statusStats();
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '战机状态',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.6,
              color: _muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          for (var i = 0; i < stats.length; i++) ...[
            SizedBox(height: i == 0 ? 8 : 6),
            _statRow(stats[i]),
          ],
        ],
      ),
    );
  }

  Widget _statRow(HudStat stat) => Row(
    children: [
      Icon(stat.icon, size: 15, color: stat.color),
      const SizedBox(width: 6),
      Text(stat.label, style: const TextStyle(fontSize: 11.5, color: _muted)),
      const Spacer(),
      Text(
        stat.fullValue,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: _ink,
        ),
      ),
    ],
  );

  Widget _wavePanel({bool compact = false, bool column = false}) => _panel(
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 9 : 12,
      vertical: compact ? 6 : 9,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.graphic_eq_rounded, size: 15, color: appCyan),
        const SizedBox(width: 5),
        Text(
          controller.waveLabel,
          style: TextStyle(
            fontSize: compact ? 11.5 : 12.5,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        if (column) const Spacer() else const SizedBox(width: 10),
        Text(
          controller.challenge == null
              ? '火力 ${controller.player.weaponLevel}'
              : '挑战 · ${controller.challengeModifier.label}',
          style: TextStyle(
            fontSize: compact ? 10.5 : 11,
            color: controller.challenge == null
                ? const Color(0xFF9BE8FF)
                : appAmber,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _bossBarContent({bool compact = false}) {
    final boss = controller.boss;
    if (boss == null) return const SizedBox.shrink();
    final barHeight = compact ? 4.0 : 6.0;
    return _panel(
      key: const ValueKey('hud-boss'),
      padding: compact
          ? const EdgeInsets.fromLTRB(8, 6, 8, 7)
          : const EdgeInsets.fromLTRB(12, 8, 12, 10),
      // 血量走独立通知器：Boss 战期间只有这条血条重建，HUD 其余部分不动。
      child: ValueListenableBuilder<int>(
        valueListenable: controller.bossHp,
        builder: (context, permille, _) {
          final ratio = permille > 0
              ? permille / 1000
              : boss.hpRatio.clamp(0.0, 1.0);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!compact) ...[
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: appCrimson,
                    ),
                    const SizedBox(width: 5),
                  ],
                  Expanded(
                    child: Text(
                      controller.bossName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: compact ? 10.5 : 12,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                        letterSpacing: compact ? 0 : 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(ratio * 100).ceil()}%',
                    style: TextStyle(
                      fontSize: compact ? 10 : 11,
                      fontWeight: FontWeight.w700,
                      color: appCrimson,
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 4 : 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    Container(
                      height: barHeight,
                      color: const Color(0x33FFFFFF),
                    ),
                    FractionallySizedBox(
                      widthFactor: ratio,
                      child: Container(
                        height: barHeight,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [appCrimson, appAmber],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _comboBadge() {
    final multiplier = controller.multiplier;
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xC21A1206),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: (multiplier > 1 ? appAmber : const Color(0x66FFFFFF))
                .withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${controller.combo} 连击',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            if (multiplier > 1) ...[
              const SizedBox(width: 6),
              Text(
                '×$multiplier',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: appAmber,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _roundButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) => Container(
    decoration: BoxDecoration(
      color: const Color(0xC20A1326),
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0x44FFFFFF)),
    ),
    child: IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 22),
      color: _ink,
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      padding: EdgeInsets.zero,
    ),
  );

  Widget _bombButton() {
    final enabled = controller.player.bombs > 0;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: enabled ? onBomb : null,
          customBorder: const CircleBorder(),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFFFFB74D), Color(0xFFE0524C)],
                center: Alignment(-0.3, -0.4),
              ),
              border: Border.all(color: const Color(0xFFFFE0A3), width: 1.4),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66FF6B4A),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 28,
                  color: Colors.white,
                ),
                Positioned(
                  right: 6,
                  bottom: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xCC1A0B06),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${controller.player.bombs}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hint() {
    if (controller.elapsed >= BattleController.hintDuration ||
        controller.phase != BattlePhase.playing) {
      return const SizedBox.shrink();
    }
    final fade = (1 - controller.elapsed / BattleController.hintDuration).clamp(
      0.0,
      1.0,
    );
    return Positioned(
      left: 0,
      right: 0,
      bottom: 92,
      child: IgnorePointer(
        child: Center(
          child: Opacity(
            opacity: fade * 0.85,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0x99061120),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0x33FFFFFF)),
              ),
              child: const Text(
                kBattleInputHint,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xE6FFFFFF),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
