/// Web 端字体：CanvasKit 没有系统中文字体回退，使用 soup_fonts 的思源黑体。
const String kWebFontFamily = 'SourceHanSansCN';

class AppConstants {
  AppConstants._();

  static const String appName = '苍穹战机';
  static const String version = '0.2.2';
  static const String tagline = '竖版弹幕射击 · 本地单机';

  static const String prefKeyDarkMode = 'dark_mode';
  static const String prefKeySound = 'sound_enabled';
  static const String prefKeyMusic = 'music_enabled';
  static const String prefKeyHaptics = 'haptics_enabled';
  static const String prefKeyLogicRate = 'logic_rate';
  static const String prefKeyHighScore = 'high_score';
  static const String prefKeyBestWave = 'best_wave';
  static const String prefKeyRuns = 'runs';
}
