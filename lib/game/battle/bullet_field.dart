import 'battle_types.dart';

/// 推进一组弹道，并按战场边界原地回收越界与已失效的子弹。
///
/// 玩家弹与敌弹的推进规则一致，只是裁剪边界不同；统一实现后战斗循环
/// 不再保留两段几乎相同的循环，也避免 `removeWhere` 每帧创建闭包。
void advanceBullets(
  List<Bullet> bullets,
  double dt, {
  required double worldWidth,
  required double worldHeight,
  required double margin,
}) {
  if (bullets.isEmpty) return;
  var write = 0;
  for (var read = 0; read < bullets.length; read++) {
    final bullet = bullets[read];
    bullet.x += bullet.vx * dt;
    bullet.y += bullet.vy * dt;
    if (bullet.x < -margin ||
        bullet.x > worldWidth + margin ||
        bullet.y < -margin ||
        bullet.y > worldHeight + margin) {
      bullet.dead = true;
    }
    if (bullet.dead) continue;
    bullets[write++] = bullet;
  }
  bullets.length = write;
}
