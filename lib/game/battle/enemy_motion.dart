import 'dart:math' as math;
import 'dart:ui';

import 'battle_types.dart';

/// 敌机移动策略：按 [EnemyPattern] 推进一帧位置。
///
/// 与开火、碰撞、掉落分离，新增移动方式时只需在这里补充分支。
/// [targetX] 是追踪型敌机（自爆无人机）需要对齐的玩家横坐标。
void advanceEnemy(Enemy enemy, double dt, {double? targetX}) {
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
      enemy.x += math.sin(enemy.age * 1.6 + enemy.driftPhase * 6) * 26 * dt;
    case EnemyPattern.chase:
      enemy.vy = math.min(214, enemy.vy + 42 * dt);
      enemy.y += enemy.vy * dt;
      if (targetX != null) {
        final step = 96 * dt;
        enemy.x += (targetX - enemy.x).clamp(-step, step);
      }
    case EnemyPattern.hover:
      _advanceHover(enemy, dt);
  }
}

void _advanceHover(Enemy enemy, double dt) {
  if (!enemy.entered) {
    enemy.y += 95 * dt;
    if (enemy.y >= enemy.hoverY) {
      enemy.y = enemy.hoverY;
      enemy.entered = true;
    }
    return;
  }
  enemy.hoverTimer += dt;
  enemy.x =
      enemy.baseX +
      math.sin(enemy.hoverTimer * 1.1 + enemy.driftPhase * 6) * 32;
  enemy.y = enemy.hoverY + math.sin(enemy.hoverTimer * 1.9) * 7;
  if (enemy.hoverTimer > 11) enemy.y += 56 * dt;
}

/// Boss 从顶部下潜到固定高度；返回是否已经就位。
bool advanceBossEntry(Enemy boss, double dt) {
  if (boss.entered) return true;
  boss.y += 78 * dt;
  if (boss.y >= 92) {
    boss.y = 92;
    boss.entered = true;
  }
  return boss.entered;
}

/// Boss 就位后的左右巡航与轻微浮动。
void hoverBoss(Enemy boss, Size world) {
  final sway = math.min(118.0, world.width / 2 - 58);
  boss.x = world.width / 2 + math.sin(boss.age * 0.72) * sway;
  boss.y = 92 + math.sin(boss.age * 1.3) * 6;
}
