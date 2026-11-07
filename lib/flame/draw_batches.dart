import 'dart:typed_data';
import 'dart:ui';

/// 圆点与竖直线段的批绘制。
///
/// 弹幕密集时逐颗 `drawCircle` 会带来成百上千次绘制调用，粒子淡出还会每帧
/// 新建 Color 与 Paint。这里把坐标写进复用的 [Float32List]，按「颜色 +
/// 透明度档位 + 粗细」分桶，每桶只做一次 [Canvas.drawRawPoints]，绘制阶段
/// 只改一次 Paint，热路径上几乎不产生临时对象。
class DrawBatch {
  DrawBatch.points() : _mode = PointMode.points;

  DrawBatch.lines() : _mode = PointMode.lines;

  /// 透明度量化档位：8 档肉眼几乎无差，却能把粒子合并到少数几个桶。
  static const int _alphaLevels = 8;

  /// 粗细量化精度：0.5 逻辑像素一档。
  static const int _widthScale = 2;
  static const int _widthKeys = 256;

  final PointMode _mode;
  final Map<int, _Bucket> _buckets = {};
  final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;

  /// 添加一个点（线段模式下两点成对，由 [CapsuleBatch] 保证）。
  ///
  /// [argb] 的高 8 位是原始透明度，[alpha] 再叠加一层衰减系数。
  void add(int argb, double x, double y, double alpha, double width) {
    if (alpha <= 0.02 || width <= 0.2) return;
    final level = ((alpha > 1 ? 1 : alpha) * _alphaLevels).round();
    if (level <= 0) return;
    final steps = level > _alphaLevels ? _alphaLevels : level;
    final sourceAlpha = (argb >> 24) & 0xFF;
    final alphaByte = sourceAlpha * steps ~/ _alphaLevels;
    if (alphaByte <= 0) return;
    final color = (argb & 0x00FFFFFF) | (alphaByte << 24);
    final widthKey = (width * _widthScale).round().clamp(1, _widthKeys);
    final bucket = _buckets[color * 257 + widthKey] ??= _Bucket(
      Color(color),
      widthKey / _widthScale,
    );
    bucket.add(x, y);
  }

  /// 绘制本批已收集的点，并清空各桶坐标，桶本身保留给下一帧复用。
  void flush(Canvas canvas) {
    if (_buckets.isEmpty) return;
    for (final bucket in _buckets.values) {
      if (bucket.length == 0) continue;
      _paint
        ..color = bucket.color
        ..strokeWidth = bucket.width;
      canvas.drawRawPoints(_mode, bucket.view, _paint);
      bucket.length = 0;
    }
  }
}

/// 圆点批绘制：入参是半径，内部换算成 `drawRawPoints` 的线宽。
class DotBatch {
  final DrawBatch _batch = DrawBatch.points();

  void add(int argb, double x, double y, double radius, double alpha) =>
      _batch.add(argb, x, y, alpha, radius * 2);

  void flush(Canvas canvas) => _batch.flush(canvas);
}

/// 竖直线段批绘制：圆头线段等价于胶囊，用来替代逐颗旋转的 RRect。
class CapsuleBatch {
  final DrawBatch _batch = DrawBatch.lines();

  void add(
    int argb,
    double x,
    double centerY,
    double halfLength,
    double width,
    double alpha,
  ) {
    _batch.add(argb, x, centerY - halfLength, alpha, width);
    _batch.add(argb, x, centerY + halfLength, alpha, width);
  }

  void flush(Canvas canvas) => _batch.flush(canvas);
}

/// 单个分桶的坐标缓冲：容量按需翻倍，避免每帧重新分配列表。
class _Bucket {
  _Bucket(this.color, this.width);

  final Color color;
  final double width;
  Float32List _data = Float32List(64);
  int length = 0;

  void add(double x, double y) {
    if (length + 2 > _data.length) {
      final grown = Float32List(_data.length * 2);
      grown.setRange(0, length, _data);
      _data = grown;
    }
    _data[length++] = x;
    _data[length++] = y;
  }

  Float32List get view => Float32List.sublistView(_data, 0, length);
}
