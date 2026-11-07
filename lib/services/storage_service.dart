import 'package:shared_preferences/shared_preferences.dart';

import '../game/challenge/daily_challenge.dart';
import '../game/logic_rate.dart';
import '../utils/constants.dart';

/// 轻量偏好存储：写入失败时静默忽略，不影响战斗主流程。
class StorageService {
  static StorageService? _instance;
  SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> get instance async {
    if (_instance != null) return _instance!;
    final service = StorageService._();
    service._prefs = await SharedPreferences.getInstance();
    _instance = service;
    return service;
  }

  /// 仅供测试：清空单例，配合 SharedPreferences 的 mock 数据使用。
  static void resetForTests() => _instance = null;

  SharedPreferences get _p {
    final prefs = _prefs;
    if (prefs == null) throw StateError('StorageService 尚未初始化');
    return prefs;
  }

  Future<void> _write(
    Future<bool> Function(SharedPreferences prefs) action,
  ) async {
    try {
      await action(_p);
    } catch (_) {}
  }

  bool get darkMode => _p.getBool(AppConstants.prefKeyDarkMode) ?? false;
  Future<void> setDarkMode(bool value) =>
      _write((p) => p.setBool(AppConstants.prefKeyDarkMode, value));

  bool get soundEnabled => _p.getBool(AppConstants.prefKeySound) ?? true;
  Future<void> setSoundEnabled(bool value) =>
      _write((p) => p.setBool(AppConstants.prefKeySound, value));

  bool get musicEnabled => _p.getBool(AppConstants.prefKeyMusic) ?? true;
  Future<void> setMusicEnabled(bool value) =>
      _write((p) => p.setBool(AppConstants.prefKeyMusic, value));

  bool get hapticsEnabled => _p.getBool(AppConstants.prefKeyHaptics) ?? true;
  Future<void> setHapticsEnabled(bool value) =>
      _write((p) => p.setBool(AppConstants.prefKeyHaptics, value));

  /// 逻辑更新速率，未设置或未知值回退到 60Hz。
  LogicRate get logicRate =>
      LogicRate.byName(_p.getString(AppConstants.prefKeyLogicRate));
  Future<void> setLogicRate(LogicRate value) =>
      _write((p) => p.setString(AppConstants.prefKeyLogicRate, value.name));

  int get highScore => _p.getInt(AppConstants.prefKeyHighScore) ?? 0;
  int get bestWave => _p.getInt(AppConstants.prefKeyBestWave) ?? 0;
  int get runs => _p.getInt(AppConstants.prefKeyRuns) ?? 0;

  /// 已解锁的成就 ID。
  Set<String> get unlockedAchievements =>
      (_p.getStringList(AppConstants.prefKeyAchievements) ?? const []).toSet();

  Future<void> saveUnlockedAchievements(Set<String> ids) => _write(
    (p) => p.setStringList(AppConstants.prefKeyAchievements, ids.toList()),
  );

  int get lifetimeKills => _p.getInt(AppConstants.prefKeyLifetimeKills) ?? 0;
  int get lifetimeBossKills =>
      _p.getInt(AppConstants.prefKeyLifetimeBossKills) ?? 0;
  int get bestCombo => _p.getInt(AppConstants.prefKeyBestCombo) ?? 0;

  /// 累计击破与最高连击，挑战模式同样计入。
  Future<void> recordLifetimeStats({
    required int kills,
    required int bossKills,
    required int bestCombo,
  }) async {
    await _write((p) async {
      if (kills > 0) {
        await p.setInt(
          AppConstants.prefKeyLifetimeKills,
          (p.getInt(AppConstants.prefKeyLifetimeKills) ?? 0) + kills,
        );
      }
      if (bossKills > 0) {
        await p.setInt(
          AppConstants.prefKeyLifetimeBossKills,
          (p.getInt(AppConstants.prefKeyLifetimeBossKills) ?? 0) + bossKills,
        );
      }
      if (bestCombo > (p.getInt(AppConstants.prefKeyBestCombo) ?? 0)) {
        await p.setInt(AppConstants.prefKeyBestCombo, bestCombo);
      }
      return true;
    });
  }

  int get challengeRuns => _p.getInt(AppConstants.prefKeyChallengeRuns) ?? 0;
  int get challengeBestEver =>
      _p.getInt(AppConstants.prefKeyChallengeBestEver) ?? 0;
  int get challengeBestStreak =>
      _p.getInt(AppConstants.prefKeyChallengeBestStreak) ?? 0;

