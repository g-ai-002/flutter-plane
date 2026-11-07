import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sky_fighter/game/logic_rate.dart';
import 'package:sky_fighter/services/storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.resetForTests();
  });

  group('StorageService', () {
    test('默认偏好', () async {
      final storage = await StorageService.instance;
      expect(storage.darkMode, isFalse);
      expect(storage.soundEnabled, isTrue);
      expect(storage.musicEnabled, isTrue);
      expect(storage.hapticsEnabled, isTrue);
      expect(storage.logicRate, LogicRate.hz60);
      expect(storage.highScore, 0);
      expect(storage.bestWave, 0);
      expect(storage.runs, 0);
    });

    test('偏好可读写', () async {
      final storage = await StorageService.instance;
      await storage.setDarkMode(true);
      await storage.setSoundEnabled(false);
      await storage.setMusicEnabled(false);
      await storage.setHapticsEnabled(false);
      await storage.setLogicRate(LogicRate.hz120);

      expect(storage.darkMode, isTrue);
      expect(storage.soundEnabled, isFalse);
      expect(storage.musicEnabled, isFalse);
      expect(storage.hapticsEnabled, isFalse);
      expect(storage.logicRate, LogicRate.hz120);
    });

    test('未识别的速率回退到 60Hz', () async {
      SharedPreferences.setMockInitialValues({'logic_rate': 'turbo'});
      StorageService.resetForTests();
      final storage = await StorageService.instance;
      expect(storage.logicRate, LogicRate.hz60);
    });

    test('记录战绩并刷新最高分', () async {
      final storage = await StorageService.instance;
      final first = await storage.recordRun(score: 1200, wave: 5);
      expect(first, isTrue);
      expect(storage.highScore, 1200);
      expect(storage.bestWave, 5);
      expect(storage.runs, 1);

      final second = await storage.recordRun(score: 800, wave: 3);
      expect(second, isFalse);
      expect(storage.highScore, 1200);
      expect(storage.bestWave, 5);
      expect(storage.runs, 2);

      final third = await storage.recordRun(score: 2400, wave: 7);
      expect(third, isTrue);
      expect(storage.highScore, 2400);
      expect(storage.bestWave, 7);
      expect(storage.runs, 3);
    });
  });
}
