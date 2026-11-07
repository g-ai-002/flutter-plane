import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/services/sound_service.dart';
import 'package:sky_fighter/services/tone_synth.dart';

int _sampleRateOf(Uint8List wav) =>
    ByteData.sublistView(wav, 24, 28).getUint32(0, Endian.little);

int _dataSizeOf(Uint8List wav) =>
    ByteData.sublistView(wav, 40, 44).getUint32(0, Endian.little);

String _tagOf(Uint8List wav, int offset) =>
    String.fromCharCodes(wav.sublist(offset, offset + 4));

void main() {
  group('音效合成', () {
    test('生成合法的 16 位单声道 WAV', () {
      final wav = synthesizeWav(const [
        SynthNote(frequency: 880, start: 0, duration: 0.1),
      ]);
      expect(_tagOf(wav, 0), 'RIFF');
      expect(_tagOf(wav, 8), 'WAVE');
      expect(_tagOf(wav, 36), 'data');
      expect(_sampleRateOf(wav), kSynthSampleRate);
      expect(_dataSizeOf(wav), wav.length - 44);
      final channels = ByteData.sublistView(
        wav,
        22,
        24,
      ).getUint16(0, Endian.little);
      expect(channels, 1);
    });

    test('包含非零采样数据', () {
      final wav = synthesizeWav(const [
        SynthNote(frequency: 440, start: 0, duration: 0.2, gain: 0.8),
      ]);
      final data = ByteData.sublistView(wav, 44);
      var peak = 0;
      for (var i = 0; i < data.lengthInBytes ~/ 2; i++) {
        final sample = data.getInt16(i * 2, Endian.little).abs();
        if (sample > peak) peak = sample;
      }
      expect(peak, greaterThan(3000));
      expect(peak, lessThanOrEqualTo(32767));
    });

    test('滑音与噪声参数被实际使用', () {
      final plain = synthesizeWav(const [
        SynthNote(frequency: 300, start: 0, duration: 0.4),
      ]);
      final sweeps = synthesizeWav(const [
        SynthNote(
          frequency: 300,
          start: 0,
          duration: 0.4,
          sweep: 4,
          noise: 0.8,
        ),
      ]);
      expect(sweeps.length, plain.length);
      expect(sweeps, isNot(equals(plain)));
    });
  });

  group('背景音乐', () {
    test('循环长度固定且首尾淡入淡出', () {
      final wav = synthesizeMusicWav();
      expect(_sampleRateOf(wav), kMusicSampleRate);
      expect(
        _dataSizeOf(wav),
        (kMusicLoopSeconds * kMusicSampleRate).round() * 2,
      );
      final data = ByteData.sublistView(wav, 44);
      expect(data.getInt16(0, Endian.little).abs(), lessThan(64));
      final last = data.getInt16(data.lengthInBytes - 2, Endian.little);
      expect(last.abs(), lessThan(64));
    });

    test('音乐包含低音、琶音与鼓点声部', () {
      final voices = buildMusicVoices();
      expect(voices.length, greaterThan(40));
      expect(voices.any((voice) => voice.noise > 0.5), isTrue);
      expect(voices.any((voice) => voice.frequency < 100), isTrue);
      expect(voices.any((voice) => voice.frequency > 100), isTrue);
      final lastStart = voices
          .map((voice) => voice.start)
          .reduce((a, b) => a > b ? a : b);
      expect(lastStart, lessThan(kMusicLoopSeconds));
    });
  });

  group('音效配方', () {
    test('每种音效都有配方且可合成', () {
      for (final sound in GameSound.values) {
        expect(SoundService.presets.containsKey(sound), isTrue);
        final clip = SoundService.clipOf(sound);
        expect(_tagOf(clip, 0), 'RIFF');
        expect(clip.length, greaterThan(44));
        expect(SoundService.clipOf(sound), same(clip));
      }
    });

    test('射击音效比爆炸短', () {
      expect(
        SoundService.clipOf(GameSound.shoot).length,
        lessThan(SoundService.clipOf(GameSound.bigExplosion).length),
      );
    });
  });
}
