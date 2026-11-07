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

    test('裸坐标版本与 Offset 版本结果一致', () {
      const cases = [
        (Offset(200, 200), 11.0, Offset(200, 240), Offset(200, 160)),
        (Offset(200, 200), 11.0, Offset(230, 240), Offset(230, 160)),
        (Offset(100, 100), 5.0, Offset(103, 100), Offset(103, 100)),
        (Offset(50, 400), 8.0, Offset(80, 380), Offset(20, 460)),
      ];
      for (final (center, radius, from, to) in cases) {
        expect(
          segmentHitsCircleXY(
            centerX: center.dx,
            centerY: center.dy,
            radius: radius,
            fromX: from.dx,
            fromY: from.dy,
            toX: to.dx,
            toY: to.dy,
          ),
          segmentHitsCircle(center: center, radius: radius, from: from, to: to),
        );
      }
    });

    test('裸坐标圆形重叠与判定顺序无关', () {
      expect(circlesOverlapXY(0, 0, 10, 15, 0, 5), isTrue);
      expect(circlesOverlapXY(15, 0, 5, 0, 0, 10), isTrue);
      expect(circlesOverlapXY(0, 0, 10, 15.1, 0, 5), isFalse);
      expect(
        circlesOverlapXY(0, 0, 10, 15, 0, 5),
        circlesOverlap(const Offset(0, 0), 10, const Offset(15, 0), 5),
      );
    });
  });
}
