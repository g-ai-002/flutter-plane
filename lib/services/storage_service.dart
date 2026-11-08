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

  int _readInt(String key) => _p.getInt(key) ?? 0;

  /// 递增计数：键不存在时从 0 开始。
  Future<bool> _bump(SharedPreferences p, String key, [int by = 1]) =>
      p.setInt(key, (p.getInt(key) ?? 0) + by);

  /// 只在 [value] 更大的时候写入，返回是否刷新了记录。
  Future<bool> _raise(SharedPreferences p, String key, int value) async {
    if (value <= (p.getInt(key) ?? 0)) return false;
    await p.setInt(key, value);
    return true;
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

  int get highScore => _readInt(AppConstants.prefKeyHighScore);
  int get bestWave => _readInt(AppConstants.prefKeyBestWave);
  int get runs => _readInt(AppConstants.prefKeyRuns);

  /// 已解锁的成就 ID。
  Set<String> get unlockedAchievements =>
      (_p.getStringList(AppConstants.prefKeyAchievements) ?? const []).toSet();

  Future<void> saveUnlockedAchievements(Set<String> ids) => _write(
    (p) => p.setStringList(AppConstants.prefKeyAchievements, ids.toList()),
  );

  int get lifetimeKills => _readInt(AppConstants.prefKeyLifetimeKills);
  int get lifetimeBossKills => _readInt(AppConstants.prefKeyLifetimeBossKills);
  int get bestCombo => _readInt(AppConstants.prefKeyBestCombo);

  /// 累计击破与最高连击，挑战模式同样计入。
  Future<void> recordLifetimeStats({
    required int kills,
    required int bossKills,
    required int bestCombo,
  }) async {
    await _write((p) async {
      if (kills > 0) await _bump(p, AppConstants.prefKeyLifetimeKills, kills);
      if (bossKills > 0) {
        await _bump(p, AppConstants.prefKeyLifetimeBossKills, bossKills);
      }
      await _raise(p, AppConstants.prefKeyBestCombo, bestCombo);
      return true;
    });
  }

  int get challengeRuns => _readInt(AppConstants.prefKeyChallengeRuns);
  int get challengeBestEver => _readInt(AppConstants.prefKeyChallengeBestEver);
  int get challengeBestStreak =>
      _readInt(AppConstants.prefKeyChallengeBestStreak);

  /// 今日挑战进度：跨天后最佳分数与次数归零，连续天数按昨天是否参与计算。
  ChallengeProgress challengeProgressFor(DailyChallenge challenge) {
    final dateKey = challenge.dateKey;
    final storedDate = _p.getString(AppConstants.prefKeyChallengeDate);
    final lastDate = _p.getString(AppConstants.prefKeyChallengeLastDate);
    final storedStreak = _readInt(AppConstants.prefKeyChallengeStreak);
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
      bestScore: _readInt(AppConstants.prefKeyChallengeBest),
      bestWave: _readInt(AppConstants.prefKeyChallengeWave),
      plays: _readInt(AppConstants.prefKeyChallengePlays),
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
      const dateKeyPref = AppConstants.prefKeyChallengeDate;
      if (p.getString(dateKeyPref) == dateKey) {
        await _raise(p, AppConstants.prefKeyChallengeBest, score);
        await _raise(p, AppConstants.prefKeyChallengeWave, wave);
        await _bump(p, AppConstants.prefKeyChallengePlays);
      } else {
        final lastDate = p.getString(AppConstants.prefKeyChallengeLastDate);
        final streak = lastDate == previousDateKey(dateKey)
            ? _readInt(AppConstants.prefKeyChallengeStreak) + 1
            : 1;
        await p.setString(dateKeyPref, dateKey);
        await p.setString(AppConstants.prefKeyChallengeLastDate, dateKey);
        await p.setInt(AppConstants.prefKeyChallengeStreak, streak);
        await _raise(p, AppConstants.prefKeyChallengeBestStreak, streak);
        await p.setInt(AppConstants.prefKeyChallengeBest, score);
        await p.setInt(AppConstants.prefKeyChallengeWave, wave);
        await p.setInt(AppConstants.prefKeyChallengePlays, 1);
      }
      await _bump(p, AppConstants.prefKeyChallengeRuns);
      await _raise(p, AppConstants.prefKeyChallengeBestEver, score);
      return true;
    });
  }

  /// 刷新最高分与最远波次，返回是否刷新了最高分。
  Future<bool> recordRun({required int score, required int wave}) async {
    var record = false;
    await _write((p) async {
      record = await _raise(p, AppConstants.prefKeyHighScore, score);
      await _raise(p, AppConstants.prefKeyBestWave, wave);
      await _bump(p, AppConstants.prefKeyRuns);
      return true;
    });
    return record;
  }
}
