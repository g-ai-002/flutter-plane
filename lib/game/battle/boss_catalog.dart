import 'dart:math' as math;

import 'battle_types.dart';

/// Boss 登场节奏、形态轮换与命名。
///
/// 波次调度与战斗控制器都从这里取形态，避免两边各自维护一套 `wave ~/ 4`
/// 的索引计算。
const int kBossWaveInterval = 4;

/// 三种形态按顺序轮换：赤蝎母舰 → 深渊利维坦 → 幽影方舟。
const List<BossVariant> kBossRotation = [
  BossVariant.scorpion,
  BossVariant.leviathan,
  BossVariant.wraith,
];

const Map<BossVariant, List<String>> kBossNames = {
  BossVariant.scorpion: ['赤蝎母舰', '雷霆要塞', '虚空旗舰'],
  BossVariant.leviathan: ['深渊利维坦', '终焉之核', '混沌母巢'],
  BossVariant.wraith: ['幽影方舟', '寂灭守望', '蚀界之瞳'],
};

/// Boss 序号：首场 Boss 为 0，之后每 4 波递增。
int bossIndexForWave(int wave) => math.max(0, wave ~/ kBossWaveInterval - 1);

/// 第 [wave] 波的 Boss 形态，三种形态依次轮换。
BossVariant bossVariantForWave(int wave) =>
    kBossRotation[bossIndexForWave(wave) % kBossRotation.length];

/// 第 [wave] 波的 Boss 名称；尚未进入 Boss 波时返回空串。
String bossNameForWave(int wave) {
  if (wave < kBossWaveInterval) return '';
  final index = bossIndexForWave(wave);
  final names = kBossNames[bossVariantForWave(wave)]!;
  return names[(index ~/ kBossRotation.length) % names.length];
}

/// Boss 弹幕节奏：后期略微加快，但不低于 1.1 秒。
double bossBarrageInterval(int wave) => math.max(1.1, 2.1 - wave * 0.05);

/// Boss 弹幕基础速度：随波次提升，16 波后封顶。
double bossBarrageSpeed(int wave) => 158 + math.min(50, wave * 3);
