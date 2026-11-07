import 'dart:ui';

import 'battle_types.dart';

/// 战场视口：在任意窗口比例下算出居中、可玩性一致的竖版战场。
///
/// 战场宽高比限制在 [minAspect, maxAspect] 之间：窄屏手机铺满全屏，
/// 桌面与平板居中显示竖版战场，两侧留给悬浮 HUD，不拉伸弹道比例。
class BattleViewport {
  BattleViewport._();

  static const double minAspect = 0.5;
  static const double maxAspect = 0.78;

  static Rect fit(Size available) {
    if (available.width <= 0 || available.height <= 0) {
      return Rect.zero;
    }
    var width = available.width;
    var height = available.height;
    final aspect = width / height;
    if (aspect > maxAspect) {
      width = height * maxAspect;
    } else if (aspect < minAspect) {
      height = width / minAspect;
    }
    return Rect.fromCenter(
      center: Offset(available.width / 2, available.height / 2),
      width: width,
      height: height,
    );
  }

  /// 渲染用的世界尺寸：宽度固定 [kWorldWidth]，高度随战场比例变化。
  static Size worldSize(Size playfield) {
    if (playfield.width <= 0 || playfield.height <= 0) {
      return const Size(kWorldWidth, kWorldWidth / minAspect);
    }
    return Size(kWorldWidth, kWorldWidth * playfield.height / playfield.width);
  }
}
