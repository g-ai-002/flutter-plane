import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';

/// SoLoud 引擎入口：音效与背景音乐共用一次初始化。
///
/// 启动期两个服务可能同时准备音频，之前各自判断 `isInitialized` 再 `init()`，
/// 存在重复初始化与竞态；集中到这里后只保留一个进行中的初始化任务。
class AudioEngine {
  AudioEngine._();

  static Future<void>? _initializing;

  static SoLoud get _soloud => SoLoud.instance;

  static Future<void> ensureInitialized() async {
    if (_soloud.isInitialized) return;
    final pending = _initializing;
    if (pending != null) return pending;
    final future = _soloud.init();
    _initializing = future;
    try {
      await future;
    } catch (_) {
      // 初始化失败时释放占位，下一次播放仍可重试。
      _initializing = null;
      rethrow;
    }
  }

  /// 装载运行时合成的内存音源，仓库不携带任何音频文件。
  static Future<AudioSource> loadMem(String name, Uint8List bytes) =>
      _soloud.loadMem(name, bytes);
}
