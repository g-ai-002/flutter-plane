import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/game/battle/battle_types.dart';
import 'package:sky_fighter/game/battle/bullet_field.dart';

Bullet bullet({
  double x = 200,
  double y = 300,
  double vx = 0,
  double vy = -100,
  bool dead = false,
}) {
  return Bullet(
    x: x,
    y: y,
    vx: vx,
    vy: vy,
    radius: 3,
    damage: 1,
    fromPlayer: true,
  )..dead = dead;
}

void main() {
  group('弹道推进', () {
    test('按速度推进并保留仍在战场内的子弹', () {
      final bullets = [bullet(vy: -120)];
      advanceBullets(
        bullets,
        0.5,
        worldWidth: 400,
        worldHeight: 700,
        margin: 24,
      );
      expect(bullets, hasLength(1));
      expect(bullets.single.y, 240);
      expect(bullets.single.dead, isFalse);
    });

    test('越界子弹被回收，存活子弹保持原顺序', () {
      final top = bullet(y: 10, vy: -200);
      final alive = bullet();
      final side = bullet(x: 430, vx: 200, vy: 0);
      final bullets = [top, alive, side];

      advanceBullets(
        bullets,
        0.5,
        worldWidth: 400,
        worldHeight: 700,
        margin: 24,
      );

      expect(bullets, [same(alive)]);
      expect(top.dead, isTrue);
      expect(side.dead, isTrue);
    });

    test('已在碰撞中失效的子弹直接移除', () {
      final dead = bullet(dead: true);
      final alive = bullet();
      final bullets = [dead, alive];

      advanceBullets(
        bullets,
        0,
        worldWidth: 400,
        worldHeight: 700,
        margin: 24,
      );

      expect(bullets, [same(alive)]);
    });

    test('空列表与零步长不会产生副作用', () {
      final bullets = <Bullet>[];
      advanceBullets(
        bullets,
        0.016,
        worldWidth: 400,
        worldHeight: 700,
        margin: 24,
      );
      expect(bullets, isEmpty);

      final still = bullet(x: 120, y: 200);
      advanceBullets(
        [still],
        0,
        worldWidth: 400,
        worldHeight: 700,
        margin: 24,
      );
      expect(still.x, 120);
      expect(still.y, 200);
    });

    test('底部与右侧越界同样回收', () {
      final bottom = bullet(y: 725, vy: 100);
      final right = bullet(x: 425, vx: 100, vy: 0);
      final bullets = [bottom, right];

      advanceBullets(
        bullets,
        0,
        worldWidth: 400,
        worldHeight: 700,
        margin: 24,
      );

      expect(bullets, isEmpty);
    });
  });
}
