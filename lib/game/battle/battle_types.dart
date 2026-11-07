import 'dart:math' as math;

/// 战场逻辑宽度：所有尺寸、速度都按这一宽度设计，渲染时整体缩放。
const double kWorldWidth = 400;

/// 玩家移动速度（键盘 / 手柄方向键）。
const double kPlayerSpeed = 300;

/// 玩家弹道速度与基础射击间隔。
const double kPlayerBulletSpeed = 560;
const double kBaseFireInterval = 0.15;

/// 敌机默认下落速度。
const double kEnemyFallSpeed = 58;

/// 战斗阶段。
enum BattlePhase { ready, playing, paused, gameOver }

/// 需要播放音效的战斗事件。
enum BattleEvent {
  shoot,
  explosion,
  bigExplosion,
  powerUp,
  playerHit,
  shieldBreak,
  bomb,
  waveStart,
  bossAppear,
  gameOver,
}

/// 敌机类型。
enum EnemyKind { scout, fighter, bomber, elite, boss }

/// 敌机移动方式。
enum EnemyPattern { straight, sine, dive, hover }

/// 敌机静态参数。
class EnemySpec {
  const EnemySpec({
    required this.hp,
    required this.radius,
    required this.score,
    required this.dropChance,
    this.fireInterval = 2.4,
  });

  final double hp;
  final double radius;
  final int score;
  final double dropChance;
  final double fireInterval;
}

const Map<EnemyKind, EnemySpec> kEnemySpecs = {
  EnemyKind.scout: EnemySpec(hp: 3, radius: 11, score: 60, dropChance: 0.04),
  EnemyKind.fighter: EnemySpec(
    hp: 10,
    radius: 14,
    score: 130,
    dropChance: 0.14,
    fireInterval: 2.1,
  ),
  EnemyKind.bomber: EnemySpec(
    hp: 26,
    radius: 19,
    score: 280,
    dropChance: 0.3,
    fireInterval: 2.5,
  ),
  EnemyKind.elite: EnemySpec(
    hp: 52,
    radius: 24,
    score: 620,
    dropChance: 0.6,
    fireInterval: 2.2,
  ),
  EnemyKind.boss: EnemySpec(
    hp: 180,
    radius: 38,
    score: 2000,
    dropChance: 1,
    fireInterval: 1.9,
  ),
};

/// 玩家战机状态。
class Player {
  Player({required this.x, required this.y});

  double x;
  double y;
  int lives = 3;
  int bombs = 2;
  int weaponLevel = 1;

  /// 护盾剩余时间（秒），大于 0 时可抵挡一次伤害。
  double shield = 0;

  /// 无敌时间（秒），受伤后短暂闪烁。
  double invuln = 0;
  double fireCooldown = 0;

  /// 左右移动带来的机身倾斜，仅用于渲染。
  double tilt = 0;
  bool alive = true;

  static const double radius = 11;
  static const int maxLives = 5;
  static const int maxBombs = 3;
  static const int maxWeaponLevel = 5;
}

/// 敌机实例。
class Enemy {
  Enemy({
    required this.kind,
    required this.pattern,
    required this.x,
    required this.y,
    required this.difficulty,
    this.driftPhase = 0,
  }) : spec = kEnemySpecs[kind]!,
       baseX = x,
       hoverY = 96 + 46 * ((driftPhase * 7) % 1) {
    maxHp = spec.hp * difficulty;
    hp = maxHp;
    vy = kind == EnemyKind.boss
        ? 0
        : kEnemyFallSpeed * (0.85 + 0.3 * driftPhase);
    if (pattern == EnemyPattern.dive) vy *= 1.4;
  }

  final EnemyKind kind;
  final EnemyPattern pattern;
  final EnemySpec spec;
  final double difficulty;
  final double driftPhase;
  final double baseX;
  final double hoverY;

  double x;
  double y;
  double vx = 0;
  double vy = 0;
  late double hp;
  late double maxHp;

  double age = 0;
  double fireCooldown = 0;
  double hitFlash = 0;

  /// Boss 专属：入场完成、当前弹幕阶段与节奏。
  bool entered = false;
  int attackPhase = 0;
  double attackTimer = 1.2;
  double hoverTimer = 0;

  bool dead = false;

  bool get isBoss => kind == EnemyKind.boss;
  double get radius => spec.radius;
  double get hpRatio => maxHp <= 0 ? 0 : (hp / maxHp).clamp(0, 1);
}

/// 子弹：玩家与敌机共用，[kind] 决定渲染样式。
class Bullet {
  Bullet({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.damage,
    required this.fromPlayer,
    this.kind = 0,
  });

  double x;
  double y;
  final double vx;
  final double vy;
  final double radius;
  final double damage;
  final bool fromPlayer;

  /// 0 能量弹、1 瞄准弹、2 散射弹、3 Boss 弹。
  final int kind;
  bool dead = false;
}

/// 补给类型。
enum PowerUpKind { weapon, shield, bomb, star }

const Map<PowerUpKind, String> kPowerUpLabels = {
  PowerUpKind.weapon: '火力',
  PowerUpKind.shield: '护盾',
  PowerUpKind.bomb: '炸弹',
  PowerUpKind.star: '分数',
};

/// 掉落的补给。
class PowerUp {
  PowerUp({required this.x, required this.y, required this.kind});

  double x;
  double y;
  final PowerUpKind kind;
  double age = 0;
  double vy = 62;
  bool dead = false;

  static const double radius = 13;
}

/// 粒子类型。
enum ParticleKind { spark, smoke, ring, debris, trail }

/// 爆炸、尾焰与拾取特效粒子。
class Particle {
  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.size,
    required this.color,
    this.kind = ParticleKind.spark,
    this.drag = 1.6,
  }) : maxLife = life;

  double x;
  double y;
  double vx;
  double vy;
  double life;
  final double maxLife;
  final double size;
  final int color;
  final ParticleKind kind;
  final double drag;

  bool get dead => life <= 0;
  double get progress => maxLife <= 0 ? 1 : 1 - (life / maxLife).clamp(0, 1);
}

/// 飘字：击杀得分与补给提示。
class ScorePopup {
  ScorePopup({
    required this.x,
    required this.y,
    required this.text,
    this.color,
  });

  double x;
  double y;
  final String text;
  final int? color;
  double life = 0.8;

  bool get dead => life <= 0;
}

/// 星空背景的一颗星星。
class Star {
  Star({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.alpha,
  });

  double x;
  double y;
  final double speed;
  final double size;
  final double alpha;
}

/// 敌机开火角度工具：从 [from] 指向 [to] 的单位方向。
math.Point<double> aimDirection(
  double fromX,
  double fromY,
  double toX,
  double toY,
) {
  final dx = toX - fromX;
  final dy = toY - fromY;
  final length = math.sqrt(dx * dx + dy * dy);
  if (length < 0.0001) return const math.Point<double>(0, 1);
  return math.Point<double>(dx / length, dy / length);
}

/// 把角度限制在 [min, max]。
double clampDouble(double value, double min, double max) =>
    value < min ? min : (value > max ? max : value);
