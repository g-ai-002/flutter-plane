import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sky_fighter/game/battle/battle_controller.dart';
import 'package:sky_fighter/game/battle/battle_types.dart';
import 'package:sky_fighter/game/challenge/daily_challenge.dart';
import 'package:sky_fighter/services/storage_service.dart';

DailyChallenge buildChallenge(DateTime date, {ChallengeModifier? modifier}) {
  final challenge = DailyChallenge.forDate(date);
  if (modifier == null) return challenge;
  return DailyChallenge(
    dateKey: challenge.dateKey,
    seed: challenge.seed,
    modifier: modifier,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.resetForTests();
  });

  group('每日挑战配置', () {
    test('同一天得到相同种子与修正', () {
      final first = DailyChallenge.forDate(DateTime(2026, 11, 8));
      final second = DailyChallenge.forDate(DateTime(2026, 11, 8, 23, 59));
      expect(first.dateKey, '20261108');
      expect(second.dateKey, first.dateKey);
      expect(second.seed, first.seed);
      expect(second.modifier, first.modifier);
    });

    test('修正规则按天轮换，五天覆盖全部规则', () {
      final modifiers = {
        for (var i = 0; i < 5; i++)
          DailyChallenge.forDate(DateTime(2026, 11, 8 + i)).modifier,
      };
      expect(modifiers, DailyChallenge.rotation.toSet());
      final repeat = DailyChallenge.forDate(DateTime(2026, 11, 13));
      expect(
        repeat.modifier,
        DailyChallenge.forDate(DateTime(2026, 11, 8)).modifier,
      );
    });

    test('日期文案包含月日与星期', () {
      final challenge = DailyChallenge.forDate(DateTime(2026, 11, 8));
      expect(challenge.dateLabel, '11月8日 周日');
    });

    test('日期键可解析回本地日期', () {
      expect(parseDateKey('20261108'), DateTime(2026, 11, 8));
      expect(parseDateKey('20260101'), DateTime(2026));
    });

    test('前一天跨月与跨年', () {
      expect(previousDateKey('20261101'), '20261031');
      expect(previousDateKey('20260101'), '20251231');
      expect(previousDateKey('20260301'), '20260228');
    });

    test('挑战修正会改变初始生命与火力', () {
      final controller = BattleController(
        size: const Size(400, 700),
        challenge: buildChallenge(
          DateTime(2026, 11, 8),
          modifier: ChallengeModifier.ace,
        ),
      );
      addTearDown(controller.dispose);
      controller.start();
      expect(controller.player.lives, 2);

      final armed = BattleController(
        size: const Size(400, 700),
        challenge: buildChallenge(
          DateTime(2026, 11, 8),
          modifier: ChallengeModifier.arsenal,
        ),
      );
      addTearDown(armed.dispose);
      armed.start();
      expect(armed.player.weaponLevel, 3);
    });

    test('挑战修正放大击破得分', () {
      final controller = BattleController(
        size: const Size(400, 700),
        challenge: buildChallenge(
          DateTime(2026, 11, 8),
          modifier: ChallengeModifier.ace,
        ),
      );
      addTearDown(controller.dispose);
      controller.start();
      final enemy = Enemy(
        kind: EnemyKind.scout,
        pattern: EnemyPattern.straight,
        x: 200,
        y: 120,
        difficulty: 1,
      );
      controller.enemies.add(enemy);
      controller.playerBullets.add(
        Bullet(
          x: 200,
          y: 128,
          vx: 0,
          vy: -500,
          radius: 3.4,
          damage: 10,
          fromPlayer: true,
        ),
      );
      controller.update(1 / 60);
      expect(enemy.dead, isTrue);
      expect(controller.score, 78);
    });
  });

  group('每日挑战进度', () {
    test('首次挑战记录今日最佳与连续天数', () async {
      final challenge = DailyChallenge.forDate(DateTime(2026, 11, 8));
      final storage = await StorageService.instance;
      expect(storage.challengeProgressFor(challenge).playedToday, isFalse);

      await storage.recordChallengeRun(
        dateKey: challenge.dateKey,
        score: 800,
        wave: 3,
      );
      var progress = storage.challengeProgressFor(challenge);
      expect(progress.bestScore, 800);
      expect(progress.bestWave, 3);
      expect(progress.plays, 1);
      expect(progress.streak, 1);
      expect(progress.playedToday, isTrue);

      await storage.recordChallengeRun(
        dateKey: challenge.dateKey,
        score: 1200,
        wave: 5,
      );
      progress = storage.challengeProgressFor(challenge);
      expect(progress.bestScore, 1200);
      expect(progress.bestWave, 5);
      expect(progress.plays, 2);
      expect(storage.challengeBestEver, 1200);
      expect(storage.challengeRuns, 2);
    });

    test('连续参与累计天数，中断后重新计数', () async {
      final storage = await StorageService.instance;
      final first = DailyChallenge.forDate(DateTime(2026, 11, 8));
      final second = DailyChallenge.forDate(DateTime(2026, 11, 9));
      final skipped = DailyChallenge.forDate(DateTime(2026, 11, 11));

      await storage.recordChallengeRun(
        dateKey: first.dateKey,
        score: 100,
        wave: 1,
      );
      await storage.recordChallengeRun(
        dateKey: second.dateKey,
        score: 200,
        wave: 2,
      );
      expect(storage.challengeProgressFor(second).streak, 2);
      expect(storage.challengeBestStreak, 2);

      final gap = storage.challengeProgressFor(skipped);
      expect(gap.streak, 0);
      expect(gap.bestScore, 0);

      await storage.recordChallengeRun(
        dateKey: skipped.dateKey,
        score: 300,
        wave: 3,
      );
      expect(storage.challengeProgressFor(skipped).streak, 1);
      expect(storage.challengeBestStreak, 2);
    });
  });
}
