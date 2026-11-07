/// Web 端没有可用的 isolate，退回当前线程执行合成。
Future<T> runSynth<T>(T Function() task) async => task();
