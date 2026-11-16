import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 依赖约束只接受精确版本，禁止 ^、~、>、< 之类的范围写法。
final RegExp _exactVersion = RegExp(r'^\d+\.\d+\.\d+([-+][0-9A-Za-z.\-+]*)?$');

List<String> _pubspecLines() => File('pubspec.yaml').readAsLinesSync();

/// 读取 pubspec 中某个顶层配置块里的二级键值，忽略注释与空行。
Map<String, String> _section(String name) {
  final lines = _pubspecLines();
  final result = <String, String>{};
  var inside = false;
  for (final line in lines) {
    if (line.startsWith('$name:')) {
      inside = true;
      continue;
    }
    if (!inside) continue;
    if (line.isNotEmpty && !line.startsWith(' ')) break;
    final match = RegExp(r'^  ([\w-]+):\s*(\S*)\s*$').firstMatch(line);
    if (match != null) result[match.group(1)!] = match.group(2)!;
  }
  return result;
}

void main() {
  group('项目配置', () {
    test('第三方依赖全部使用固定版本号', () {
      final dependencies = _section('dependencies');
      final devDependencies = _section('dev_dependencies');
      expect(dependencies, isNotEmpty);
      expect(devDependencies, isNotEmpty);

      final ranged = <String>[];
      for (final entry in {...dependencies, ...devDependencies}.entries) {
        final version = entry.value;
        // sdk 依赖写的是 `flutter` 之类的来源名，没有版本约束。
        if (version.isEmpty || version == 'flutter') continue;
        if (!_exactVersion.hasMatch(version)) {
          ranged.add('${entry.key}: $version');
        }
      }
      expect(ranged, isEmpty, reason: '以下依赖不是固定版本号: ${ranged.join(', ')}');
    });

    test('关闭 Xiph 解码器，构建期不再下载预编译库', () {
      final lines = _pubspecLines();
      final start = lines.indexWhere((line) => line.startsWith('hooks:'));
      expect(start, isNonNegative, reason: 'pubspec 缺少 hooks 配置');

      final hooks = lines.skip(start).join('\n');
      expect(
        RegExp(r'^\s+no_xiph_libs:\s*true\s*$', multiLine: true).hasMatch(hooks),
        isTrue,
        reason: '音效只用运行时合成的 WAV，需保持 no_xiph_libs: true',
      );
      expect(
        RegExp(r'^\s+enable_vst3:\s*true\s*$', multiLine: true).hasMatch(hooks),
        isFalse,
        reason: 'VST3 托管默认关闭，避免引入第三方插件与额外构建依赖',
      );
    });
  });
}
