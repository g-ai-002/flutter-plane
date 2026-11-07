import 'dart:math' as math;
import 'dart:typed_data';

/// 音效采样率：射击、爆炸这类短促提示音用 22.05 kHz 足够，数据量约为 44.1 kHz 的一半。
const int kSynthSampleRate = 22050;

/// 单枚乐音：正弦基频叠加二、三次谐波，可混入噪声并做频率滑移。
class SynthNote {
  const SynthNote({
    required this.frequency,
    required this.start,
    required this.duration,
    this.gain = 0.5,
    this.noise = 0,
    this.sweep = 1,
    this.decay = 3.2,
    this.brightness = 1,
  });

  /// 基频（Hz）。
  final double frequency;

  /// 相对整段音效的起始时间（秒）。
  final double start;

  /// 持续时长（秒）。
  final double duration;

  /// 音量，0 到 1。
  final double gain;

  /// 混入的噪声比例，用于表现爆炸、撞击。
  final double noise;

  /// 频率滑移倍数：结束时基频为 `frequency * sweep`。
  final double sweep;

  /// 指数衰减速度，越大衰减越快。
  final double decay;

  /// 谐波强度，1 为默认，越大越明亮。
  final double brightness;
}

/// 纯 Dart 音效合成：把若干乐音渲染成 16 位单声道 WAV 字节。
///
/// 音效全部在运行时生成，代码仓库与安装包都不携带音频文件。
Uint8List synthesizeWav(
  List<SynthNote> notes, {
  int sampleRate = kSynthSampleRate,
  double tailSeconds = 0.04,
}) {
  final seconds = notes.fold<double>(
    0,
    (longest, note) => math.max(longest, note.start + note.duration),
  );
  final totalSamples = ((seconds + tailSeconds) * sampleRate).round();
  final mix = Float64List(totalSamples);
  final random = math.Random(20261107);

  for (final note in notes) {
    final offset = (note.start * sampleRate).round();
    final count = (note.duration * sampleRate).round();
    if (count <= 0) continue;
    final attack = math.max(1, (0.0025 * sampleRate).round());
    final release = math.max(1, (0.005 * sampleRate).round());
    final gain = note.gain / 1.44;
    var phase = 0.0;
    for (var i = 0; i < count; i++) {
      final index = offset + i;
      if (index >= totalSamples) break;
      final progress = i / count;
      final envelope =
          math.min(1, i / attack) *
          math.min(1, (count - i) / release) *
          math.exp(-note.decay * progress);
      final frequency = note.frequency * (1 + (note.sweep - 1) * progress);
      phase += 2 * math.pi * frequency / sampleRate;
      final tone =
          math.sin(phase) +
          (0.32 * note.brightness) * math.sin(2 * phase) +
          (0.12 * note.brightness) * math.sin(3 * phase);
      final hit = note.noise * (random.nextDouble() * 2 - 1);
      mix[index] += envelope * (tone * gain + hit);
    }
  }

  return encodePcmWav(mix, sampleRate);
}

/// 背景音乐采样率与循环长度：强节奏电子循环，8 秒一循环。
const int kMusicSampleRate = 16000;
const double kMusicLoopSeconds = 8;

class MusicVoice {
  const MusicVoice({
    required this.start,
    required this.frequency,
    required this.duration,
    this.gain = 0.4,
    this.sweep = 1,
    this.decay = 2,
    this.noise = 0,
    this.brightness = 1,
  });

  final double start;
  final double frequency;
  final double duration;
  final double gain;
  final double sweep;
  final double decay;
  final double noise;
  final double brightness;
}

