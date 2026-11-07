import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'battle_collision.dart';
import 'battle_effects.dart';
import 'battle_types.dart';
import 'enemy_motion.dart';
import 'enemy_weapons.dart';
import 'player_weapon.dart';
import 'wave_director.dart';

/// 战斗控制器：纯逻辑的弹幕战场，负责玩家、敌机、弹道、碰撞、波次与计分。
///
/// 渲染层按世界坐标（宽度固定 [kWorldWidth]）缩放绘制，界面层只读取状态，
/// 因此同一套逻辑可以在 Android、Windows 与 Web 上保持一致，并可直接单测。
/// 具体职责拆到 [BattleEffects]（特效）、[WaveDirector]（波次）、
/// `player_weapon` / `enemy_weapons`（弹道）与 `battle_collision`（碰撞）。
class BattleController extends ChangeNotifier {
  BattleController({
    required Size size,
    int seed = 20261107,
    this._highScore = 0,
  }) : _size = size,
       _seed = seed,
       _rng = math.Random(seed),
       _starRng = math.Random(seed ^ 0x5F3759DF),
       _director = WaveDirector(seed: seed) {
    _effects = BattleEffects(_rng, _starRng);
    player = Player(x: size.width / 2, y: size.height - 84);
    _effects.resetStars(_size);
  }

  static const Map<BossVariant, List<String>> _bossNames = {
    BossVariant.scorpion: ['赤蝎母舰', '雷霆要塞', '虚空旗舰'],
    BossVariant.leviathan: ['深渊利维坦', '终焉之核', '混沌母巢'],
  };

  /// 开场操作提示的持续时间，与 HUD 的淡出时长保持一致。
  static const double hintDuration = 6;

  final int _seed;
  final math.Random _rng;
  final math.Random _starRng;
  late final BattleEffects _effects;
  WaveDirector _director;

  late Player player;
  final List<Enemy> enemies = [];
  final List<Bullet> playerBullets = [];
  final List<Bullet> enemyBullets = [];
  final List<PowerUp> powerUps = [];

  List<Particle> get particles => _effects.particles;
  List<ScorePopup> get popups => _effects.popups;
  List<Star> get stars => _effects.stars;

  final List<BattleEvent> _events = [];
  Offset _moveAxis = Offset.zero;
  Size _size;
  int _highScore;
  int _runs = 0;
  double _gapTimer = 1.4;
  double _hudTimer = 0;
  int _lastHudSignature = 0;
  double _trailTimer = 0;
  double _shootCooldown = 0;
  int _dropPity = 0;

  BattlePhase phase = BattlePhase.ready;
  int score = 0;
  int wave = 0;
  int kills = 0;
  int combo = 0;
  double comboTimer = 0;
  double shake = 0;
  double flash = 0;
  double elapsed = 0;
  Duration survived = Duration.zero;

  Size get size => _size;

  int get highScore => _highScore;

  BossVariant get bossVariant {
    final index = wave <= 0 ? 0 : wave ~/ 4 - 1;
    return index.isOdd ? BossVariant.leviathan : BossVariant.scorpion;
  }

  String get bossName {
    if (wave <= 0) return '';
    final index = wave ~/ 4 - 1;
    final variant = index.isOdd ? BossVariant.leviathan : BossVariant.scorpion;
    final names = _bossNames[variant]!;
    return names[(index ~/ 2) % names.length];
  }

  int get multiplier {
    if (combo >= 60) return 4;
    if (combo >= 30) return 3;
    if (combo >= 12) return 2;
    return 1;
  }

  Enemy? get boss {
    for (final enemy in enemies) {
      if (enemy.isBoss && !enemy.dead) return enemy;
    }
    return null;
  }

  double get bossHpRatio => boss?.hpRatio ?? 0;

  String get waveLabel {
    if (wave <= 0) return '待命';
    if (_director.bossWave) return 'BOSS 波';
    return '第 $wave 波';
  }

