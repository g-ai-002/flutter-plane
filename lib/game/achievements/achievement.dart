/// 成就图标：逻辑层不依赖 Flutter，界面层再把枚举映射成具体图标。
enum AchievementBadge {
  launch,
  score,
  wave,
  kill,
  combo,
  boss,
  daily,
  streak,
  trophy,
}

/// 一条成就定义：进度由累计战绩快照计算，达到目标即解锁。
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.badge,
    required this.target,
    required this.progress,
  });

  final String id;
  final String title;
  final String description;
  final AchievementBadge badge;
  final int target;
  final int Function(AchievementSnapshot snapshot) progress;
}

/// 累计战绩快照，界面与成就判定共用同一份数据。
class AchievementSnapshot {
  const AchievementSnapshot({
    required this.runs,
    required this.highScore,
    required this.bestWave,
    required this.lifetimeKills,
    required this.lifetimeBossKills,
    required this.bestCombo,
    required this.challengeRuns,
    required this.challengeBestStreak,
    required this.challengeBestEver,
  });

  final int runs;
  final int highScore;
  final int bestWave;
  final int lifetimeKills;
  final int lifetimeBossKills;
  final int bestCombo;
  final int challengeRuns;
  final int challengeBestStreak;
  final int challengeBestEver;
}

/// 成就目录：普通战绩与每日挑战各占一半，覆盖短期与长期目标。
final List<Achievement> kAchievements = [
  Achievement(
    id: 'first_run',
    title: '初次出击',
    description: '完成第一次战斗',
    badge: AchievementBadge.launch,
    target: 1,
    progress: (s) => s.runs,
  ),
  Achievement(
    id: 'score_5k',
    title: '千分新星',
    description: '单局得分达到 5,000',
    badge: AchievementBadge.score,
    target: 5000,
    progress: (s) => s.highScore,
  ),
  Achievement(
    id: 'score_20k',
    title: '破万分卫',
    description: '单局得分达到 20,000',
    badge: AchievementBadge.score,
    target: 20000,
    progress: (s) => s.highScore,
  ),
  Achievement(
    id: 'wave_8',
    title: '深入敌阵',
    description: '到达第 8 波',
    badge: AchievementBadge.wave,
    target: 8,
    progress: (s) => s.bestWave,
  ),
  Achievement(
    id: 'wave_16',
    title: '空域霸主',
    description: '到达第 16 波',
    badge: AchievementBadge.wave,
    target: 16,
    progress: (s) => s.bestWave,
  ),
  Achievement(
    id: 'kills_100',
    title: '百机斩',
    description: '累计击破 100 架敌机',
    badge: AchievementBadge.kill,
    target: 100,
    progress: (s) => s.lifetimeKills,
  ),
  Achievement(
    id: 'kills_1000',
    title: '千机屠戮',
    description: '累计击破 1,000 架敌机',
    badge: AchievementBadge.kill,
    target: 1000,
    progress: (s) => s.lifetimeKills,
  ),
  Achievement(
    id: 'combo_60',
    title: '连击大师',
    description: '单局打出 60 连击',
    badge: AchievementBadge.combo,
    target: 60,
    progress: (s) => s.bestCombo,
  ),
  Achievement(
    id: 'boss_5',
    title: '母舰克星',
    description: '累计击破 5 艘 Boss',
    badge: AchievementBadge.boss,
    target: 5,
    progress: (s) => s.lifetimeBossKills,
  ),
  Achievement(
    id: 'boss_20',
    title: '舰队终结者',
    description: '累计击破 20 艘 Boss',
    badge: AchievementBadge.boss,
    target: 20,
    progress: (s) => s.lifetimeBossKills,
  ),
  Achievement(
    id: 'challenge_first',
    title: '每日先锋',
    description: '完成一次每日挑战',
    badge: AchievementBadge.daily,
    target: 1,
    progress: (s) => s.challengeRuns,
  ),
  Achievement(
    id: 'challenge_streak',
    title: '七日坚持',
    description: '连续 7 天参与每日挑战',
    badge: AchievementBadge.streak,
    target: 7,
    progress: (s) => s.challengeBestStreak,
  ),
  Achievement(
    id: 'challenge_score',
    title: '挑战精英',
    description: '每日挑战单局得分达到 15,000',
    badge: AchievementBadge.trophy,
    target: 15000,
    progress: (s) => s.challengeBestEver,
  ),
];

/// 新解锁的成就，按目录顺序返回。
List<Achievement> newlyUnlockedAchievements(
  AchievementSnapshot snapshot,
  Set<String> unlocked,
) => [
  for (final achievement in kAchievements)
    if (!unlocked.contains(achievement.id) &&
        achievement.progress(snapshot) >= achievement.target)
      achievement,
];

/// 已解锁成就数量（忽略目录中不存在的历史 ID）。
int unlockedAchievementCount(Set<String> unlocked) => kAchievements
    .where((achievement) => unlocked.contains(achievement.id))
    .length;
