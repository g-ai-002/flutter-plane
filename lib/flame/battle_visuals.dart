import 'dart:ui';

import '../game/battle/battle_types.dart';

/// 敌机矢量外观：机体、描边、核心颜色与轮廓路径都按类型集中声明。
///
/// 渲染层只按 [EnemyKind] 查表，不再在每个绘制分支里重复 switch，
/// 新增敌机类型时只需补充一条视觉配置。
class EnemyVisual {
  const EnemyVisual({
    required this.hull,
    required this.trim,
    required this.core,
    required this.coreRadius,
    required this.path,
    this.coreOffsetY = 0,
    this.strokeWidth = 1.4,
  });

  final Color hull;
  final Color trim;
  final Color core;
  final double coreRadius;
  final double coreOffsetY;
  final double strokeWidth;
  final Path path;
}

final Path playerHullPath = Path()
  ..moveTo(0, -17)
  ..lineTo(4.5, -6)
  ..lineTo(14, 3)
  ..lineTo(14, 8.5)
  ..lineTo(5, 7)
  ..lineTo(3.2, 12)
  ..lineTo(-3.2, 12)
  ..lineTo(-5, 7)
  ..lineTo(-14, 8.5)
  ..lineTo(-14, 3)
  ..lineTo(-4.5, -6)
  ..close();

final Path bossHullPath = Path()
  ..moveTo(0, 38)
  ..lineTo(-15, 27)
  ..lineTo(-37, 19)
  ..lineTo(-46, 3)
  ..lineTo(-30, -5)
  ..lineTo(-38, -22)
  ..lineTo(-12, -14)
  ..lineTo(0, -27)
  ..lineTo(12, -14)
  ..lineTo(38, -22)
  ..lineTo(30, -5)
  ..lineTo(46, 3)
  ..lineTo(37, 19)
  ..lineTo(15, 27)
  ..close();

final Map<EnemyKind, EnemyVisual> kEnemyVisuals = {
  EnemyKind.scout: EnemyVisual(
    hull: const Color(0xFF6E2431),
    trim: const Color(0xFFFF9E6B),
    core: const Color(0xFFFFD166),
    coreRadius: 3.2,
    path: Path()
      ..moveTo(0, 12)
      ..lineTo(-11, -3)
      ..lineTo(-4, -7)
      ..lineTo(0, -3)
      ..lineTo(4, -7)
      ..lineTo(11, -3)
      ..close(),
  ),
  EnemyKind.fighter: EnemyVisual(
    hull: const Color(0xFF7C2A33),
    trim: const Color(0xFFFF7A59),
    core: const Color(0xFFFFB347),
    coreRadius: 3.2,
    path: Path()
      ..moveTo(0, 15)
      ..lineTo(-6, 3)
      ..lineTo(-16, -3)
      ..lineTo(-9, -9)
      ..lineTo(0, -5)
      ..lineTo(9, -9)
      ..lineTo(16, -3)
      ..lineTo(6, 3)
      ..close(),
  ),
  EnemyKind.bomber: EnemyVisual(
    hull: const Color(0xFF5E1F3A),
    trim: const Color(0xFFFF6B8B),
    core: const Color(0xFFFF8A80),
    coreRadius: 3.2,
    path: Path()
      ..moveTo(0, 20)
      ..lineTo(-10, 10)
      ..lineTo(-20, 3)
      ..lineTo(-14, -8)
      ..lineTo(0, -12)
      ..lineTo(14, -8)
      ..lineTo(20, 3)
      ..lineTo(10, 10)
      ..close(),
  ),
  EnemyKind.elite: EnemyVisual(
    hull: const Color(0xFF5A1B4C),
    trim: const Color(0xFFFF6BC4),
    core: const Color(0xFFFF8FD1),
    coreRadius: 5.5,
    coreOffsetY: 2,
    strokeWidth: 2,
    path: Path()
      ..moveTo(0, 25)
      ..lineTo(-9, 11)
      ..lineTo(-23, 4)
      ..lineTo(-16, -7)
      ..lineTo(-20, -16)
      ..lineTo(0, -11)
      ..lineTo(20, -16)
      ..lineTo(16, -7)
      ..lineTo(23, 4)
      ..lineTo(9, 11)
      ..close(),
  ),
  EnemyKind.boss: EnemyVisual(
    hull: const Color(0xFF3A1F4F),
    trim: const Color(0xFFFF6B9D),
    core: const Color(0xFFFFD54F),
    coreRadius: 9,
    strokeWidth: 2.2,
    path: bossHullPath,
  ),
};

const Color kPlayerHull = Color(0xFF2FA8FF);
const Color kPlayerHullShadow = Color(0xFF10306B);
const Color kPlayerTrim = Color(0xFF9BE8FF);
const Color kPlayerBulletGlow = Color(0xFF4FD1FF);
const Color kPlayerBulletBody = Color(0xFFB7F4FF);
const Color kEnemyEngineGlow = Color(0xFFFF8A5C);
const Color kBossCoreGlow = Color(0xFFFFD54F);
const Color kBossTurret = Color(0xFF6B2E63);
const Color kBossTrim = Color(0xFFFF8FB8);

const Map<int, Color> kEnemyBulletColors = {
  BulletKind.aimed: Color(0xFFFF9E6B),
  BulletKind.spread: Color(0xFFFF6BC4),
  BulletKind.boss: Color(0xFFFFD54F),
};

const Map<PowerUpKind, Color> kPowerUpColors = {
  PowerUpKind.weapon: Color(0xFFFFB347),
  PowerUpKind.shield: Color(0xFF7FD8FF),
  PowerUpKind.bomb: Color(0xFFFF6B6B),
  PowerUpKind.star: Color(0xFFFFD54F),
};