  /// 开始新一轮战斗，清空全部战场状态。
  void start() {
    _runs++;
    _director = WaveDirector(seed: _seed + _runs * 7919);
    player = Player(x: _size.width / 2, y: _size.height - 84);
    enemies.clear();
    playerBullets.clear();
    enemyBullets.clear();
    powerUps.clear();
    _effects.clear();
    _events.clear();
    score = 0;
    wave = 0;
    kills = 0;
    combo = 0;
    comboTimer = 0;
    shake = 0;
    flash = 0;
    elapsed = 0;
    survived = Duration.zero;
    _gapTimer = 1.2;
    _hudTimer = 0;
    _lastHudSignature = 0;
    _trailTimer = 0;
    _shootCooldown = 0;
    _dropPity = 0;
    _moveAxis = Offset.zero;
    _effects.resetStars(_size);
    phase = BattlePhase.playing;
    notifyListeners();
  }

  void pause() {
    if (phase != BattlePhase.playing) return;
    phase = BattlePhase.paused;
    notifyListeners();
  }

  void resume() {
    if (phase != BattlePhase.paused) return;
    phase = BattlePhase.playing;
    notifyListeners();
  }

  void setHighScore(int value) {
    if (value == _highScore) return;
    _highScore = value;
    notifyListeners();
  }

  /// 键盘方向轴：长度不超过 1 的向量。
  void setMoveAxis(Offset axis) {
    final length = axis.distance;
    _moveAxis = length > 1 ? axis / length : axis;
  }

  /// 指针拖动：按手指位移平移战机，越界自动收拢。
  void movePlayerBy(Offset delta) {
    if (phase != BattlePhase.playing || !player.alive) return;
    player.x = clampDouble(player.x + delta.dx, 16, _size.width - 16);
    player.y = clampDouble(player.y + delta.dy, 44, _size.height - 26);
    player.tilt = clampDouble(player.tilt + delta.dx * 0.03, -1, 1);
  }

  /// 使用炸弹：清空敌弹并对全场敌机造成伤害。
  void useBomb() {
    if (phase != BattlePhase.playing || !player.alive || player.bombs <= 0) {
      return;
    }
    player.bombs--;
    flash = 0.62;
    shake = math.max(shake, 16);
    _emit(BattleEvent.bomb);
    for (final bullet in enemyBullets) {
      _effects.burst(
        Offset(bullet.x, bullet.y),
        count: 1,
        color: 0xFF8BE9FD,
        speed: 60,
        size: 2.2,
        life: 0.3,
      );
    }
    enemyBullets.clear();
    for (final enemy in enemies) {
      if (enemy.dead) continue;
      final damage = enemy.isBoss ? enemy.maxHp * 0.16 : 40.0;
      _damageEnemy(enemy, damage);
    }
    _effects.addPopup(
      ScorePopup(x: _size.width / 2, y: _size.height * 0.55, text: '全屏轰炸'),
    );
    notifyListeners();
  }

  void resize(Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final scaleX = size.width / _size.width;
    _size = size;
    player.x = clampDouble(player.x * scaleX, 16, size.width - 16);
    player.y = clampDouble(player.y, 44, size.height - 26);
    for (final enemy in enemies) {
      enemy.x = clampDouble(enemy.x, 20, size.width - 20);
    }
    _effects.resetStars(_size);
    notifyListeners();
  }

  /// 本步累积的事件（不复制），渲染层消费后调用 [clearEvents]。
  List<BattleEvent> get pendingEvents => _events;

  void clearEvents() => _events.clear();

  void update(double dt) {
    if (dt <= 0) return;
    if (phase == BattlePhase.gameOver || phase == BattlePhase.ready) {
      _updateEffects(dt);
      return;
    }
    if (phase != BattlePhase.playing) return;

    elapsed += dt;
    _effects.updateStars(dt, _size);
    _updatePlayer(dt);
    _updateWaves(dt);
    _updateEnemies(dt);
    _updateBullets(dt);
    _updatePowerUps(dt);
    _collide(dt);
    _updateEffects(dt);

    if (comboTimer > 0) {
      comboTimer -= dt;
      if (comboTimer <= 0) combo = 0;
    }
    _shootCooldown = math.max(0, _shootCooldown - dt);
    shake = shake < 0.05 ? 0 : shake * math.exp(-5.2 * dt);
    flash = math.max(0, flash - 2.4 * dt);
    _hudTimer += dt;
    if (_hudTimer < 0.1) return;
    _hudTimer = 0;
    // 开场提示需要连续淡出、Boss 血条会随命中变化，这两种情况保持 10Hz 刷新；
    // 其余时间只在 HUD 可见数值真的变化时才通知，避免整棵界面空转重建。
    final signature = _hudSignature();
    if (elapsed >= hintDuration &&
        boss == null &&
        signature == _lastHudSignature) {
      return;
    }
    _lastHudSignature = signature;
    notifyListeners();
  }

