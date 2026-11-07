/// 全局时间与数字格式化工具。
library;

String pad2(int value) => value.toString().padLeft(2, '0');

/// `yyyyMMdd`，用于日志文件名。
String formatDateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}${pad2(date.month)}${pad2(date.day)}';

/// `yyyy-MM-dd HH:mm`。
String formatDateTime(DateTime time) =>
    '${time.year.toString().padLeft(4, '0')}-${pad2(time.month)}-${pad2(time.day)} '
    '${pad2(time.hour)}:${pad2(time.minute)}';

/// `HH:mm:ss.SSS`，日志行首时间戳。
String formatLogTimestamp(DateTime time) =>
    '${pad2(time.hour)}:${pad2(time.minute)}:${pad2(time.second)}.'
    '${time.millisecond.toString().padLeft(3, '0')}';

String formatLogLine(DateTime time, String level, String message) =>
    '[${formatLogTimestamp(time)}][$level] $message';

/// 得分千分位：`12,345`。
String formatScore(int score) {
  final text = score.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
    buffer.write(text[i]);
  }
  return '${score < 0 ? '-' : ''}$buffer';
}

/// 存活时长：`mm:ss`。
String formatDuration(Duration duration) {
  final total = duration.inSeconds;
  return '${pad2(total ~/ 60)}:${pad2(total % 60)}';
}