  /// 今日挑战进度：跨天后最佳分数与次数归零，连续天数按昨天是否参与计算。
  ChallengeProgress challengeProgressFor(DailyChallenge challenge) {
    final dateKey = challenge.dateKey;
    final storedDate = _p.getString(AppConstants.prefKeyChallengeDate);
    final lastDate = _p.getString(AppConstants.prefKeyChallengeLastDate);
    final storedStreak = _p.getInt(AppConstants.prefKeyChallengeStreak) ?? 0;
    final streak = lastDate == dateKey
        ? storedStreak
        : (lastDate == previousDateKey(dateKey) ? storedStreak : 0);
    if (storedDate != dateKey) {
      return ChallengeProgress(
        dateKey: dateKey,
        bestScore: 0,
        bestWave: 0,
        plays: 0,
        streak: streak,
      );
    }
    return ChallengeProgress(
      dateKey: dateKey,
      bestScore: _p.getInt(AppConstants.prefKeyChallengeBest) ?? 0,
      bestWave: _p.getInt(AppConstants.prefKeyChallengeWave) ?? 0,
      plays: _p.getInt(AppConstants.prefKeyChallengePlays) ?? 0,
      streak: streak,
    );
  }

  /// 记录一次每日挑战：刷新当日最佳、参与次数与连续天数。
  Future<void> recordChallengeRun({
    required String dateKey,
    required int score,
    required int wave,
  }) async {
    await _write((p) async {
      if (p.getString(AppConstants.prefKeyChallengeDate) == dateKey) {
        if (score > (p.getInt(AppConstants.prefKeyChallengeBest) ?? 0)) {
          await p.setInt(AppConstants.prefKeyChallengeBest, score);
        }
        if (wave > (p.getInt(AppConstants.prefKeyChallengeWave) ?? 0)) {
          await p.setInt(AppConstants.prefKeyChallengeWave, wave);
        }
        await p.setInt(
          AppConstants.prefKeyChallengePlays,
          (p.getInt(AppConstants.prefKeyChallengePlays) ?? 0) + 1,
        );
      } else {
        final lastDate = p.getString(AppConstants.prefKeyChallengeLastDate);
        final streak = lastDate == previousDateKey(dateKey)
            ? (p.getInt(AppConstants.prefKeyChallengeStreak) ?? 0) + 1
            : 1;
        await p.setString(AppConstants.prefKeyChallengeDate, dateKey);
        await p.setString(AppConstants.prefKeyChallengeLastDate, dateKey);
        await p.setInt(AppConstants.prefKeyChallengeStreak, streak);
        await p.setInt(
          AppConstants.prefKeyChallengeBestStreak,
          streak > (p.getInt(AppConstants.prefKeyChallengeBestStreak) ?? 0)
              ? streak
              : (p.getInt(AppConstants.prefKeyChallengeBestStreak) ?? 0),
        );
        await p.setInt(AppConstants.prefKeyChallengeBest, score);
        await p.setInt(AppConstants.prefKeyChallengeWave, wave);
        await p.setInt(AppConstants.prefKeyChallengePlays, 1);
      }
      await p.setInt(
        AppConstants.prefKeyChallengeRuns,
        (p.getInt(AppConstants.prefKeyChallengeRuns) ?? 0) + 1,
      );
      if (score > (p.getInt(AppConstants.prefKeyChallengeBestEver) ?? 0)) {
        await p.setInt(AppConstants.prefKeyChallengeBestEver, score);
      }
      return true;
    });
  }

  /// 刷新最高分与最远波次，返回是否刷新了最高分。
  Future<bool> recordRun({required int score, required int wave}) async {
    var record = false;
    await _write((p) async {
      if (score > (p.getInt(AppConstants.prefKeyHighScore) ?? 0)) {
        await p.setInt(AppConstants.prefKeyHighScore, score);
        record = true;
      }
      if (wave > (p.getInt(AppConstants.prefKeyBestWave) ?? 0)) {
        await p.setInt(AppConstants.prefKeyBestWave, wave);
      }
      await p.setInt(
        AppConstants.prefKeyRuns,
        (p.getInt(AppConstants.prefKeyRuns) ?? 0) + 1,
      );
      return true;
    });
    return record;
  }
}