  /// HUD 上可见数值的指纹，用于跳过没有变化的刷新。
  int _hudSignature() => Object.hash(
    score,
    wave,
    player.lives,
    player.bombs,
    player.weaponLevel,
    player.rapid > 0 ? player.rapid.ceil() : 0,
    combo,
    multiplier,
    phase,
  );

  // ---------------------------------------------------------------- 玩家

  void _updatePlayer(double dt) {
    final p = player;
    if (!p.alive) return;
    p.invuln = math.max(0, p.invuln - dt);
    p.shield = math.max(0, p.shield - dt);
    p.rapid = math.max(0, p.rapid - dt);
    if (_moveAxis != Offset.zero) {
      p.x = clampDouble(
        p.x + _moveAxis.dx * kPlayerSpeed * dt,
        16,
        _size.width - 16,
      );
      p.y = clampDouble(
        p.y + _moveAxis.dy * kPlayerSpeed * dt,
        44,
        _size.height - 26,
      );
      p.tilt += (_moveAxis.dx - p.tilt) * math.min(1, dt * 9);
    } else {
      p.tilt += (0 - p.tilt) * math.min(1, dt * 7);
    }

    p.fireCooldown -= dt;
    if (p.fireCooldown <= 0) {
      final interval = kBaseFireInterval - 0.008 * (p.weaponLevel - 1);
      p.fireCooldown = interval * (p.rapid > 0 ? 0.62 : 1);
      appendPlayerShots(p, playerBullets);
      if (_shootCooldown <= 0) {
        _shootCooldown = 0.12;
        _emit(BattleEvent.shoot);
      }
    }

    _trailTimer += dt;
    while (_trailTimer >= 0.05) {
      _trailTimer -= 0.05;
      _effects.addPlayerTrail(Offset(p.x, p.y), shielded: p.shield > 0);
    }
  }

  // ---------------------------------------------------------------- 波次

  void _updateWaves(double dt) {
    for (final request in _director.update(dt)) {
      _spawnEnemy(request);
    }
    if (_director.spawning || enemies.isNotEmpty) return;
    _gapTimer -= dt;
    if (_gapTimer > 0) return;
    _director.startNextWave();
    wave = _director.wave;
    _gapTimer = 2.6;
    _effects.addPopup(
      ScorePopup(
        x: _size.width / 2,
        y: _size.height * 0.36,
        text: _director.bossWave ? '⚠ $bossName 来袭' : '第 $wave 波',
        color: _director.bossWave ? 0xFFFF6B6B : 0xFF8BE9FD,
      ),
    );
    _emit(_director.bossWave ? BattleEvent.bossAppear : BattleEvent.waveStart);
    if (_director.bossWave) flash = 0.22;
    notifyListeners();
  }

  void _spawnEnemy(SpawnRequest request) {
    final difficulty = 1 + 0.09 * (wave - 1);
    enemies.add(
      Enemy(
        kind: request.kind,
        pattern: request.pattern,
        x: request.x,
        y: request.kind == EnemyKind.boss ? -60 : -24,
        difficulty: difficulty,
        driftPhase: request.phase,
        variant: request.variant,
      ),
    );
  }

  // ---------------------------------------------------------------- 敌机

  void _updateEnemies(double dt) {
    for (final enemy in enemies) {
      if (enemy.dead) continue;
      enemy.age += dt;
      enemy.hitFlash = math.max(0, enemy.hitFlash - dt);
      if (enemy.isBoss) {
        _updateBoss(enemy, dt);
      } else {
        advanceEnemy(
          enemy,
          dt,
          targetX: enemy.pattern == EnemyPattern.chase ? player.x : null,
        );
        if (enemy.y > _size.height + 60) {
          enemy.dead = true;
        } else if (enemy.y > 6 && enemy.y < _size.height * 0.78) {
          _updateEnemyFire(enemy, dt);
        }
      }
    }
    enemies.removeWhere((enemy) => enemy.dead);
  }

