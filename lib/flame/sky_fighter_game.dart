import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/battle/battle_controller.dart';
import '../game/logic_rate.dart';
import 'battle_field_component.dart';

/// Flame 游戏入口：单个战场组件负责固定步长逻辑与矢量渲染。
class SkyFighterGame extends FlameGame {
  SkyFighterGame({
    required this.controller,
    required this.logicRate,
    this.fontFamily,
  });

  final BattleController controller;

  /// Canvas 内文字（连击飘字、补给标签）使用的字体。
  final String? fontFamily;

  /// 弹道逻辑更新速率，见 [LogicRate]。
  final LogicRate logicRate;

  BattleFieldComponent? _field;

  @override
  Color backgroundColor() => const Color(0xFF05070F);

  @override
  Future<void> onLoad() async {
    final field = BattleFieldComponent(
      controller: controller,
      logicRate: logicRate,
      fontFamily: fontFamily,
    );
    field.size = Vector2(size.x, size.y);
    _field = field;
    await add(field);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final field = _field;
    if (field == null) return;
    field
      ..size = Vector2(size.x, size.y)
      ..position = Vector2.zero();
  }
}
