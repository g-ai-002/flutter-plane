import 'package:flutter/foundation.dart';

import 'constants.dart';

/// 各平台优先使用的中文字体：Windows 使用微软雅黑，Web 使用思源黑体，
/// Android 交给系统默认字体，与主题保持一致。
String? appFontFamily() {
  if (kIsWeb) return kWebFontFamily;
  if (defaultTargetPlatform == TargetPlatform.windows) {
    return 'Microsoft YaHei UI';
  }
  return null;
}
