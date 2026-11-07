import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/game/battle/battle_collision.dart';

void main() {
  group('碰撞检测', () {
    test('线段扫过圆时命中，即使两端都在圆外', () {
      final hit = segmentHitsCircle(
        center: const Offset(200, 200),
        radius: 11,
        from: const Offset(200, 240),
        to: const Offset(200, 160),
      );
      expect(hit, isTrue);
    });

    test('线段偏离圆时不命中', () {
      final hit = segmentHitsCircle(
        center: const Offset(200, 200),
        radius: 11,
        from: const Offset(230, 240),
        to: const Offset(230, 160),
      );
      expect(hit, isFalse);
    });

    test('线段终点在圆内时命中', () {
      final hit = segmentHitsCircle(
        center: const Offset(200, 200),
        radius: 11,
        from: const Offset(200, 160),
        to: const Offset(200, 205),
      );
      expect(hit, isTrue);
    });

    test('零长度线段按点与圆判断', () {
      expect(
        segmentHitsCircle(
          center: const Offset(100, 100),
          radius: 5,
          from: const Offset(103, 100),
          to: const Offset(103, 100),
        ),
        isTrue,
      );
      expect(
        segmentHitsCircle(
          center: const Offset(100, 100),
          radius: 5,
          from: const Offset(120, 100),
          to: const Offset(120, 100),
        ),
        isFalse,
      );
    });

    test('圆形重叠包含边界', () {
      expect(
        circlesOverlap(const Offset(0, 0), 10, const Offset(15, 0), 5),
        isTrue,
      );
      expect(
        circlesOverlap(const Offset(0, 0), 10, const Offset(15.1, 0), 5),
        isFalse,
      );
    });

    test('扫掠起点按速度回推', () {
      final start = sweepStart(
        position: const Offset(200, 100),
        velocity: const Offset(0, -600),
        dt: 1 / 60,
      );
      expect(start.dx, 200);
      expect(start.dy, closeTo(110, 0.0001));
    });
  });
}
