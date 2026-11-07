import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/game/ship_geometry.dart';

void main() {
  group('战机轮廓', () {
    test('玩家机体尺寸稳定', () {
      final bounds = playerHullPath.getBounds();
      expect(bounds.width, 28);
      expect(bounds.height, 29);
      expect(bounds.center.dx, closeTo(0, 0.001));
    });

    test('僚机轮廓比主机更小且居中', () {
      final wing = wingmanHullPath.getBounds();
      expect(wing.width, 13);
      expect(wing.height, 15);
      expect(wing.width, lessThan(playerHullPath.getBounds().width));
    });
  });
}
