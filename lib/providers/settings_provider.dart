import 'dart:async';

import 'package:flutter/foundation.dart';

import '../game/achievements/achievement.dart';
import '../game/challenge/daily_challenge.dart';
import '../game/logic_rate.dart';
import '../services/music_service.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';

/// 一局战斗的结算结果：是否刷新纪录、今日挑战最佳与新解锁成就。
class RunOutcome {
  const RunOutcome({
    required this.isRecord,
    required this.dailyBest,
    required this.unlocked,
  });

  final bool isRecord;
  final int dailyBest;
  final List<Achievement> unlocked;
}

/// 用户偏好：主题、音效、音乐、震动与逻辑刷新率。
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._storage) {
    _syncFeedback();
  }

  final StorageService _storage;

  bool get darkMode => _storage.darkMode;
  Future<void> setDarkMode(bool value) =>
      _update(() => _storage.setDarkMode(value));

  bool get soundEnabled => _storage.soundEnabled;
  Future<void> setSoundEnabled(bool value) => _update(() async {
    await _storage.setSoundEnabled(value);
    _syncFeedback();
  });

  bool get musicEnabled => _storage.musicEnabled;
  Future<void> setMusicEnabled(bool value) => _update(() async {
    await _storage.setMusicEnabled(value);
    // 音频启停不阻塞开关反馈，加载失败时 MusicService 自行记录日志。
    unawaited(MusicService.setEnabled(value));
  });

  bool get hapticsEnabled => _storage.hapticsEnabled;
  Future<void> setHapticsEnabled(bool value) => _update(() async {
    await _storage.setHapticsEnabled(value);
    _syncFeedback();
  });

  LogicRate get logicRate => _storage.logicRate;
  Future<void> setLogicRate(LogicRate value) =>
      _update(() => _storage.setLogicRate(value));

  int get highScore => _storage.highScore;
  int get bestWave => _storage.bestWave;
  int get runs => _storage.runs;

  int get lifetimeKills => _storage.lifetimeKills;
  int get lifetimeBossKills => _storage.lifetimeBossKills;
  int get bestCombo => _storage.bestCombo;

  Set<String> get unlockedAchievements => _storage.unlockedAchievements;

  int get achievementCount =>
      unlockedAchievementCount(_storage.unlockedAchievements);

  AchievementSnapshot get achievementSnapshot => AchievementSnapshot(
    runs: runs,
    highScore: highScore,
    bestWave: bestWave,
    lifetimeKills: lifetimeKills,
    lifetimeBossKills: lifetimeBossKills,
    bestCombo: bestCombo,
    challengeRuns: _storage.challengeRuns,
    challengeBestStreak: _storage.challengeBestStreak,
    challengeBestEver: _storage.challengeBestEver,
  );

  ChallengeProgress challengeProgress(DailyChallenge challenge) =>
      _storage.challengeProgressFor(challenge);

  /// 记录一次战斗结果，返回是否刷新最高分。
  Future<bool> recordRun({required int score, required int wave}) async {
    final record = await _storage.recordRun(score: score, wave: wave);
    notifyListeners();
    return record;
  }

  /// 战斗结算：写入普通战绩或每日挑战战绩，累计击破数据并判定成就。
  Future<RunOutcome> finishRun({
    required int score,
    required int wave,
    required int kills,
    required int bossKills,
    required int maxCombo,
    DailyChallenge? challenge,
  }) async {
    var record = false;
    var dailyBest = 0;
    if (challenge != null) {
      final before = _storage.challengeProgressFor(challenge);
      await _storage.recordChallengeRun(
        dateKey: challenge.dateKey,
        score: score,
        wave: wave,
      );
      final after = _storage.challengeProgressFor(challenge);
      dailyBest = after.bestScore;
      record = after.bestScore > before.bestScore;
    } else {
      record = await _storage.recordRun(score: score, wave: wave);
    }
    await _storage.recordLifetimeStats(
      kills: kills,
      bossKills: bossKills,
      bestCombo: maxCombo,
    );
    final unlocked = _storage.unlockedAchievements;
    final newlyUnlocked = newlyUnlockedAchievements(
      achievementSnapshot,
      unlocked,
    );
    if (newlyUnlocked.isNotEmpty) {
      await _storage.saveUnlockedAchievements({
        ...unlocked,
        for (final achievement in newlyUnlocked) achievement.id,
      });
    }
    notifyListeners();
    return RunOutcome(
      isRecord: record,
      dailyBest: dailyBest,
      unlocked: newlyUnlocked,
    );
  }

  void _syncFeedback() =>
      SoundService.configure(sound: soundEnabled, haptics: hapticsEnabled);

  /// 写入偏好后统一通知界面，避免每个 setter 重复一遍。
  Future<void> _update(Future<void> Function() write) async {
    await write();
    notifyListeners();
  }
}
