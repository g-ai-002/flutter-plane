import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../game/challenge/daily_challenge.dart';
import '../providers/settings_provider.dart';
import '../services/log_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'achievements_page.dart';
import 'game_page.dart';
import 'settings_page.dart';
import 'widgets/how_to_play.dart';
import 'widgets/space_backdrop.dart';
import 'widgets/stat_text.dart';
import 'widgets/surface_panel.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final challenge = DailyChallenge.today();
    final progress = settings.challengeProgress(challenge);
    final wide =
        MediaQuery.sizeOf(context).width >= 940 &&
        MediaQuery.sizeOf(context).height >= 640;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SpaceBackdrop(brightness: theme.brightness),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 40 : 20,
                    8,
                    wide ? 40 : 20,
                    24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: math.max(0, constraints.maxHeight - 32),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: wide ? 1040 : 540,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _TopBar(settings: settings),
                            const SizedBox(height: 6),
                            if (wide)
                              Row(
                                children: [
                                  const Expanded(
                                    child: Center(
                                      child: PlaneEmblem(size: 340),
                                    ),
                                  ),
                                  const SizedBox(width: 36),
                                  SizedBox(
                                    width: 470,
                                    child: _Hero(
                                      settings: settings,
                                      wide: true,
                                      challenge: challenge,
                                      progress: progress,
                                      onStart: () => _startGame(context),
                                      onStartChallenge: () =>
                                          _startGame(context, challenge),
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              const PlaneEmblem(size: 196),
                              const SizedBox(height: 6),
                              _Hero(
                                settings: settings,
                                wide: false,
                                challenge: challenge,
                                progress: progress,
                                onStart: () => _startGame(context),
                                onStartChallenge: () =>
                                    _startGame(context, challenge),
                              ),
                            ],
                            const SizedBox(height: 18),
                            Text(
                              'v${AppConstants.version} · 本地运行 · 无需联网',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _startGame(BuildContext context, [DailyChallenge? challenge]) {
    LogService.info(
      challenge == null
          ? '进入战斗'
          : '进入每日挑战 ${challenge.dateKey} ${challenge.modifier.label}',
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => GamePage(challenge: challenge)),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.settings});

  final SettingsProvider settings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.primary.withValues(alpha: 0.1),
            border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
          ),
          child: Icon(
            Icons.rocket_launch_rounded,
            size: 17,
            color: colors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          AppConstants.appName,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: colors.onSurface,
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: '成就',
          onPressed: () => openAchievementsPage(context),
          icon: Badge.count(
            count: settings.achievementCount,
            isLabelVisible: settings.achievementCount > 0,
            backgroundColor: appAmber,
            textColor: const Color(0xFF2A1A00),
            child: const Icon(Icons.emoji_events_outlined, size: 21),
          ),
        ),
        IconButton(
          tooltip: settings.darkMode ? '切换到浅色' : '切换到深色',
          onPressed: () => settings.setDarkMode(!settings.darkMode),
          icon: Icon(
            settings.darkMode
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            size: 21,
          ),
        ),
        IconButton(
          tooltip: '设置',
          onPressed: () => openSettingsPage(context),
          icon: const Icon(Icons.tune_rounded, size: 21),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.settings,
    required this.wide,
    required this.challenge,
    required this.progress,
    required this.onStart,
    required this.onStartChallenge,
  });

  final SettingsProvider settings;
  final bool wide;
  final DailyChallenge challenge;
  final ChallengeProgress progress;
  final VoidCallback onStart;
  final VoidCallback onStartChallenge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: wide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [
                    Color(0xFF9BE8FF),
                    Color(0xFFFFFFFF),
                    Color(0xFFB39DFF),
                  ]
                : const [
                    Color(0xFF0E63B8),
                    Color(0xFF35C8FF),
                    Color(0xFF7B3FF2),
                  ],
          ).createShader(rect),
          child: Text(
            AppConstants.appName,
            textAlign: wide ? TextAlign.left : TextAlign.center,
            style: TextStyle(
              fontSize: wide ? 52 : 38,
              height: 1.12,
              fontWeight: FontWeight.w900,
              letterSpacing: wide ? 10 : 8,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppConstants.tagline,
          textAlign: wide ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            fontSize: wide ? 14 : 12.5,
            height: 1.6,
            color: colors.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: wide ? WrapAlignment.start : WrapAlignment.center,
          children: const [
            _FeaturePill(label: '竖版弹幕'),
            _FeaturePill(label: '僚机护航'),
            _FeaturePill(label: 'Boss 战'),
            _FeaturePill(label: '每日挑战'),
            _FeaturePill(label: '成就'),
          ],
        ),
        const SizedBox(height: 20),
        _StatRow(settings: settings),
        const SizedBox(height: 12),
        _DailyChallengeCard(
          challenge: challenge,
          progress: progress,
          onTap: onStartChallenge,
        ),
        const SizedBox(height: 20),
        _StartButton(onTap: onStart),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => showHowToPlay(context),
                icon: const Icon(Icons.menu_book_outlined, size: 18),
                label: const Text('玩法说明'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => openSettingsPage(context),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('设置'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.primary.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: colors.primary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.settings});

  final SettingsProvider settings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatTile(
          label: '最高分',
          value: formatScore(settings.highScore),
          icon: Icons.emoji_events_outlined,
        ),
        const SizedBox(width: 8),
        _StatTile(
          label: '最远波次',
          value: '${settings.bestWave}',
          icon: Icons.flag_outlined,
        ),
        const SizedBox(width: 8),
        _StatTile(
          label: '出击次数',
          value: '${settings.runs}',
          icon: Icons.flight_takeoff_rounded,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SurfacePanel(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        radius: 12,
        opacity: 0.72,
        child: StatText(
          label: label,
          value: value,
          icon: icon,
          labelFirst: true,
          valueSize: 17,
          labelSize: 9.5,
        ),
      ),
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({
    required this.challenge,
    required this.progress,
    required this.onTap,
  });

  final DailyChallenge challenge;
  final ChallengeProgress progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.surface.withValues(alpha: 0.9),
                appAmber.withValues(alpha: 0.09),
              ],
            ),
            border: Border.all(color: appAmber.withValues(alpha: 0.45)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: appAmber.withValues(alpha: 0.14),
                  ),
                  child: const Icon(
                    Icons.event_available_rounded,
                    size: 20,
                    color: appAmber,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '每日挑战',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            challenge.dateLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          if (progress.streak > 0) ...[
                            const SizedBox(width: 6),
                            Text(
                              '连续 ${progress.streak} 天',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: appAmber,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${challenge.modifier.label} · '
                        '${challenge.modifier.description}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.35,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        progress.playedToday
                            ? '今日最佳 ${formatScore(progress.bestScore)} · '
                                  '已战 ${progress.plays} 次'
                            : '今日尚未出战 · 挑战独立计分',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: progress.playedToday
                              ? appAmber
                              : colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.play_circle_fill_rounded,
                  size: 28,
                  color: appAmber.withValues(alpha: 0.85),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7FE7FF), appCyan, Color(0xFF2B6BFF)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x5535C8FF),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: const SizedBox(
            height: 58,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_arrow_rounded,
                  size: 26,
                  color: Color(0xFF00243A),
                ),
                SizedBox(width: 6),
                Text(
                  '开始战斗',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    color: Color(0xFF00243A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
