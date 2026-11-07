/// 后台合成：把采样级音频生成放到主线程之外，按平台选择实现。
library;

export 'synth_worker_io.dart' if (dart.library.js_interop) 'synth_worker_web.dart';
