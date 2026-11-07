import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sky_fighter/services/log_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LogService', () {
    late Directory tempDir;

    setUp(() async {
      LogService.reset();
      tempDir = await Directory.systemTemp.createTemp('skyfighter_log_test');
    });

    tearDown(() async {
      LogService.reset();
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('按天写入日志文件', () async {
      final clock = DateTime(2026, 11, 7, 21, 30);
      await LogService.init(logRoot: () async => tempDir, clock: () => clock);

      LogService.info('开始战斗');
      LogService.warning('低帧率');
      LogService.error('异常', StateError('boom'), StackTrace.current);

      final file = File('${tempDir.path}/app_20261107.log');
      expect(await file.exists(), isTrue);
      final content = await file.readAsString();
      expect(content, contains('[21:30:00.000][INFO] 开始战斗'));
      expect(content, contains('[WARN] 低帧率'));
      expect(content, contains('Bad state: boom'));
      expect(LogService.logFilePath, file.path);
      expect(LogService.getRecentLogs().length, greaterThanOrEqualTo(4));
    });

    test('初始化前的日志在初始化后补写', () async {
      LogService.info('早期日志');
      await LogService.init(logRoot: () async => tempDir);
      LogService.info('之后的日志');

      final files = tempDir.listSync().whereType<File>().toList();
      expect(files, isNotEmpty);
      final content = await files.first.readAsString();
      expect(content, contains('早期日志'));
      expect(content, contains('之后的日志'));
    });

    test('目录不可用时降级为内存日志', () async {
      await LogService.init(
        logRoot: () async => throw const FileSystemException('不可写'),
      );
      LogService.info('内存中的日志');
      expect(LogService.logFilePath, '');
      expect(LogService.getRecentLogs().last, contains('内存中的日志'));
    });

    test('最近日志按行数截取', () async {
      await LogService.init(logRoot: () async => tempDir);
      for (var i = 0; i < 30; i++) {
        LogService.info('第 $i 行');
      }
      final recent = LogService.getRecentLogs(5);
      expect(recent.length, 5);
      expect(recent.last, contains('第 29 行'));
    });
  });
}
