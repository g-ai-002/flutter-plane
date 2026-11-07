import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sky_fighter/game/achievements/achievement.dart';
import 'package:sky_fighter/game/challenge/daily_challenge.dart';
import 'package:sky_fighter/providers/settings_provider.dart';
import 'package:sky_fighter/services/storage_service.dart';

AchievementSnapshot emptySnapshot({int runs = 0}) => AchievementSnapshot(
  runs: runs,
  highScore: 0,
  bestWave: 0,
  lifetimeKills: 0,
  lifetimeBossKills: 0,
  bestCombo: 0,
  challengeRuns: 0,
  challengeBestStreak: 0,
  challengeBestEver: 0,
);

Future<SettingsProvider> buildSettings() async {
  final storage = await StorageService.instance;
  return SettingsProvider(storage);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.resetForTests();
  });

  group('成就判定', () {
    test('进度达到目标后解锁', () {
      const snapshot = AchievementSnapshot(
        runs: 1,
        highScore: 6000,
        bestWave: 9,
        lifetimeKills: 130,
        lifetimeBossKills: 5,
        bestCombo: 62,
        challengeRuns: 0,
        challengeBestStreak: 0,
        challengeBestEver: 0,
      );
      final unlocked = newlyUnlockedAchievements(snapshot, const {});
      final ids = unlocked.map((item) => item.id).toSet();
      expect(ids, containsAll(['first_run', 'score_5k', 'wave_8']));
      expect(ids, containsAll(['kills_100', 'combo_60', 'boss_5']));
      expect(ids, isNot(contains('score_20k')));
      expect(ids, isNot(contains('challenge_first')));
    });

    test('已解锁的成就不会重复返回', () {
      final snapshot = emptySnapshot(runs: 3);
      final unlocked = newlyUnlockedAchievements(snapshot, {'first_run'});
      expect(unlocked, isEmpty);
    });

    test('目录内成就计数忽略未知 ID', () {
      expect(unlockedAchievementCount({'first_run', 'score_5k', 'legacy'}), 2);
      expect(unlockedAchievementCount(const {}), 0);
    });
  });

  group('战斗结算', () {
    test('普通战斗写入战绩、累计击破与新成就', () async {
      final settings = await buildSettings();
      final outcome = await settings.finishRun(
        score: 6000,
        wave: 9,
        kills: 120,
        bossKills: 5,
        maxCombo: 62,
      );

      expect(outcome.isRecord, isTrue);
      expect(outcome.unlocked.map((item) => item.id), contains('first_run'));
      expect(outcome.unlocked.map((item) => item.id), contains('score_5k'));
      expect(settings.highScore, 6000);
      expect(settings.bestWave, 9);
      expect(settings.runs, 1);
      expect(settings.lifetimeKills, 120);
      expect(settings.lifetimeBossKills, 5);
      expect(settings.bestCombo, 62);
      expect(settings.unlockedAchievements, contains('first_run'));
      expect(settings.achievementCount, outcome.unlocked.length);

      final again = await settings.finishRun(
        score: 500,
        wave: 2,
        kills: 3,
        bossKills: 0,
        maxCombo: 5,
      );
      expect(again.isRecord, isFalse);
      expect(again.unlocked, isEmpty);
      expect(settings.lifetimeKills, 123);
      expect(settings.bestCombo, 62);
    });

    test('每日挑战独立计分并推进挑战成就', () async {
      final settings = await buildSettings();
      final challenge = DailyChallenge.forDate(DateTime(2026, 11, 8));
      final outcome = await settings.finishRun(
        score: 16000,
        wave: 11,
        kills: 80,
        bossKills: 2,
        maxCombo: 30,
        challenge: challenge,
      );

      expect(outcome.isRecord, isTrue);
      expect(outcome.dailyBest, 16000);
      expect(settings.highScore, 0);
      expect(settings.runs, 0);
      expect(settings.challengeProgress(challenge).bestScore, 16000);
      expect(settings.unlockedAchievements, contains('challenge_first'));
      expect(settings.unlockedAchievements, contains('challenge_score'));
      expect(settings.achievementCount, outcome.unlocked.length);
    });
  });
}
