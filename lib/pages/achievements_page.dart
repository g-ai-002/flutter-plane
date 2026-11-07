import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/achievements/achievement.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'widgets/space_backdrop.dart';
import 'widgets/stat_text.dart';

Future<void> openAchievementsPage(BuildContext context) {
  return Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const AchievementsPage()));
}

/// 成就页：展示解锁进度、累计战绩与每一条成就的完成度。
class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  static IconData iconFor(AchievementBadge badge) => switch (badge) {
    AchievementBadge.launch => Icons.flight_takeoff_rounded,
    AchievementBadge.score => Icons.trending_up_rounded,
    AchievementBadge.wave => Icons.flag_rounded,
    AchievementBadge.kill => Icons.gps_fixed_rounded,
    AchievementBadge.combo => Icons.bolt_rounded,
    AchievementBadge.boss => Icons.shield_moon_outlined,
    AchievementBadge.daily => Icons.event_available_rounded,
    AchievementBadge.streak => Icons.local_fire_department_rounded,
    AchievementBadge.trophy => Icons.emoji_events_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final unlocked = settings.unlockedAchievements;
    final snapshot = settings.achievementSnapshot;
    final done = unlockedAchievementCount(unlocked);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('成就')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SpaceBackdrop(brightness: theme.brightness),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 28),
              children: [
                _SummaryCard(done: done, snapshot: snapshot),
                const SizedBox(height: 12),
                for (final achievement in kAchievements) ...[
                  _AchievementTile(
                    achievement: achievement,
                    unlocked: unlocked.contains(achievement.id),
                    progress: achievement.progress(snapshot),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.done, required this.snapshot});

  final int done;
  final AchievementSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final total = kAchievements.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, size: 18, color: appAmber),
              const SizedBox(width: 7),
              Text(
                '已解锁 $done / $total',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Text(
                '${(done * 100 / total).round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: appAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: done / total,
              minHeight: 5,
              backgroundColor: colors.outline.withValues(alpha: 0.5),
              valueColor: const AlwaysStoppedAnimation<Color>(appAmber),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatText(
                  label: '累计击破',
                  value: formatScore(snapshot.lifetimeKills),
                ),
              ),
              Expanded(
                child: StatText(
                  label: 'Boss 击破',
                  value: '${snapshot.lifetimeBossKills}',
                ),
              ),
              Expanded(
                child: StatText(label: '最高连击', value: '${snapshot.bestCombo}'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.achievement,
    required this.unlocked,
    required this.progress,
  });

  final Achievement achievement;
  final bool unlocked;
  final int progress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ratio = (progress / achievement.target).clamp(0.0, 1.0);
    final accent = unlocked ? appAmber : colors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 14, 11),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: unlocked ? 0.92 : 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: unlocked
              ? appAmber.withValues(alpha: 0.45)
              : colors.outline.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: unlocked ? 0.16 : 0.08),
            ),
            child: Icon(
              AchievementsPage.iconFor(achievement.badge),
              size: 19,
              color: accent,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: unlocked ? colors.onSurface : accent,
                        ),
                      ),
                    ),
                    Text(
                      unlocked
                          ? '已解锁'
                          : '${formatScore(progress.clamp(0, achievement.target))}'
                                ' / ${formatScore(achievement.target)}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 3,
                    backgroundColor: colors.outline.withValues(alpha: 0.4),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
