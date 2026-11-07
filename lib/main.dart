import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'services/log_service.dart';
import 'services/logging_init.dart';
import 'services/music_service.dart';
import 'services/sound_service.dart';
import 'services/storage_service.dart';
import 'utils/constants.dart';
import 'utils/window_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    LogService.error('Flutter 异常', details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    LogService.error('未捕获异常', error, stack);
    return true;
  };

  // 窗口、日志与本地存储互不依赖，三者并行初始化以缩短冷启动；
  // LogService 会把初始化前的日志暂存，稍后补写。
  final startup = await Future.wait<Object?>([
    setupDesktopWindow(),
    initLogging(),
    StorageService.instance,
  ]);
  final storage = startup[2]! as StorageService;
  LogService.info('应用启动: ${AppConstants.appName} v${AppConstants.version}');
  unawaited(SoundService.init());
  MusicService.enabled = storage.musicEnabled;
  // Web 需要用户手势才能播放，首次点击页面时由 App 的监听器启动。
  if (storage.musicEnabled && !kIsWeb) unawaited(MusicService.start());

  runApp(SkyFighterApp(storage: storage));
}
