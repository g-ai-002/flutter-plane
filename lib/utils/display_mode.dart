import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 竖版弹幕射击需要尽可能高的画面，手机与折叠屏折叠态进入战斗时隐藏系统栏。
///
/// 战斗画面为竖屏，旋转横屏反而会把战场压成中间一条窄带，因此这里只做全屏
/// 沉浸而不改变方向；平板、桌面与 Web 保持系统默认外观。
bool shouldUseImmersiveFullscreen(Size size) =>
    !kIsWeb &&
    defaultTargetPlatform == TargetPlatform.android &&
    size.shortestSide < 600;

/// 沉浸式全屏作用域：进入时隐藏状态栏与导航栏，退出后恢复。
/// 多个页面叠放时按引用计数只在最后一个退出时恢复系统栏。
class ImmersiveFullscreen extends StatefulWidget {
  const ImmersiveFullscreen({super.key, required this.child});

  final Widget child;

  @override
  State<ImmersiveFullscreen> createState() => _ImmersiveFullscreenState();
}

class _ImmersiveFullscreenState extends State<ImmersiveFullscreen> {
  static int _holders = 0;

  bool _applied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final wanted = shouldUseImmersiveFullscreen(MediaQuery.sizeOf(context));
    if (wanted == _applied) return;
    _applied = wanted;
    if (wanted) {
      _holders++;
      if (_holders == 1) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    } else {
      _release();
    }
  }

  void _release() {
    if (_holders > 0) _holders--;
    if (_holders > 0) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    if (_applied) _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