/// 强节奏循环配方：A 小调五声音阶，140 BPM，低音铺底 + 琶音 + 底鼓与踩镲。
List<MusicVoice> buildMusicVoices() {
  final voices = <MusicVoice>[];
  const beat = 60 / 140;
  const roots = [55.0, 43.65, 65.41, 49.0];
  const scale = [220.0, 261.63, 293.66, 329.63, 392.0, 440.0];
  const arpPattern = [0, 2, 4, 2, 3, 5, 4, 2, 1, 3, 5, 3, 2, 4, 3, 1];

  // 低音：每两拍一个根音，带八度跳进。
  for (var bar = 0; bar < 4; bar++) {
    final root = roots[bar];
    for (var beatIndex = 0; beatIndex < 4; beatIndex++) {
      final start = (bar * 4 + beatIndex) * beat;
      voices.add(
        MusicVoice(
          start: start,
          frequency: beatIndex.isEven ? root : root * 2,
          duration: beat * 0.9,
          gain: 0.30,
          decay: 1.4,
          brightness: 0.6,
        ),
      );
    }
  }

  // 主琶音：八分音符，音高在五声音阶内循环。
  for (var i = 0; i < 32; i++) {
    final start = i * beat / 2;
    final octave = i % 8 >= 4 ? 2 : 1;
    voices.add(
      MusicVoice(
        start: start,
        frequency: scale[arpPattern[i % arpPattern.length]] * octave,
        duration: beat * 0.46,
        gain: 0.16,
        decay: 2.6,
        brightness: 1.1,
      ),
    );
  }

  // 底鼓与踩镲：噪声短促，撑起节奏。
  for (var i = 0; i < 16; i++) {
    voices.add(
      MusicVoice(
        start: i * beat,
        frequency: 52,
        duration: 0.16,
        gain: 0.34,
        sweep: 0.55,
        decay: 4.2,
        noise: 0.18,
      ),
    );
  }
  for (var i = 0; i < 32; i++) {
    voices.add(
      MusicVoice(
        start: i * beat / 2 + beat / 4,
        frequency: 7200,
        duration: 0.035,
        gain: 0.075,
        decay: 6,
        noise: 0.9,
        brightness: 0.2,
      ),
    );
  }
  return voices;
}

/// 合成背景音乐：首尾淡入淡出后无缝循环。
Uint8List synthesizeMusicWav({int sampleRate = kMusicSampleRate}) {
  final voices = buildMusicVoices();
  final totalSamples = (kMusicLoopSeconds * sampleRate).round();
  final mix = Float64List(totalSamples);
  final random = math.Random(20261108);

  for (final voice in voices) {
    final offset = (voice.start * sampleRate).round();
    final count = math.min(
      (voice.duration * sampleRate).round(),
      totalSamples - offset,
    );
    if (count <= 0) continue;
    final attack = math.max(1, (0.004 * sampleRate).round());
    var phase = 0.0;
    for (var i = 0; i < count; i++) {
      final progress = i / count;
      final envelope =
          math.min(1, i / attack) * math.exp(-voice.decay * progress);
      final frequency = voice.frequency * (1 + (voice.sweep - 1) * progress);
      phase += 2 * math.pi * frequency / sampleRate;
      final tone =
          math.sin(phase) +
          (0.3 * voice.brightness) * math.sin(2 * phase) +
          (0.1 * voice.brightness) * math.sin(3 * phase);
      final hit = voice.noise * (random.nextDouble() * 2 - 1);
      mix[offset + i] += envelope * voice.gain * (tone * 0.42 + hit);
    }
  }

  var peak = 0.0;
  for (final value in mix) {
    final magnitude = value.abs();
    if (magnitude > peak) peak = magnitude;
  }
  final scale = peak > 0 ? 0.78 / peak : 1.0;
  final edge = (0.02 * sampleRate).round();
  for (var i = 0; i < totalSamples; i++) {
    final fadeIn = i < edge ? i / edge : 1.0;
    final fadeOut = i >= totalSamples - edge ? (totalSamples - i) / edge : 1.0;
    mix[i] *= scale * fadeIn * fadeOut;
  }
  return encodePcmWav(mix, sampleRate);
}

/// 把 [-1,1] 的浮点混音编码为 16 位单声道 WAV。
Uint8List encodePcmWav(Float64List mix, int sampleRate) {
  final totalSamples = mix.length;
  final data = ByteData(44 + totalSamples * 2);
  _writeAscii(data, 0, 'RIFF');
  data.setUint32(4, 36 + totalSamples * 2, Endian.little);
  _writeAscii(data, 8, 'WAVE');
  _writeAscii(data, 12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  _writeAscii(data, 36, 'data');
  data.setUint32(40, totalSamples * 2, Endian.little);

  for (var i = 0; i < totalSamples; i++) {
    final sample = (mix[i].clamp(-1.0, 1.0) * 32767).round();
    data.setInt16(44 + i * 2, sample, Endian.little);
  }
  return data.buffer.asUint8List();
}

void _writeAscii(ByteData data, int offset, String text) {
  for (var i = 0; i < text.length; i++) {
    data.setUint8(offset + i, text.codeUnitAt(i));
  }
}
