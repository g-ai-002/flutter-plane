import 'dart:ui';

/// 圆形碰撞与扫掠检测。
///
/// 弹道每帧位移可能远大于敌机半径，因此玩家弹与敌弹都按「上一帧位置到
/// 当前位置」的线段做扫掠检测，低刷新率下也不会穿透。
///
/// 战斗循环每帧要跑成百上千次检测，[segmentHitsCircleXY] 与
/// [circlesOverlapXY] 直接收裸坐标，避免为每一对实体构造 Offset。

/// 判断线段 [from] → [to] 是否与圆相交。
bool segmentHitsCircle({
  required Offset center,
  required double radius,
  required Offset from,
  required Offset to,
}) => segmentHitsCircleXY(
  centerX: center.dx,
  centerY: center.dy,
  radius: radius,
  fromX: from.dx,
  fromY: from.dy,
  toX: to.dx,
  toY: to.dy,
);

/// 判断线段 (fromX, fromY) → (toX, toY) 是否与圆相交。
bool segmentHitsCircleXY({
  required double centerX,
  required double centerY,
  required double radius,
  required double fromX,
  required double fromY,
  required double toX,
  required double toY,
}) {
  final dx = toX - fromX;
  final dy = toY - fromY;
  final lengthSq = dx * dx + dy * dy;
  final ox = centerX - fromX;
  final oy = centerY - fromY;
  var t = 0.0;
  if (lengthSq > 0.0001) {
    t = (ox * dx + oy * dy) / lengthSq;
    if (t < 0) {
      t = 0;
    } else if (t > 1) {
      t = 1;
    }
  }
  final cx = ox - dx * t;
  final cy = oy - dy * t;
  return cx * cx + cy * cy <= radius * radius;
}

/// 两个圆是否重叠。
bool circlesOverlap(Offset a, double radiusA, Offset b, double radiusB) =>
    circlesOverlapXY(a.dx, a.dy, radiusA, b.dx, b.dy, radiusB);

/// 两个圆是否重叠，坐标直接传入以避免临时 Offset。
bool circlesOverlapXY(
  double ax,
  double ay,
  double radiusA,
  double bx,
  double by,
  double radiusB,
) {
  final dx = ax - bx;
  final dy = ay - by;
  final radius = radiusA + radiusB;
  return dx * dx + dy * dy <= radius * radius;
}

/// 子弹上一帧到当前帧的扫掠线段。
Offset sweepStart({
  required Offset position,
  required Offset velocity,
  required double dt,
}) => position - velocity * dt;

/// 带包围盒预筛的扫掠检测：线段包围盒都碰不到圆时直接返回 false。
///
/// 弹幕密集时绝大多数子弹离目标很远，先做四次比较可以省掉线段投影。
bool sweepHitsCircleXY({
  required double centerX,
  required double centerY,
  required double reach,
  required double fromX,
  required double fromY,
  required double toX,
  required double toY,
}) {
  if (centerX + reach < (fromX < toX ? fromX : toX) ||
      centerX - reach > (fromX > toX ? fromX : toX) ||
      centerY + reach < (fromY < toY ? fromY : toY) ||
      centerY - reach > (fromY > toY ? fromY : toY)) {
    return false;
  }
  return segmentHitsCircleXY(
    centerX: centerX,
    centerY: centerY,
    radius: reach,
    fromX: fromX,
    fromY: fromY,
    toX: toX,
    toY: toY,
  );
}
