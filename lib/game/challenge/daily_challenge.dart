import '../../utils/formatters.dart';

/// 每日挑战的战场修正：同一套战斗循环，用不同的限制制造新鲜感。
///
/// 只提供少量可叠加的数值修正，避免为挑战模式复制一套战斗逻辑。
enum ChallengeModifier {
  standard(label: '标准空域', description: '常规战场节奏'),
  barrage(
    label: '弹幕压制',
    description: '敌弹速度 +16%，单局得分 ×1.1',
    enemyBulletSpeedScale: 1.16,
    scoreScale: 1.1,
  ),
  armor(
    label: '重装舰队',
    description: '敌机血量 +22%，单局得分 ×1.15',
    enemyHpScale: 1.22,
    scoreScale: 1.15,
  ),
  scarcity(
    label: '补给管制',
    description: '补给掉率 -38%，单局得分 ×1.2',
    dropScale: 0.62,
    scoreScale: 1.2,
  ),
  ace(
    label: '单机突入',
    description: '初始生命 2 点，单局得分 ×1.3',
    startLivesDelta: -1,
    scoreScale: 1.3,
  ),
  arsenal(
    label: '火力演习',
    description: '开局火力 3 级，单局得分 ×1.1',
    startWeaponLevel: 3,
    scoreScale: 1.1,
  );

  const ChallengeModifier({
    required this.label,
    required this.description,
    this.enemyHpScale = 1,
    this.enemyBulletSpeedScale = 1,
    this.dropScale = 1,
    this.scoreScale = 1,
    this.startLivesDelta = 0,
    this.startWeaponLevel = 1,
  });

  final String label;
  final String description;
  final double enemyHpScale;
  final double enemyBulletSpeedScale;
  final double dropScale;
  final double scoreScale;
  final int startLivesDelta;
  final int startWeaponLevel;
}

const List<String> _kWeekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

/// 当天的挑战：日期决定随机种子与修正规则，同一天重开得到相同战场。
class DailyChallenge {
  const DailyChallenge({
    required this.dateKey,
    required this.seed,
    required this.modifier,
  });

  final String dateKey;
  final int seed;
  final ChallengeModifier modifier;

  /// 修正规则按天轮换，五种规则覆盖不同的操作压力。
  static const List<ChallengeModifier> rotation = [
    ChallengeModifier.barrage,
    ChallengeModifier.armor,
    ChallengeModifier.scarcity,
    ChallengeModifier.ace,
    ChallengeModifier.arsenal,
  ];

  factory DailyChallenge.forDate(DateTime date) {
    final dayIndex =
        DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
    return DailyChallenge(
      dateKey: formatDateKey(date),
      seed: (dayIndex * 7919 + 20261108) & 0x7FFFFFFF,
      modifier: rotation[dayIndex % rotation.length],
    );
  }

  static DailyChallenge today() => DailyChallenge.forDate(DateTime.now());

  String get dateLabel {
    final date = parseDateKey(dateKey);
    final weekday = _kWeekdays[date.weekday - 1];
    return '${date.month}月${date.day}日 $weekday';
  }
}

/// 把 `yyyyMMdd` 解析成本地日期，挑战文案与连续天数共用同一套解析。
DateTime parseDateKey(String dateKey) => DateTime(
  int.parse(dateKey.substring(0, 4)),
  int.parse(dateKey.substring(4, 6)),
  int.parse(dateKey.substring(6, 8)),
);

/// 一个日期前一天的键，用于判断连续挑战天数。
String previousDateKey(String dateKey) =>
    formatDateKey(parseDateKey(dateKey).subtract(const Duration(days: 1)));

/// 今日挑战的进度快照：最佳分数、最佳波次、今日已战次数与连续天数。
class ChallengeProgress {
  const ChallengeProgress({
    required this.dateKey,
    required this.bestScore,
    required this.bestWave,
    required this.plays,
    required this.streak,
  });

  final String dateKey;
  final int bestScore;
  final int bestWave;
  final int plays;
  final int streak;

  bool get playedToday => plays > 0;
}