  void _updateEnemyFire(Enemy enemy, double dt) {
    final spec = enemy.spec;
    if (spec.fireCount <= 0) return;
    enemy.fireCooldown -= dt;
    if (enemy.fireCooldown > 0) return;
    final scale = 1 / math.sqrt(1 + 0.09 * (wave - 1));
    enemy.fireCooldown = spec.fireInterval * scale;
    final origin = Offset(enemy.x, enemy.y);
    if (spec.fireMode == EnemyFireMode.radial) {
      enemyBullets.addAll(
        buildRadialVolley(
          origin: origin,
          count: spec.fireCount,
          speed: spec.bulletSpeed,
          kind: spec.bulletKind,
          phase: enemy.age * 0.45,
        ),
      );
      return;
    }
    enemyBullets.addAll(
      buildAimedVolley(
        origin: origin,
        target: Offset(player.x, player.y),
        speed: spec.bulletSpeed,
        count: spec.fireCount,
        spread: spec.fireSpread,
        kind: spec.bulletKind,
      ),
    );
  }

  void _updateBoss(Enemy boss, double dt) {
    if (!advanceBossEntry(boss, dt)) return;
    hoverBoss(boss, _size);
    boss.attackTimer -= dt;
    if (boss.attackTimer > 0) return;

    final cycle = boss.attackPhase % 4;
    final speed = 158.0 + math.min(50, wave * 3);
    boss.attackPhase++;
    boss.attackTimer = math.max(1.1, 2.1 - wave * 0.05);
    enemyBullets.addAll(
      buildBossBarrage(
        boss: boss,
        target: Offset(player.x, player.y),
        cycle: cycle,
        speed: speed,
        variant: boss.variant,
      ),
    );
  }

  void _damageEnemy(Enemy enemy, double damage) {
    if (enemy.dead) return;
    enemy.hp -= damage;
    enemy.hitFlash = 0.09;
    if (enemy.hp <= 0) _killEnemy(enemy);
  }

  void _killEnemy(Enemy enemy) {
    if (enemy.dead) return;
    enemy.dead = true;
    kills++;
    combo++;
    comboTimer = 2.6;
    final gain = (enemy.spec.score * multiplier).round();
    score += gain;
    final big = enemy.isBoss || enemy.kind == EnemyKind.elite;
    _effects.addPopup(
      ScorePopup(
        x: enemy.x,
        y: enemy.y,
        text: '+$gain',
        color: enemy.isBoss ? 0xFFFFD54F : null,
      ),
    );
    _effects.explode(
      Offset(enemy.x, enemy.y),
      big: big,
      color: _enemyColor(enemy.kind),
    );
    shake = math.max(shake, enemy.isBoss ? 18 : (big ? 8 : 3));
    if (enemy.isBoss) {
      flash = 0.5;
      _emit(BattleEvent.bigExplosion);
      _dropAt(enemy.x - 26, enemy.y);
      _dropAt(enemy.x, enemy.y);
      _dropAt(enemy.x + 26, enemy.y);
      _dropPity = 0;
      _effects.addPopup(
        ScorePopup(
          x: enemy.x,
          y: enemy.y - 26,
          text: '击破 $bossName',
          color: 0xFFFFD54F,
        ),
      );
    } else {
      _emit(big ? BattleEvent.bigExplosion : BattleEvent.explosion);
      // 连续多架未掉落时强制补给一次，避免整局拿不到火力升级。
      final drop = _rng.nextDouble() < enemy.spec.dropChance || _dropPity >= 20;
      if (drop) {
        _dropAt(enemy.x, enemy.y);
        _dropPity = 0;
      } else {
        _dropPity++;
      }
    }
    notifyListeners();
  }

  int _enemyColor(EnemyKind kind) => switch (kind) {
    EnemyKind.scout => 0xFFFFB347,
    EnemyKind.fighter => 0xFFFF7A59,
    EnemyKind.bomber => 0xFFFF5252,
    EnemyKind.elite => 0xFFFF4FA3,
    EnemyKind.interceptor => 0xFFFFE082,
    EnemyKind.drone => 0xFFFF7043,
    EnemyKind.fortress => 0xFFB388FF,
    EnemyKind.boss => 0xFFFFD54F,
  };

