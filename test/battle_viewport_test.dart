import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/game/battle/battle_types.dart';
import 'package:sky_fighter/game/battle/battle_viewport.dart';

void main() {
  group('BattleViewport', () {
    test('竖屏手机铺满可用空间', () {
      final field = BattleViewport.fit(const Size(400, 800));
      expect(field.width, closeTo(400, 1e-6));
      expect(field.height, closeTo(800, 1e-6));
      expect(field.left, 0);
      expect(field.top, 0);
    });

    test('超宽窗口限制最大宽高比并居中', () {
      final field = BattleViewport.fit(const Size(1600, 800));
      expect(field.height, closeTo(800, 1e-6));
      expect(field.width, closeTo(800 * BattleViewport.maxAspect, 1e-6));
      expect(field.center.dx, closeTo(800, 1e-6));
      expect(field.top, 0);
    });

    test('极高窗口限制最小宽高比', () {
      final field = BattleViewport.fit(const Size(300, 900));
      expect(field.width, closeTo(300, 1e-6));
      expect(field.height, closeTo(300 / BattleViewport.minAspect, 1e-6));
      expect(field.center.dy, closeTo(450, 1e-6));
    });

    test('世界坐标宽度固定，高度随战场比例变化', () {
      final world = BattleViewport.worldSize(const Size(400, 800));
      expect(world.width, kWorldWidth);
      expect(world.height, closeTo(800, 1e-6));
    });

    test('无效尺寸返回空矩形', () {
      expect(BattleViewport.fit(Size.zero), Rect.zero);
    });
  });
}
