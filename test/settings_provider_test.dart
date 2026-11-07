import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sky_fighter/game/logic_rate.dart';
import 'package:sky_fighter/providers/settings_provider.dart';
import 'package:sky_fighter/services/music_service.dart';
import 'package:sky_fighter/services/sound_service.dart';
import 'package:sky_fighter/services/storage_service.dart';

Future<SettingsProvider> buildSettings() async {
  final storage = await StorageService.instance;
  return SettingsProvider(storage);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    StorageService.resetForTests();
    SoundService.reset();
    MusicService.reset();
  });

  tearDown(() {
    SoundService.reset();
    MusicService.reset();
  });

  test('默认值与偏好同步', () async {
    final settings = await buildSettings();
    expect(settings.darkMode, isFalse);
    expect(settings.soundEnabled, isTrue);
    expect(settings.highScore, 0);

    await settings.setDarkMode(true);
    expect(settings.darkMode, isTrue);
  });

  test('音效开关同步到 SoundService', () async {
    final settings = await buildSettings();
    await settings.setSoundEnabled(false);
    expect(SoundService.soundEnabled, isFalse);

    await settings.setHapticsEnabled(false);
    expect(SoundService.hapticsEnabled, isFalse);

    await settings.setSoundEnabled(true);
    expect(SoundService.soundEnabled, isTrue);
  });

  test('音乐开关交给 MusicService 异步处理', () async {
    final states = <bool>[];
    MusicService.sink = states.add;
    final settings = await buildSettings();
    await settings.setMusicEnabled(false);
    expect(MusicService.enabled, isFalse);
    expect(states, [false]);
  });

  test('记录战绩后通知并返回是否刷新纪录', () async {
    final settings = await buildSettings();
    var notified = 0;
    settings.addListener(() => notified++);

    final record = await settings.recordRun(score: 900, wave: 4);
    expect(record, isTrue);
    expect(settings.highScore, 900);
    expect(settings.bestWave, 4);
    expect(settings.runs, 1);
    expect(notified, 1);

    final again = await settings.recordRun(score: 100, wave: 1);
    expect(again, isFalse);
    expect(settings.highScore, 900);
  });

  test('逻辑刷新率可切换', () async {
    final settings = await buildSettings();
    await settings.setLogicRate(LogicRate.hz30);
    expect(settings.logicRate, LogicRate.hz30);
  });
}
