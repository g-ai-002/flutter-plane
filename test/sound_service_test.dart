import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/services/music_service.dart';
import 'package:sky_fighter/services/sound_service.dart';

void main() {
  setUp(() {
    SoundService.reset();
    MusicService.reset();
  });

  tearDown(() {
    SoundService.reset();
    MusicService.reset();
  });

  group('SoundService', () {
    test('开启音效时把反馈交给出口', () {
      final played = <GameSound>[];
      SoundService.sink = played.add;
      SoundService.configure(sound: true, haptics: false);

      SoundService.play(GameSound.shoot);
      SoundService.play(GameSound.explosion);

      expect(played, [GameSound.shoot, GameSound.explosion]);
    });

    test('关闭音效后不再播放', () {
      final played = <GameSound>[];
      SoundService.sink = played.add;
      SoundService.configure(sound: false, haptics: false);

      SoundService.play(GameSound.bomb);

      expect(played, isEmpty);
    });

    test('重置恢复默认开关', () {
      SoundService.configure(sound: false, haptics: false);
      SoundService.reset();
      expect(SoundService.soundEnabled, isTrue);
      expect(SoundService.hapticsEnabled, isTrue);
      expect(SoundService.sink, isNull);
    });
  });

  group('MusicService', () {
    test('默认开启时启动播放', () async {
      final states = <bool>[];
      MusicService.sink = states.add;

      await MusicService.start();
      expect(states, [true]);

      await MusicService.setEnabled(false);
      expect(states.last, isFalse);
      expect(MusicService.enabled, isFalse);
    });

    test('关闭状态下不启动播放', () async {
      final states = <bool>[];
      MusicService.sink = states.add;
      await MusicService.setEnabled(false);
      states.clear();

      await MusicService.start();
      expect(states, isEmpty);
    });

    test('重新开启后恢复播放', () async {
      final states = <bool>[];
      MusicService.sink = states.add;
      await MusicService.setEnabled(false);
      await MusicService.setEnabled(true);
      expect(states, [false, true]);
      expect(MusicService.enabled, isTrue);
    });

    test('重置清空状态', () async {
      MusicService.sink = (_) {};
      await MusicService.setEnabled(false);
      MusicService.reset();
      expect(MusicService.enabled, isTrue);
      expect(MusicService.sink, isNull);
    });
  });
}
