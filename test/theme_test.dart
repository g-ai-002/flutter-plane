import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/theme/app_theme.dart';
import 'package:sky_fighter/utils/display_mode.dart';

void main() {
  group('主题', () {
    test('浅色与深色主题均使用 Material 3', () {
      final light = buildLightTheme();
      final dark = buildDarkTheme(fontFamily: 'TestFont');
      expect(light.useMaterial3, isTrue);
      expect(light.colorScheme.brightness, Brightness.light);
      expect(dark.colorScheme.brightness, Brightness.dark);
      expect(dark.textTheme.bodyMedium?.fontFamily, 'TestFont');
      expect(light.colorScheme.primary, const Color(0xFF0E63B8));
      expect(dark.colorScheme.primary, const Color(0xFF57D6FF));
    });

    test('卡片与按钮风格统一', () {
      final theme = buildLightTheme();
      expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
      expect(theme.appBarTheme.centerTitle, isTrue);
      expect(
        theme.filledButtonTheme.style?.minimumSize?.resolve({}),
        isNotNull,
      );
    });
  });

  group('沉浸式全屏', () {
    test('手机与折叠屏启用沉浸式全屏', () {
      expect(shouldUseImmersiveFullscreen(const Size(390, 844)), isTrue);
      expect(shouldUseImmersiveFullscreen(const Size(340, 900)), isTrue);
    });

    test('平板与桌面不改变系统栏', () {
      expect(shouldUseImmersiveFullscreen(const Size(800, 1280)), isFalse);
      expect(shouldUseImmersiveFullscreen(const Size(1440, 900)), isFalse);
    });
  });
}
