# 苍穹战机

经典竖版飞机大战：拖动战机躲避弹幕、自动开火、击破编队与 Boss，在连击倍率中冲刺最高分。
覆盖 **Android / Windows / Web**，完全本地运行，无需联网。

- 🎮 在线试玩：<http://192.168.31.120:8040/GTech/flutter-plane/>
- ⬇️ 下载 Android APK / Windows ZIP：<http://192.168.31.120:3020/GTech/flutter-plane/releases/tag/v0.1.2>

## 特色

- **完整战斗循环**：五级弹道光束、护盾、全屏炸弹、连击倍率（最高 ×4）与波次递增难度。
- **四类敌机 + Boss**：侦察机、战斗机、轰炸机、精英机各有移动与开火方式；每 4 波迎战 Boss 母舰，
  四种弹幕循环并带独立血条。
- **纯粹的程序化视听**：星空、战机、弹幕、爆炸全部用 Canvas 矢量绘制；九种音效与 8 秒电子循环
  背景音乐在运行时合成，仓库不存放图片、字体与音频文件。
- **自适应战场**：竖屏手机、折叠屏、平板与桌面窗口自动选择战场比例；HUD 悬浮在战场四周，
  提示变化不会挤压战场。
- **批绘制与对象池**：星空、粒子与弹幕按颜色分桶合并绘制，粒子对象回收复用；
  240 颗弹幕的三层外观只需 12 次以内的绘制调用，密集弹幕下帧率更稳。
- **可调逻辑刷新率**：30Hz 省电 / 60Hz 均衡 / 120Hz 顺滑（默认 60Hz），固定步长推进，
  低帧率下也不会出现子弹穿透。
- **本地记录**：最高分、最远波次与出击次数自动保存；日志按天写入用户目录，方便排查问题。

## 操作

| 平台 | 移动 | 炸弹 | 暂停 |
| --- | --- | --- | --- |
| 手机 / 平板 | 拖动屏幕 | 点击右下角炸弹按钮 | 右上角暂停按钮 |
| Windows / Web | 拖动鼠标，或方向键 / WASD | 空格 / B，或点击炸弹按钮 | Esc / P，或点击暂停按钮 |

自动开火，无需点击射击。

## 玩法

1. 击破敌机累积连击，12 / 30 / 60 连击分别提升分数倍率，停火 2.6 秒后连击归零。
2. 拾取补给：**火力**（提升弹道等级）、**护盾**（抵挡一次伤害）、**炸弹**（补充全屏炸弹）、
   **分数**（直接加分）。
3. 每 4 波出现 Boss 母舰；击破后掉落三份补给。
4. 生命耗尽即战斗结束，最高分与本局波次自动保存。

## 技术栈

- Flutter 3.47.9 + Flame 1.38.2
- 状态：Provider；本地存储：shared_preferences
- 音频：flutter_soloud（播放运行时合成的 WAV）
- 桌面窗口：window_manager；Web 中文字体：soup_fonts

## 开发

```shell
flutter pub get
flutter analyze
flutter test

# 运行（Windows / Web）
flutter run -d windows
flutter run -d chrome
```

当前包含 141 项单元与组件测试，覆盖战斗流程、弹道、碰撞、特效、批绘制、波次与三端界面。

Android 配置：`minSdk=35`、`targetSdk=37`、`compileSdk=37`，仅构建 `arm64-v8a`。
Windows 与 Web 平台文件由 CI 在构建时生成，仓库不存放 `windows/`、`web/` 目录。

### 目录结构

```
lib/
  app.dart / main.dart          应用入口与主题、生命周期
  flame/                        Flame 游戏、战场渲染、批绘制与敌机视觉表
  game/battle/                  战斗逻辑：实体、波次、弹道、移动、碰撞、特效
  game/logic_rate.dart          30/60/120Hz 逻辑速率与固定步长
  pages/                        首页、战斗页、设置页与悬浮 HUD
  providers/                    用户偏好
  services/                     日志、存储、音效合成、音乐
  theme/ utils/                 主题、常量、格式化、窗口与全屏
test/                           单元测试与组件测试
.github / .gitea                GitHub / Gitea 构建发布流水线
```

### 日志位置

- Windows：`%USERPROFILE%\Documents\FlutterSkyFighter\logs\app_yyyyMMdd.log`
- Android：应用外部存储目录下的 `FlutterSkyFighter/logs/`
- Web：仅保留内存日志，可在设置页查看

日志按天滚动，保留 7 天，单个文件超过 5MB 自动轮转。

## 构建与发布

构建全部在 CI 完成。推送 Tag 不会自动出包，需要在 Actions 中手动运行 `build.yml` 并选定该 Tag：

```shell
git tag -a v0.1.2 -m "v0.1.2: 批绘制与碰撞热路径优化"
git push origin v0.1.2
tea actions workflows dispatch build.yml --ref refs/tags/v0.1.2 --follow
```

产物包含 Android APK（aarch64）、Windows ZIP（x86_64）与 Web 压缩包，并发布到 Releases 与 Pages。

## 版本

| 版本 | 说明 |
| --- | --- |
| v0.1.2 | 性能版本：弹幕/粒子/星空批绘制、粒子对象池、碰撞预筛，玩法不变 |
| v0.1.1 | 重构版本：拆分战斗模块、弹道与敌机配置化、渲染查表，玩法不变 |
| v0.1.0 | 首个可玩版本：完整弹幕战斗、四类敌机与 Boss、程序化音画、三端发布 |
