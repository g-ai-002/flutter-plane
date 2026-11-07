import 'dart:ui';

/// 圆形碰撞与扫掠检测。
///
/// 弹道每帧位移可能远大于敌机半径，因此玩家弹与敌弹都按「上一帧位置到
/// 当前位置」的线段做扫掠检测，低刷新率下也不会穿透。

/// 判断线段 [from] → [to] 是否与圆相交。
bool segmentHitsCircle({
  required Offset center,
  required double radius,
  required Offset from,
  required Offset to,
}) {
  final delta = to - from;
  final lengthSq = delta.distanceSquared;
  final offset = center - from;
  var t = 0.0;
  if (lengthSq > 0.0001) {
    t = (offset.dx * delta.dx + offset.dy * delta.dy) / lengthSq;
    t = t.clamp(0.0, 1.0);
  }
  final closest = from + delta * t;
  return (center - closest).distanceSquared <= radius * radius;
}

/// 两个圆是否重叠。
bool circlesOverlap(Offset a, double radiusA, Offset b, double radiusB) {
  final radius = radiusA + radiusB;
  return (a - b).distanceSquared <= radius * radius;
}

/// 子弹上一帧到当前帧的扫掠线段。
Offset sweepStart({
  required Offset position,
  required Offset velocity,
  required double dt,
}) => position - velocity * dt;
