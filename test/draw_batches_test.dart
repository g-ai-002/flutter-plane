import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/flame/draw_batches.dart';

/// 只记录批绘制的画布：其余 Canvas 方法一律忽略。
class RecordingCanvas implements Canvas {
  final List<RawPointsCall> calls = [];

  @override
  void drawRawPoints(PointMode mode, Float32List points, Paint paint) {
    calls.add(
      RawPointsCall(
        mode: mode,
        points: List<double>.of(points),
        color: paint.color,
        strokeWidth: paint.strokeWidth,
        strokeCap: paint.strokeCap,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class RawPointsCall {
  RawPointsCall({
    required this.mode,
    required this.points,
    required this.color,
    required this.strokeWidth,
    required this.strokeCap,
  });

  final PointMode mode;
  final List<double> points;
  final Color color;
  final double strokeWidth;
  final StrokeCap strokeCap;

  int get pointCount => points.length ~/ 2;
}

void main() {
  group('圆点批绘制', () {
    test('同色同径的圆点合并为一次绘制', () {
      final batch = DotBatch();
      final canvas = RecordingCanvas();

      for (var i = 0; i < 120; i++) {
        batch.add(0xFFFFD54F, i.toDouble(), 40, 3, 1);
      }
      batch.flush(canvas);

      expect(canvas.calls, hasLength(1));
      final call = canvas.calls.single;
      expect(call.mode, PointMode.points);
      expect(call.pointCount, 120);
      expect(call.strokeWidth, 6);
      expect(call.strokeCap, StrokeCap.round);
      expect(call.color.toARGB32(), 0xFFFFD54F);
      expect(call.points[0], 0);
      expect(call.points[1], 40);
      expect(call.points[238], 119);
    });

    test('半径按 0.5 像素分桶，颜色不同各自成桶', () {
      final batch = DotBatch();
      final canvas = RecordingCanvas();

      batch.add(0xFFFF0000, 10, 10, 3.0, 1);
      batch.add(0xFFFF0000, 20, 10, 3.1, 1);
      batch.add(0xFFFF0000, 30, 10, 4.2, 1);
      batch.add(0xFF00FF00, 40, 10, 3.0, 1);
      batch.flush(canvas);

      expect(canvas.calls, hasLength(3));
      expect(
        canvas.calls.map((call) => call.pointCount).reduce((a, b) => a + b),
        4,
      );
    });

    test('透明度量化到 8 档并叠加原始 alpha', () {
      final batch = DotBatch();
      final canvas = RecordingCanvas();

      batch.add(0xFFFFFFFF, 10, 10, 1.0, 1);
      batch.add(0xFFFFFFFF, 20, 10, 1, 0.99);
      batch.flush(canvas);
      expect(canvas.calls, hasLength(1));
      expect(canvas.calls.single.color.a, closeTo(1, 0.01));

      final faded = RecordingCanvas();
      batch.add(0xFFFFFFFF, 10, 10, 1.0, 1);
      batch.add(0xFFFFFFFF, 20, 10, 1, 0.5);
      batch.flush(faded);
      expect(faded.calls, hasLength(2));
      final low = faded.calls.reduce((a, b) => a.color.a < b.color.a ? a : b);
      expect(low.color.a, closeTo(0.5, 0.01));
    });

    test('完全透明的点不进入绘制', () {
      final batch = DotBatch();
      final canvas = RecordingCanvas();

      batch.add(0xFFFFFFFF, 10, 10, 0.01, 1);
      batch.flush(canvas);

      expect(canvas.calls, isEmpty);
    });

    test('绘制后清空坐标，桶可继续复用', () {
      final batch = DotBatch();
      final canvas = RecordingCanvas();

      batch.add(0xFFFFFFFF, 10, 10, 1, 2);
      batch.flush(canvas);
      batch.flush(canvas);
      expect(canvas.calls, hasLength(1));

      batch.add(0xFFFFFFFF, 30, 30, 1, 2);
      batch.flush(canvas);
      expect(canvas.calls, hasLength(2));
      expect(canvas.calls.last.pointCount, 1);
    });

    test('大量点只扩张缓冲，不丢坐标', () {
      final batch = DotBatch();
      final canvas = RecordingCanvas();

      for (var i = 0; i < 5000; i++) {
        batch.add(0xFF123456, i * 0.5, i.toDouble(), 1, 1);
      }
      batch.flush(canvas);

      expect(canvas.calls.single.pointCount, 5000);
      expect(canvas.calls.single.points[9998], 2499.5);
    });
  });

  group('胶囊批绘制', () {
    test('同一胶囊的两端成对写入，圆头线段等价于子弹外形', () {
      final batch = CapsuleBatch();
      final canvas = RecordingCanvas();

      batch.add(0xFFB7F4FF, 50, 100, 4, 6, 1);
      batch.flush(canvas);

      final call = canvas.calls.single;
      expect(call.mode, PointMode.lines);
      expect(call.pointCount, 2);
      expect(call.points, [50, 96, 50, 104]);
      expect(call.strokeWidth, 6);
      expect(call.strokeCap, StrokeCap.round);
    });

    test('多颗子弹合并到一次绘制', () {
      final batch = CapsuleBatch();
      final canvas = RecordingCanvas();

      for (var i = 0; i < 30; i++) {
        batch.add(0xFFB7F4FF, i.toDouble(), 200, 4, 6, 1);
        batch.add(0xFFFFFFFF, i.toDouble(), 200, 2.9, 2.2, 1);
      }
      batch.flush(canvas);

      expect(canvas.calls, hasLength(2));
      expect(canvas.calls.first.pointCount, 60);
      expect(canvas.calls.last.pointCount, 60);
    });
  });
}
