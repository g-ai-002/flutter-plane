import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/game/battle/battle_types.dart';
import 'package:sky_fighter/game/battle/wave_director.dart';

void main() {
  group('WaveDirector', () {
    test('首波在调用前保持待命', () {
      final director = WaveDirector();
      expect(director.wave, 0);
      expect(director.spawning, isFalse);
      expect(director.update(1), isEmpty);
    });

    test('每 4 波为 Boss 波', () {
      final director = WaveDirector(seed: 3);
      for (var i = 1; i <= 12; i++) {
        director.startNextWave();
        expect(director.wave, i);
        expect(director.bossWave, i % 4 == 0);
        while (director.spawning) {
          director.update(10);
        }
      }
    });

    test('生成请求在战场宽度内', () {
      final director = WaveDirector(seed: 11);
      for (var wave = 1; wave <= 10; wave++) {
        director.startNextWave();
        final requests = <SpawnRequest>[];
        while (director.spawning) {
          requests.addAll(director.update(10));
        }
        for (final request in requests) {
          expect(request.x, greaterThanOrEqualTo(34));
          expect(request.x, lessThanOrEqualTo(kWorldWidth - 34));
        }
        if (!director.bossWave) {
          expect(requests, isNotEmpty);
        }
      }
    });

    test('生成按延迟排队，不会同一帧全部出现', () {
      final director = WaveDirector(seed: 5)..startNextWave();
      final first = director.update(0.01);
      expect(first.length, lessThan(2));
      expect(director.spawning, isTrue);
      final rest = <SpawnRequest>[];
      for (var i = 0; i < 200; i++) {
        rest.addAll(director.update(0.1));
      }
      expect(rest, isNotEmpty);
      expect(director.spawning, isFalse);
    });

    test('高波次会加入轰炸机与精英机', () {
      final director = WaveDirector(seed: 9);
      director.startNextWave();
      while (director.spawning) {
        director.update(10);
      }
      for (var i = 0; i < 5; i++) {
        director.startNextWave();
        while (director.spawning) {
          director.update(10);
        }
      }
      director.startNextWave();
      final kinds = <EnemyKind>{};
      while (director.spawning) {
        kinds.addAll(director.update(10).map((request) => request.kind));
      }
      expect(kinds.contains(EnemyKind.elite), isTrue);
      expect(kinds.contains(EnemyKind.bomber), isTrue);
    });
  });
}
