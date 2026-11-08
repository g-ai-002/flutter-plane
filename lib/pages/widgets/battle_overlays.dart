import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../game/achievements/achievement.dart';
import '../../game/challenge/daily_challenge.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'stat_text.dart';

/// 战斗遮罩的玻璃卡片外观。
class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child, required this.width});

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    // 小屏或解锁成就较多时允许面板内部滚动，按钮始终可达。
    final maxHeight = (MediaQuery.sizeOf(context).height - 48).clamp(
      240.0,
      2000.0,
    );
    return Container(
      width: width,
      constraints: BoxConstraints(maxHeight: maxHeight),
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xF2162340), Color(0xF20B1120)],
        ),
        border: Border.all(color: const Color(0x33A9E9FF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 40,
            offset: Offset(0, 16),
          ),
          BoxShadow(color: Color(0x2235C8FF), blurRadius: 30),
        ],
      ),
      child: SingleChildScrollView(
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Color(0xFFE7EEFA)),
          child: child,
        ),
      ),
    );
  }
}

class _OverlayScrim extends StatelessWidget {
  const _OverlayScrim({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0x99030911),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// 暂停遮罩：继续、重开或返回主页。
class BattlePauseOverlay extends StatelessWidget {
  const BattlePauseOverlay({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return _OverlayScrim(
      child: _GlassPanel(
        width: (width - 48).clamp(260.0, 360.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: appCyan.withValues(alpha: 0.12),
                border: Border.all(color: appCyan.withValues(alpha: 0.5)),
              ),
              child: const Icon(Icons.pause_rounded, color: appCyan, size: 30),
            ),
            const SizedBox(height: 14),
            const Text(
              '战斗暂停',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '战机已原地待命',
              style: TextStyle(fontSize: 12, color: Color(0x99FFFFFF)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onResume,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('继续战斗'),
                style: FilledButton.styleFrom(
                  backgroundColor: appCyan,
                  foregroundColor: const Color(0xFF00243A),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('重新开始'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE7EEFA),
                  side: const BorderSide(color: Color(0x44FFFFFF)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: onExit,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0x99FFFFFF),
              ),
              child: const Text('返回主页'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 结算遮罩：得分、最高分、波次、击破数与新解锁成就。
class BattleResultOverlay extends StatelessWidget {
  const BattleResultOverlay({
    super.key,
    required this.score,
    required this.best,
    required this.wave,
    required this.kills,
    required this.survived,
    required this.isRecord,
    required this.onRestart,
    required this.onExit,
    this.challenge,
    this.dailyBest = 0,
    this.unlocked = const [],
  });

  final int score;
  final int best;
  final int wave;
  final int kills;
  final Duration survived;
  final bool isRecord;
  final VoidCallback onRestart;
  final VoidCallback onExit;
  final DailyChallenge? challenge;
  final int dailyBest;
  final List<Achievement> unlocked;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isChallenge = challenge != null;
    return _OverlayScrim(
      child: _GlassPanel(
        width: (width - 48).clamp(260.0, 380.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: appCrimson.withValues(alpha: 0.12),
                border: Border.all(color: appCrimson.withValues(alpha: 0.5)),
              ),
              child: Icon(
                isChallenge
                    ? Icons.event_available_rounded
                    : Icons.rocket_launch_rounded,
                color: isChallenge ? appAmber : appCrimson,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isChallenge ? '挑战结束' : '战机坠毁',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
            if (isChallenge) ...[
              const SizedBox(height: 4),
              Text(
                '${challenge!.dateLabel} · ${challenge!.modifier.label}',
                style: const TextStyle(fontSize: 11, color: Color(0x99FFFFFF)),
              ),
            ],
            const SizedBox(height: 14),
            if (isRecord)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: appAmber.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: appAmber.withValues(alpha: 0.6)),
                ),
                child: Text(
                  isChallenge ? '今日新纪录' : '新纪录',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: appAmber,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            Text(
              formatScore(score),
              style: const TextStyle(
                fontSize: 40,
                height: 1.1,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: Colors.white,
              ),
            ),
            Text(
              isChallenge
                  ? '今日最佳 ${formatScore(dailyBest)}'
                  : '最高分 ${formatScore(best)}',
              style: const TextStyle(fontSize: 11.5, color: Color(0x99FFFFFF)),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0x33FFFFFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x1AFFFFFF)),
              ),
              child: StatStrip(
                entries: [
                  StatStripEntry(label: '波次', value: '$wave'),
                  StatStripEntry(label: '击破', value: '$kills'),
                  StatStripEntry(label: '存活', value: formatDuration(survived)),
                ],
                valueSize: 17,
                valueColor: Colors.white,
                labelColor: const Color(0x99FFFFFF),
                alignment: CrossAxisAlignment.center,
                dividerColor: const Color(0x22FFFFFF),
              ),
            ),
            if (unlocked.isNotEmpty) ...[
              const SizedBox(height: 12),
              _UnlockedAchievements(items: unlocked),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onRestart,
                icon: const Icon(Icons.replay_rounded),
                label: Text(isChallenge ? '再次挑战' : '再来一局'),
                style: FilledButton.styleFrom(
                  backgroundColor: appCyan,
                  foregroundColor: const Color(0xFF00243A),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: onExit,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0x99FFFFFF),
              ),
              child: const Text('返回主页'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 结算面板里的成就提示：最多列出三项，避免遮挡主要战绩。
class _UnlockedAchievements extends StatelessWidget {
  const _UnlockedAchievements({required this.items});

  final List<Achievement> items;

  @override
  Widget build(BuildContext context) {
    final shown = items.take(3).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: BoxDecoration(
        color: appAmber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appAmber.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, size: 14, color: appAmber),
              const SizedBox(width: 5),
              Text(
                '解锁 ${items.length} 项成就',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: appAmber,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            [
              for (final item in shown) item.title,
              if (items.length > shown.length) '等',
            ].join(' · '),
            style: const TextStyle(fontSize: 11, color: Color(0xCCFFFFFF)),
          ),
        ],
      ),
    );
  }
}
