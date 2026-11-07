import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/game/logic_rate.dart';

void main() {
  group('LogicRate', () {
    test('三档速率与步长', () {
      expect(LogicRate.values.length, 3);
      expect(LogicRate.hz30.step, closeTo(1 / 30, 1e-9));
      expect(LogicRate.hz60.step, closeTo(1 / 60, 1e-9));
      expect(LogicRate.hz120.step, closeTo(1 / 120, 1e-9));
    });

    test('未知值回退到 60Hz', () {
      expect(LogicRate.byName(null), LogicRate.hz60);
      expect(LogicRate.byName('unknown'), LogicRate.hz60);
      expect(LogicRate.byName('hz120'), LogicRate.hz120);
    });
  });

  group('FixedStepClock', () {
    test('按固定步长折算逻辑步', () {
      final clock = FixedStepClock(1 / 60);
      final spans = <double>[];
      final steps = clock.advance(1 / 30, spans.add);
      expect(steps, 2);
      expect(spans.single, closeTo(2 / 60, 1e-9));
    });

    test('不足一步时不推进', () {
      final clock = FixedStepClock(1 / 60);
      var calls = 0;
      expect(clock.advance(0.005, (_) => calls++), 0);
      expect(calls, 0);
      expect(clock.advance(0.02, (_) => calls++), 1);
    });

    test('严重卡顿时丢弃积压，只推进上限步数', () {
      final clock = FixedStepClock(1 / 60, maxSteps: 4);
      final spans = <double>[];
      final steps = clock.advance(1, spans.add);
      expect(steps, 4);
      expect(spans.single, closeTo(4 / 60, 1e-9));
      expect(clock.advance(0.001, (_) {}), 0);
      expect(clock.advance(1 / 60, (_) {}), 1);
    });

    test('120Hz 每秒推进 120 步', () {
      final clock = FixedStepClock(1 / 120);
      var total = 0;
      for (var i = 0; i < 60; i++) {
        total += clock.advance(1 / 60, (_) {});
      }
      expect(total, 120);
    });
  });
}
