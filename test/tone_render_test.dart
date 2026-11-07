import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/services/tone_synth.dart';

void main() {
  group('声部渲染', () {
    test('只写入指定区间，不污染相邻样本', () {
      final mix = Float64List(200);
      renderVoice(
        mix: mix,
        offset: 50,
        count: 100,
        sampleRate: 22050,
        frequency: 440,
        sweep: 1,
        decay: 2,
        brightness: 1,
        gain: 0.5,
        noise: 0,
        attackSamples: 1,
        releaseSamples: 0,
        harmonic2: 0.32,
        harmonic3: 0.12,
        random: math.Random(1),
      );
      expect(mix.sublist(0, 50).every((value) => value == 0), isTrue);
      expect(mix.sublist(150).every((value) => value == 0), isTrue);
      expect(mix.sublist(50, 150).any((value) => value != 0), isTrue);
    });

    test('噪声参数改变渲染结果', () {
      final plain = Float64List(200);
      final noisy = Float64List(200);
      void render(Float64List target, double noise) => renderVoice(
        mix: target,
        offset: 0,
        count: 200,
        sampleRate: 22050,
        frequency: 300,
        sweep: 1,
        decay: 1,
        brightness: 1,
        gain: 0.4,
        noise: noise,
        attackSamples: 4,
        releaseSamples: 4,
        harmonic2: 0.3,
        harmonic3: 0.1,
        random: math.Random(7),
      );
      render(plain, 0);
      render(noisy, 0.6);
      expect(noisy, isNot(equals(plain)));
    });
  });
}
