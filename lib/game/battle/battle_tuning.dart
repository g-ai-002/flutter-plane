import 'dart:math' as math;

import 'battle_types.dart';

/// 战场调参表：难度曲线、边界、掉落与战斗节奏集中在这里。
///
/// 逻辑层、HUD 与玩法说明都从同一份数值出发，避免同一个公式在多处各写一遍
/// 后悄悄走样；调整手感时只需要改这一处。

// ---------------------------------------------------------------- 边界与裁剪

/// 玩家战机的可活动范围。
const double kPlayerSideMargin = 16;
const double kPlayerTopLimit = 44;
const double kPlayerBottomMargin = 26;

/// 战机在战场底部的初始高度偏移。
const double kPlayerStartBottomOffset = 84;

/// 窗口缩放后敌机允许的横向范围。
const double kEnemySideMargin = 20;

/// 敌机与 Boss 的出生高度（战场上方）。
const double kEnemySpawnY = -24;
const double kBossSpawnY = -60;

/// 越过战场边界多远后回收实体。
const double kEnemyCullMargin = 60;
const double kPlayerBulletCullMargin = 24;
const double kEnemyBulletCullMargin = 30;
const double kPowerUpCullMargin = 30;

/// 敌机开始与停止开火的纵向区间。
const double kEnemyFireMinY = 6;
const double kEnemyFireMaxRatio = 0.78;

// ---------------------------------------------------------------- 难度曲线

/// 每一波带来的血量与射速修正。
const double kWaveDifficultyStep = 0.09;

/// 第 [wave] 波的敌机强度系数。
double waveDifficulty(int wave) =>
    1 + kWaveDifficultyStep * math.max(0, wave - 1);

/// 后期敌机射速加快的系数：与血量共用同一条难度曲线。
double enemyFireIntervalScale(int wave) => 1 / math.sqrt(waveDifficulty(wave));

// ---------------------------------------------------------------- 玩家火力

/// 火力等级每提升一级缩短的射击间隔。
const double kWeaponFireStepPerLevel = 0.008;

/// 急速射击状态下的射击间隔系数。
const double kRapidFireIntervalScale = 0.62;

/// 当前火力与急速状态下的射击间隔（秒）。
double playerFireInterval(int weaponLevel, {required bool rapid}) {
  final level = math.max(1, weaponLevel);
  final base = kBaseFireInterval - kWeaponFireStepPerLevel * (level - 1);
  return rapid ? base * kRapidFireIntervalScale : base;
}

// ---------------------------------------------------------------- 连击

const int kComboTier2x = 12;
const int kComboTier3x = 30;
const int kComboTier4x = 60;

/// 连击中断的静默时长。
const double kComboWindow = 2.6;

/// 连击数对应的分数倍率。
int comboMultiplier(int combo) {
  if (combo >= kComboTier4x) return 4;
  if (combo >= kComboTier3x) return 3;
  if (combo >= kComboTier2x) return 2;
  return 1;
}

// ---------------------------------------------------------------- 掉落与补给

/// 连续多少架未掉落补给后强制掉落一次。
const int kDropPityLimit = 20;

/// 掉落随机数对应的补给类型，概率顺序与玩法说明一致。
PowerUpKind powerUpKindForRoll(double roll) {
  if (roll < 0.36) return PowerUpKind.weapon;
  if (roll < 0.56) return PowerUpKind.shield;
  if (roll < 0.68) return PowerUpKind.bomb;
  if (roll < 0.79) return PowerUpKind.star;
  if (roll < 0.9) return PowerUpKind.rapid;
  return PowerUpKind.wingman;
}

/// 拾取效果与满级折算分数。
const double kShieldPickupDuration = 10;
const double kRapidPickupDuration = 6;
const double kRapidMaxDuration = 12;
const int kWeaponCapScore = 300;
const int kBombCapScore = 200;
const int kStarPickupScore = 250;
const int kWingmanCapScore = 250;

// ---------------------------------------------------------------- 僚机

/// 僚机相对机身的横向与纵向站位。
const double kWingmanOffsetX = 27;
const double kWingmanOffsetY = 13;

/// 僚机追随玩家的收敛速度（越大越跟手）。
const double kWingmanFollowLerp = 11;

/// 僚机的射击间隔、弹速与伤害。
const double kWingmanFireInterval = 0.36;
const double kWingmanBulletSpeed = 540;
const double kWingmanBulletDamage = 1;

/// 僚机的外张角：左右僚机的弹道略微向两侧展开。
const double kWingmanSpreadAngle = 0.06;

// ---------------------------------------------------------------- 伤害

/// 炸弹对普通敌机与 Boss 的伤害。
const double kBombDamage = 40;
const double kBombBossDamageRatio = 0.16;

/// 与玩家机体相撞时敌机承受的伤害。
const double kRamDamage = 24;
const double kRamBossDamage = 30;

/// 受伤后的无敌时间，以及护盾破碎后的短暂无敌。
const double kHitInvuln = 2;
const double kShieldBreakInvuln = 1.1;

/// 受伤时清除身边敌弹的半径。
const double kHitClearRadius = 100;

/// 每次受伤损失的火力等级。
const int kWeaponLossPerHit = 1;

// ---------------------------------------------------------------- 战斗节奏

/// 开局等待第一波敌机的时间。
const double kFirstWaveGap = 1.2;

/// 一波清空后到下一波的间隔。
const double kBetweenWaveGap = 2.6;

/// 开场操作提示的持续时间，与 HUD 淡出时长保持一致。
const double kBattleHintDuration = 6;

/// HUD 的刷新周期（10Hz）。
const double kHudRefreshInterval = 0.1;

/// 尾焰粒子的生成间隔。
const double kPlayerTrailInterval = 0.05;

/// 射击音效的最小间隔。
const double kShootSoundInterval = 0.12;

/// 敌机受击闪白的持续时间。
const double kEnemyHitFlashDuration = 0.09;
