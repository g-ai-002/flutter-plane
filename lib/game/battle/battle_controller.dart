import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'battle_types.dart';
import 'wave_director.dart';

/// 战斗控制器：纯逻辑的弹幕战场，负责玩家、敌机、弹道、碰撞、波次与计分。
///
/// 渲染层按世界坐标（宽度固定 [kWorldWidth]）缩放绘制，界面层只读取状态，
/// 因此同一套逻辑可以在 Android、Windows 与 Web 上保持一致，并可直接单测。
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
    player = Player(x: size.width / 2, y: size.height - 84);
    _initStars();
  }

  static const List<String> _bossNames = ['赤蝎母舰', '雷霆要塞', '虚空旗舰', '终焉之核'];

  final int _seed;
  final math.Random _rng;
  final math.Random _starRng;
  WaveDirector _director;

  late Player player;
  final List<Enemy> enemies = [];
  final List<Bullet> playerBullets = [];
  final List<Bullet> enemyBullets = [];
  final List<PowerUp> powerUps = [];
  final List<Particle> particles = [];
  final List<ScorePopup> popups = [];
  final List<Star> stars = [];

  final List<BattleEvent> _events = [];
  Offset _moveAxis = Offset.zero;
  Size _size;
  int _highScore;
  int _runs = 0;
  double _gapTimer = 1.4;
  double _hudTimer = 0;
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

  String get bossName {
    if (wave <= 0) return '';
    return _bossNames[(wave ~/ 4 - 1) % _bossNames.length];
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
    particles.clear();
    popups.clear();
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
    _trailTimer = 0;
    _shootCooldown = 0;
    _dropPity = 0;
    _moveAxis = Offset.zero;
    _initStars();
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
      _burst(
        bullet.x,
        bullet.y,
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
    popups.add(
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
    _initStars();
    notifyListeners();
  }

  List<BattleEvent> drainEvents() {
    if (_events.isEmpty) return const [];
    final copy = List<BattleEvent>.of(_events);
    _events.clear();
    return copy;
  }

  void update(double dt) {
    if (dt <= 0) return;
    if (phase == BattlePhase.gameOver || phase == BattlePhase.ready) {
      _updateEffects(dt);
      return;
    }
    if (phase != BattlePhase.playing) return;

    elapsed += dt;
    _updateStars(dt);
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
    if (_hudTimer >= 0.1) {
      _hudTimer = 0;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------- 玩家

  void _updatePlayer(double dt) {
    final p = player;
    if (!p.alive) return;
    p.invuln = math.max(0, p.invuln - dt);
    p.shield = math.max(0, p.shield - dt);
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
      p.fireCooldown = kBaseFireInterval - 0.008 * (p.weaponLevel - 1);
      _firePlayer();
      if (_shootCooldown <= 0) {
        _shootCooldown = 0.12;
        _emit(BattleEvent.shoot);
      }
    }

    _trailTimer += dt;
    while (_trailTimer >= 0.05) {
      _trailTimer -= 0.05;
      particles.add(
        Particle(
          x: p.x + (_rng.nextDouble() - 0.5) * 6,
          y: p.y + 14,
          vx: (_rng.nextDouble() - 0.5) * 14,
          vy: 90,
          life: 0.26,
          size: 2.4 + _rng.nextDouble() * 1.6,
          color: p.shield > 0 ? 0xFF7FD8FF : 0xFF4FD1FF,
          kind: ParticleKind.trail,
          drag: 2.4,
        ),
      );
    }
    if (particles.length > 420) {
      particles.removeRange(0, particles.length - 420);
    }
  }

  void _firePlayer() {
    final p = player;
    final y = p.y - 16;
    final level = p.weaponLevel;

    void shot(double x, double angle, {double speed = kPlayerBulletSpeed}) {
      playerBullets.add(
        Bullet(
          x: x,
          y: y,
          vx: math.sin(angle) * speed,
          vy: -math.cos(angle) * speed,
          radius: 3.4,
          damage: 1,
          fromPlayer: true,
        ),
      );
    }

    if (level == 1) {
      shot(p.x, 0);
    } else if (level == 2) {
      shot(p.x - 5, 0);
      shot(p.x + 5, 0);
    } else if (level == 3) {
      shot(p.x - 6, 0);
      shot(p.x + 6, 0);
      shot(p.x - 11, -0.16);
      shot(p.x + 11, 0.16);
    } else if (level == 4) {
      shot(p.x - 7, 0);
      shot(p.x, 0);
      shot(p.x + 7, 0);
      shot(p.x - 13, -0.17);
      shot(p.x + 13, 0.17);
    } else {
      shot(p.x - 8, 0);
      shot(p.x, 0);
      shot(p.x + 8, 0);
      shot(p.x - 13, -0.14);
      shot(p.x + 13, 0.14);
      shot(p.x - 16, -0.3);
      shot(p.x + 16, 0.3);
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
    popups.add(
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
        switch (enemy.pattern) {
          case EnemyPattern.straight:
            enemy.y += enemy.vy * dt;
          case EnemyPattern.sine:
            enemy.y += enemy.vy * dt;
            enemy.x =
                enemy.baseX +
                math.sin(enemy.age * 2.1 + enemy.driftPhase * math.pi * 2) * 26;
          case EnemyPattern.dive:
            enemy.vy = math.min(190, enemy.vy + 30 * dt);
            enemy.y += enemy.vy * dt;
            enemy.x +=
                math.sin(enemy.age * 1.6 + enemy.driftPhase * 6) * 26 * dt;
          case EnemyPattern.hover:
            if (!enemy.entered) {
              enemy.y += 95 * dt;
              if (enemy.y >= enemy.hoverY) {
                enemy.y = enemy.hoverY;
                enemy.entered = true;
              }
            } else {
              enemy.hoverTimer += dt;
              enemy.x =
                  enemy.baseX +
                  math.sin(enemy.hoverTimer * 1.1 + enemy.driftPhase * 6) * 32;
              enemy.y = enemy.hoverY + math.sin(enemy.hoverTimer * 1.9) * 7;
              if (enemy.hoverTimer > 11) enemy.y += 56 * dt;
            }
        }
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
    enemy.fireCooldown -= dt;
    if (enemy.fireCooldown > 0) return;
    final scale = 1 / math.sqrt(1 + 0.09 * (wave - 1));
    enemy.fireCooldown = enemy.spec.fireInterval * scale;
    switch (enemy.kind) {
      case EnemyKind.scout:
        break;
      case EnemyKind.fighter:
        _shootAimed(enemy, speed: 185, count: 1, spread: 0);
      case EnemyKind.bomber:
        _shootAimed(enemy, speed: 155, count: 3, spread: 0.22, kind: 2);
      case EnemyKind.elite:
        _shootAimed(enemy, speed: 175, count: 5, spread: 0.17, kind: 2);
      case EnemyKind.boss:
        break;
    }
  }

  void _updateBoss(Enemy boss, double dt) {
    if (!boss.entered) {
      boss.y += 78 * dt;
      if (boss.y >= 92) {
        boss.y = 92;
        boss.entered = true;
      }
      return;
    }
    final sway = math.min(118.0, _size.width / 2 - 58);
    boss.x = _size.width / 2 + math.sin(boss.age * 0.72) * sway;
    boss.y = 92 + math.sin(boss.age * 1.3) * 6;
    boss.attackTimer -= dt;
    if (boss.attackTimer > 0) return;

    final cycle = boss.attackPhase % 4;
    final speed = 158.0 + math.min(50, wave * 3);
    boss.attackPhase++;
    boss.attackTimer = math.max(1.1, 2.1 - wave * 0.05);
    switch (cycle) {
      case 0:
        _shootAimed(boss, speed: speed + 40, count: 3, spread: 0.15, kind: 3);
      case 1:
        final base = boss.age * 0.6;
        const count = 18;
        for (var i = 0; i < count; i++) {
          final angle = base + i * 2 * math.pi / count;
          _enemyShot(boss.x, boss.y, angle, speed * 0.85, 3);
        }
      case 2:
        _shootAimed(boss, speed: speed + 60, count: 5, spread: 0.19, kind: 3);
      case 3:
        for (var side = -1; side <= 1; side += 2) {
          for (var i = 0; i < 5; i++) {
            final angle = side * (0.42 + i * 0.18) + math.pi / 2;
            _enemyShot(boss.x + side * 26, boss.y + 12, angle, speed, 3);
          }
        }
    }
  }

  void _shootAimed(
    Enemy enemy, {
    required double speed,
    required int count,
    required double spread,
    int kind = 1,
  }) {
    final dir = aimDirection(enemy.x, enemy.y, player.x, player.y);
    final base = math.atan2(dir.y, dir.x);
    for (var i = 0; i < count; i++) {
      final angle = base + (i - (count - 1) / 2) * spread;
      _enemyShot(enemy.x, enemy.y + 6, angle, speed, kind);
    }
  }

  void _enemyShot(double x, double y, double angle, double speed, int kind) {
    enemyBullets.add(
      Bullet(
        x: x,
        y: y,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        radius: kind == 3 ? 5 : 4.2,
        damage: 1,
        fromPlayer: false,
        kind: kind,
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
    popups.add(
      ScorePopup(
        x: enemy.x,
        y: enemy.y,
        text: '+$gain',
        color: enemy.isBoss ? 0xFFFFD54F : null,
      ),
    );
    _explode(enemy.x, enemy.y, big: big, color: _enemyColor(enemy.kind));
    shake = math.max(shake, enemy.isBoss ? 18 : (big ? 8 : 3));
    if (enemy.isBoss) {
      flash = 0.5;
      _emit(BattleEvent.bigExplosion);
      _dropAt(enemy.x - 26, enemy.y);
      _dropAt(enemy.x, enemy.y);
      _dropAt(enemy.x + 26, enemy.y);
      _dropPity = 0;
      popups.add(
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
    final kind = roll < 0.44
        ? PowerUpKind.weapon
        : roll < 0.68
        ? PowerUpKind.shield
        : roll < 0.82
        ? PowerUpKind.bomb
        : PowerUpKind.star;
    powerUps.add(
      PowerUp(x: clampDouble(x, 20, _size.width - 20), y: y, kind: kind),
    );
  }

  void _collectPowerUp(PowerUp item) {
    item.dead = true;
    switch (item.kind) {
      case PowerUpKind.weapon:
        if (player.weaponLevel < Player.maxWeaponLevel) {
          player.weaponLevel++;
          popups.add(
            ScorePopup(
              x: item.x,
              y: item.y,
              text: '火力 ${player.weaponLevel} 级',
            ),
          );
        } else {
          score += 300;
          popups.add(ScorePopup(x: item.x, y: item.y, text: '+300'));
        }
      case PowerUpKind.shield:
        player.shield = math.max(player.shield, 10);
        popups.add(
          ScorePopup(x: item.x, y: item.y, text: '护盾展开', color: 0xFF7FD8FF),
        );
      case PowerUpKind.bomb:
        if (player.bombs < Player.maxBombs) {
          player.bombs++;
          popups.add(ScorePopup(x: item.x, y: item.y, text: '炸弹 +1'));
        } else {
          score += 200;
          popups.add(ScorePopup(x: item.x, y: item.y, text: '+200'));
        }
      case PowerUpKind.star:
        final gain = 250 * multiplier;
        score += gain;
        popups.add(ScorePopup(x: item.x, y: item.y, text: '+$gain'));
    }
    _burst(
      item.x,
      item.y,
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
    for (final bullet in playerBullets) {
      if (bullet.dead) continue;
      for (final enemy in enemies) {
        if (enemy.dead) continue;
        final radius = enemy.radius + bullet.radius;
        if (_segmentHits(
          enemy.x,
          enemy.y,
          radius,
          bullet.x,
          bullet.y,
          -bullet.vx * dt,
          -bullet.vy * dt,
        )) {
          bullet.dead = true;
          _damageEnemy(enemy, bullet.damage);
          _spark(bullet.x, bullet.y, 0xFFB7F4FF);
          break;
        }
      }
    }
    if (player.alive) {
      for (final bullet in enemyBullets) {
        if (bullet.dead) continue;
        final radius = Player.radius + bullet.radius;
        if (_segmentHits(
          player.x,
          player.y,
          radius,
          bullet.x,
          bullet.y,
          -bullet.vx * dt,
          -bullet.vy * dt,
        )) {
          bullet.dead = true;
          _hitPlayer();
          break;
        }
      }
    }
    for (final enemy in enemies) {
      if (enemy.dead || !player.alive) continue;
      final distance = math.sqrt(
        math.pow(enemy.x - player.x, 2) + math.pow(enemy.y - player.y, 2),
      );
      if (distance < enemy.radius + Player.radius) {
        _damageEnemy(enemy, enemy.isBoss ? 30 : 24);
        _hitPlayer();
      }
    }
    for (final item in powerUps) {
      if (item.dead) continue;
      final distance = math.sqrt(
        math.pow(item.x - player.x, 2) + math.pow(item.y - player.y, 2),
      );
      if (distance < PowerUp.radius + Player.radius + 4) {
        _collectPowerUp(item);
      }
    }
    powerUps.removeWhere((item) => item.dead);
  }

  /// 子弹在一帧内从 `(x, y)` 移动到 `(x + dx, y + dy)`，判断扫掠线段是否命中圆。
  bool _segmentHits(
    double cx,
    double cy,
    double radius,
    double x,
    double y,
    double dx,
    double dy,
  ) {
    final lengthSq = dx * dx + dy * dy;
    var t = 0.0;
    if (lengthSq > 0.0001) {
      t = ((cx - x) * dx + (cy - y) * dy) / lengthSq;
      t = t.clamp(0.0, 1.0);
    }
    final px = x + dx * t;
    final py = y + dy * t;
    final ex = cx - px;
    final ey = cy - py;
    return ex * ex + ey * ey <= radius * radius;
  }

  void _hitPlayer() {
    if (!player.alive || player.invuln > 0) return;
    if (player.shield > 0) {
      player.shield = 0;
      player.invuln = 1.1;
      shake = math.max(shake, 8);
      flash = math.max(flash, 0.16);
      _emit(BattleEvent.shieldBreak);
      _burst(
        player.x,
        player.y,
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
    _explode(player.x, player.y, big: true, color: 0xFF4FD1FF);
    enemyBullets.removeWhere((bullet) {
      final dx = bullet.x - player.x;
      final dy = bullet.y - player.y;
      return dx * dx + dy * dy < 100 * 100;
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
    _explode(player.x, player.y, big: true, color: 0xFFFFD54F);
    notifyListeners();
  }

  // ---------------------------------------------------------------- 特效

  void _updateEffects(double dt) {
    for (final particle in particles) {
      particle.life -= dt;
      final damping = math.exp(-particle.drag * dt);
      particle.vx *= damping;
      particle.vy *= damping;
      particle.x += particle.vx * dt;
      particle.y += particle.vy * dt;
    }
    particles.removeWhere((particle) => particle.dead);
    for (final popup in popups) {
      popup.life -= dt;
      popup.y -= 24 * dt;
    }
    popups.removeWhere((popup) => popup.dead);
    if (phase == BattlePhase.gameOver) {
      for (final enemy in enemies) {
        enemy.hitFlash = math.max(0, enemy.hitFlash - dt);
      }
      shake = shake < 0.05 ? 0 : shake * math.exp(-3 * dt);
      flash = math.max(0, flash - 1.6 * dt);
      _updateStars(dt);
    }
  }

  void _explode(double x, double y, {required bool big, required int color}) {
    _burst(
      x,
      y,
      count: big ? 26 : 12,
      color: color,
      speed: big ? 240 : 150,
      size: big ? 3.4 : 2.2,
      life: big ? 0.8 : 0.5,
    );
    _burst(
      x,
      y,
      count: big ? 10 : 4,
      color: 0xFF2A3358,
      speed: big ? 90 : 55,
      size: big ? 9 : 5,
      kind: ParticleKind.smoke,
      life: big ? 1.1 : 0.7,
    );
    _burst(
      x,
      y,
      count: 2,
      color: 0xFFFFFFFF,
      speed: 40,
      size: big ? 18 : 9,
      kind: ParticleKind.ring,
      life: 0.36,
    );
    if (big) {
      _burst(
        x,
        y,
        count: 8,
        color: 0xFFFFD54F,
        speed: 190,
        size: 3,
        kind: ParticleKind.debris,
        life: 0.9,
      );
    }
  }

  void _spark(double x, double y, int color) {
    _burst(x, y, count: 3, color: color, speed: 90, size: 1.8, life: 0.22);
  }

  void _burst(
    double x,
    double y, {
    required int count,
    required int color,
    double speed = 160,
    double size = 2.6,
    ParticleKind kind = ParticleKind.spark,
    double life = 0.5,
  }) {
    for (var i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final velocity = speed * (0.3 + _rng.nextDouble() * 0.9);
      particles.add(
        Particle(
          x: x,
          y: y,
          vx: math.cos(angle) * velocity,
          vy: math.sin(angle) * velocity,
          life: life * (0.6 + _rng.nextDouble() * 0.7),
          size: size * (0.7 + _rng.nextDouble() * 0.7),
          color: color,
          kind: kind,
          drag: kind == ParticleKind.smoke ? 1.1 : 2.2,
        ),
      );
    }
    if (particles.length > 460) {
      particles.removeRange(0, particles.length - 460);
    }
  }

  // ---------------------------------------------------------------- 星空

  void _initStars() {
    stars.clear();
    final count = (_size.width * _size.height / 5200).round().clamp(40, 110);
    for (var i = 0; i < count; i++) {
      stars.add(
        Star(
          x: _starRng.nextDouble() * _size.width,
          y: _starRng.nextDouble() * _size.height,
          speed: 18 + _starRng.nextDouble() * 72,
          size: 0.6 + _starRng.nextDouble() * 1.5,
          alpha: 0.18 + _starRng.nextDouble() * 0.6,
        ),
      );
    }
  }

  void _updateStars(double dt) {
    for (final star in stars) {
      star.y += star.speed * dt;
      if (star.y > _size.height + 4) {
        star.y = -4;
        star.x = _starRng.nextDouble() * _size.width;
      }
    }
  }

  void _emit(BattleEvent event) {
    if (_events.length >= 24) return;
    _events.add(event);
  }
}
