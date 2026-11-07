import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/utils/formatters.dart';

void main() {
  group('formatters', () {
    test('pad2 补零', () {
      expect(pad2(0), '00');
      expect(pad2(9), '09');
      expect(pad2(42), '42');
    });

    test('日期与时间格式化', () {
      final time = DateTime(2026, 1, 5, 8, 7, 3, 9);
      expect(formatDateKey(time), '20260105');
      expect(formatDateTime(time), '2026-01-05 08:07');
      expect(formatLogTimestamp(time), '08:07:03.009');
    });

    test('得分千分位', () {
      expect(formatScore(0), '0');
      expect(formatScore(999), '999');
      expect(formatScore(1000), '1,000');
      expect(formatScore(1234567), '1,234,567');
    });

    test('存活时长', () {
      expect(formatDuration(const Duration(seconds: 5)), '00:05');
      expect(formatDuration(const Duration(minutes: 12, seconds: 34)), '12:34');
    });
  });
}