  // ---------------------------------------------------------------- 弹道

  void _updateBullets(double dt) {
    for (final bullet in playerBullets) {
      bullet.x += bullet.vx * dt;
      bullet.y += bullet.vy * dt;
      if (bullet.y < -24 || bullet.x < -24 || bullet.x > _size.width + 24) {
        bullet.dead = true;
      }
    }
    for (final bullet in enemyBullets) {
      bullet.x += bullet.vx * dt;
      bullet.y += bullet.vy * dt;
      if (bullet.y < -30 ||
          bullet.y > _size.height + 30 ||
          bullet.x < -30 ||
          bullet.x > _size.width + 30) {
        bullet.dead = true;
      }
    }
    playerBullets.removeWhere((bullet) => bullet.dead);
    enemyBullets.removeWhere((bullet) => bullet.dead);
  }

  // ---------------------------------------------------------------- 补给

  void _updatePowerUps(double dt) {
    for (final item in powerUps) {
      item.age += dt;
      item.y += item.vy * dt;
      item.x += math.sin(item.age * 2.4) * 18 * dt;
      if (item.y > _size.height + 30) item.dead = true;
    }
    powerUps.removeWhere((item) => item.dead);
  }

  void _dropAt(double x, double y) {
    final roll = _rng.nextDouble();
    final kind = roll < 0.4
        ? PowerUpKind.weapon
        : roll < 0.62
        ? PowerUpKind.shield
        : roll < 0.75
        ? PowerUpKind.bomb
        : roll < 0.87
        ? PowerUpKind.star
        : PowerUpKind.rapid;
    powerUps.add(
      PowerUp(x: clampDouble(x, 20, _size.width - 20), y: y, kind: kind),
    );
  }

  void _collectPowerUp(PowerUp item) {
    item.dead = true;
    final position = Offset(item.x, item.y);
    switch (item.kind) {
      case PowerUpKind.weapon:
        if (player.weaponLevel < Player.maxWeaponLevel) {
          player.weaponLevel++;
          _effects.addPopup(
            ScorePopup(
              x: item.x,
              y: item.y,
              text: '火力 ${player.weaponLevel} 级',
            ),
          );
        } else {
          score += 300;
          _effects.addPopup(ScorePopup(x: item.x, y: item.y, text: '+300'));
        }
      case PowerUpKind.shield:
        player.shield = math.max(player.shield, 10);
        _effects.addPopup(
          ScorePopup(x: item.x, y: item.y, text: '护盾展开', color: 0xFF7FD8FF),
        );
      case PowerUpKind.bomb:
        if (player.bombs < Player.maxBombs) {
          player.bombs++;
          _effects.addPopup(ScorePopup(x: item.x, y: item.y, text: '炸弹 +1'));
        } else {
          score += 200;
          _effects.addPopup(ScorePopup(x: item.x, y: item.y, text: '+200'));
        }
      case PowerUpKind.star:
        final gain = 250 * multiplier;
        score += gain;
        _effects.addPopup(ScorePopup(x: item.x, y: item.y, text: '+$gain'));
      case PowerUpKind.rapid:
        player.rapid = math.min(12, player.rapid + 6);
        _effects.addPopup(
          ScorePopup(x: item.x, y: item.y, text: '急速射击', color: 0xFFFFE082),
        );
    }
    _effects.burst(
      position,
      count: 10,
      color: 0xFF7FD8FF,
      speed: 120,
      size: 2.2,
      life: 0.4,
    );
    _emit(BattleEvent.powerUp);
    notifyListeners();
  }

  // ---------------------------------------------------------------- 碰撞

