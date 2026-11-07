import 'dart:isolate';

/// 在后台 isolate 执行纯计算合成任务。
///
/// 音效与背景音乐都是数十万个采样点的函数计算，放在主线程会在启动阶段
/// 抢占帧预算；投递到 isolate 后主线程只负责把结果交给音频引擎。
Future<T> runSynth<T>(T Function() task) => Isolate.run(task);
