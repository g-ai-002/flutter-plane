import 'dart:math' as math;
import 'dart:ui';

import 'battle_types.dart';

/// 战场视口：在任意窗口比例下算出居中、可玩性一致的竖版战场。
///
/// 战场高度始终铺满可用高度：手机 20:9 等超高屏幕的上下不会留出黑边，
/// 世界高度随屏幕比例增长；宽屏只限制最大宽高比，两侧留给悬浮 HUD。
class BattleViewport {
  BattleViewport._();

  static const double maxAspect = 0.78;

  /// 无效尺寸时兜底的世界宽高比，取常见手机竖屏的 1:2。
  static const double fallbackAspect = 0.5;

  static Rect fit(Size available) {
    if (available.width <= 0 || available.height <= 0) {
      return Rect.zero;
    }
    final width = math.min(available.width, available.height * maxAspect);
    return Rect.fromLTWH(
      (available.width - width) / 2,
      0,
      width,
      available.height,
    );
  }

  /// 战场是否铺满舞台：满屏时不画外框，避免屏幕边缘出现描边与圆角。
  static bool fillsStage(Rect field, Size stage) =>
      field.width >= stage.width - 0.5 && field.height >= stage.height - 0.5;

  /// 渲染用的世界尺寸：宽度固定 [kWorldWidth]，高度随战场比例变化。
  static Size worldSize(Size playfield) {
    if (playfield.width <= 0 || playfield.height <= 0) {
      return const Size(kWorldWidth, kWorldWidth / fallbackAspect);
    }
    return Size(kWorldWidth, kWorldWidth * playfield.height / playfield.width);
  }
}