  void _collide(double dt) {
    final px = player.x;
    final py = player.y;
    for (final bullet in playerBullets) {
      if (bullet.dead) continue;
      final toX = bullet.x;
      final toY = bullet.y;
      final fromX = toX - bullet.vx * dt;
      final fromY = toY - bullet.vy * dt;
      final minX = math.min(fromX, toX);
      final maxX = math.max(fromX, toX);
      final minY = math.min(fromY, toY);
      final maxY = math.max(fromY, toY);
      for (final enemy in enemies) {
        if (enemy.dead) continue;
        final reach = enemy.radius + bullet.radius;
        // 包围盒先排除远处的敌机，密集弹幕下省掉大部分扫掠计算。
        if (enemy.x + reach < minX ||
            enemy.x - reach > maxX ||
            enemy.y + reach < minY ||
            enemy.y - reach > maxY) {
          continue;
        }
        if (segmentHitsCircleXY(
          centerX: enemy.x,
          centerY: enemy.y,
          radius: reach,
          fromX: fromX,
          fromY: fromY,
          toX: toX,
          toY: toY,
        )) {
          bullet.dead = true;
          _damageEnemy(enemy, bullet.damage);
          _effects.spark(Offset(toX, toY), 0xFFB7F4FF);
          break;
        }
      }
    }
    if (player.alive) {
      for (final bullet in enemyBullets) {
        if (bullet.dead) continue;
        final toX = bullet.x;
        final toY = bullet.y;
        final fromX = toX - bullet.vx * dt;
        final fromY = toY - bullet.vy * dt;
        final reach = Player.radius + bullet.radius;
        if (math.min(fromX, toX) > px + reach ||
            math.max(fromX, toX) < px - reach ||
            math.min(fromY, toY) > py + reach ||
            math.max(fromY, toY) < py - reach) {
          continue;
        }
        if (segmentHitsCircleXY(
          centerX: px,
          centerY: py,
          radius: reach,
          fromX: fromX,
          fromY: fromY,
          toX: toX,
          toY: toY,
        )) {
          bullet.dead = true;
          _hitPlayer();
          break;
        }
      }
    }
    for (final enemy in enemies) {
      if (enemy.dead || !player.alive) continue;
      if (circlesOverlapXY(
        enemy.x,
        enemy.y,
        enemy.radius,
        px,
        py,
        Player.radius,
      )) {
        _damageEnemy(enemy, enemy.isBoss ? 30 : 24);
        _hitPlayer();
      }
    }
    for (final item in powerUps) {
      if (item.dead) continue;
      if (circlesOverlapXY(
        item.x,
        item.y,
        PowerUp.radius + 4,
        px,
        py,
        Player.radius,
      )) {
        _collectPowerUp(item);
      }
    }
    powerUps.removeWhere((item) => item.dead);
  }

  void _hitPlayer() {
    final center = Offset(player.x, player.y);
    if (!player.alive || player.invuln > 0) return;
    if (player.shield > 0) {
      player.shield = 0;
      player.invuln = 1.1;
      shake = math.max(shake, 8);
      flash = math.max(flash, 0.16);
      _emit(BattleEvent.shieldBreak);
      _effects.burst(
        center,
        count: 16,
        color: 0xFF7FD8FF,
        speed: 170,
        size: 2.4,
      );
      notifyListeners();
      return;
    }
    player.lives--;
    player.weaponLevel = math.max(1, player.weaponLevel - 1);
    player.invuln = 2;
    shake = math.max(shake, 14);
    flash = math.max(flash, 0.38);
    _emit(BattleEvent.playerHit);
    _effects.explode(center, big: true, color: 0xFF4FD1FF);
    enemyBullets.removeWhere((bullet) {
      final delta = Offset(bullet.x, bullet.y) - center;
      return delta.distanceSquared < 100 * 100;
    });
    if (player.lives <= 0) {
      _gameOver();
    } else {
      notifyListeners();
    }
  }

  void _gameOver() {
    player.alive = false;
    player.lives = 0;
    phase = BattlePhase.gameOver;
    survived = Duration(milliseconds: (elapsed * 1000).round());
    flash = 0.85;
    shake = 24;
    _emit(BattleEvent.gameOver);
    _effects.explode(Offset(player.x, player.y), big: true, color: 0xFFFFD54F);
    notifyListeners();
  }

  // ---------------------------------------------------------------- 特效

  void _updateEffects(double dt) {
    _effects.update(dt);
    if (phase != BattlePhase.gameOver) return;
    for (final enemy in enemies) {
      enemy.hitFlash = math.max(0, enemy.hitFlash - dt);
    }
    shake = shake < 0.05 ? 0 : shake * math.exp(-3 * dt);
    flash = math.max(0, flash - 1.6 * dt);
    _effects.updateStars(dt, _size);
  }

  void _emit(BattleEvent event) {
    if (_events.length >= 24) return;
    _events.add(event);
  }
}
