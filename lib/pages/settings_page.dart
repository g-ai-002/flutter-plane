import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../game/logic_rate.dart';
import '../providers/settings_provider.dart';
import '../services/file_system_service.dart';
import '../services/log_service.dart';
import '../services/sound_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'widgets/page_shell.dart';
import 'widgets/stat_text.dart';
import 'widgets/surface_panel.dart';

Future<void> openSettingsPage(BuildContext context) {
  return Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    return PageShell(
      title: '设置',
      children: [
        _Section(
          title: '画面与性能',
          icon: Icons.tune_rounded,
          children: [
            _LogicRatePicker(settings: settings),
            const SizedBox(height: 6),
            _SwitchRow(
              title: '深色模式',
              subtitle: '夜间与低光环境下更柔和',
              value: settings.darkMode,
              onChanged: settings.setDarkMode,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          title: '声音与反馈',
          icon: Icons.volume_up_outlined,
          children: [
            _SwitchRow(
              title: '音效',
              subtitle: '射击、爆炸与拾取提示音',
              value: settings.soundEnabled,
              onChanged: settings.setSoundEnabled,
            ),
            _SwitchRow(
              title: '背景音乐',
              subtitle: '运行时合成的电子循环音乐',
              value: settings.musicEnabled,
              onChanged: settings.setMusicEnabled,
            ),
            _SwitchRow(
              title: '震动反馈',
              subtitle: '受伤、爆炸与拾取时轻微震动',
              value: settings.hapticsEnabled,
              onChanged: settings.setHapticsEnabled,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Section(
          title: '战绩',
          icon: Icons.emoji_events_outlined,
          children: [
            StatStrip(
              entries: [
                StatStripEntry(
                  label: '最高分',
                  value: formatScore(settings.highScore),
                ),
                StatStripEntry(label: '最远波次', value: '${settings.bestWave}'),
                StatStripEntry(label: '出击次数', value: '${settings.runs}'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _Section(
          title: '关于',
          icon: Icons.info_outline_rounded,
          children: [
            _InfoRow(label: '版本', value: 'v${AppConstants.version}'),
            _InfoRow(label: '运行方式', value: '本地单机 · 无需联网'),
            _InfoRow(label: '图形与音效', value: '运行时程序化生成'),
            SizedBox(height: 12),
            _LogSection(),
          ],
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            'v${AppConstants.version} · 苍穹战机',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: colors.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _LogicRatePicker extends StatelessWidget {
  const _LogicRatePicker({required this.settings});

  final SettingsProvider settings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '逻辑刷新率',
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 3),
        Text(
          '弹道与碰撞的更新频率，越高越顺滑，30Hz 更省电',
          style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final rate in LogicRate.values) ...[
              Expanded(
                child: _ChoicePill(
                  label: rate.label,
                  selected: settings.logicRate == rate,
                  onTap: () {
                    SoundService.play(GameSound.ui);
                    settings.setLogicRate(rate);
                  },
                ),
              ),
              if (rate != LogicRate.values.last) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? colors.primary.withValues(alpha: 0.7)
                  : colors.outline,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? colors.primary : colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// 日志入口：展示最近运行日志，非 Web 端可直接打开日志目录。
class _LogSection extends StatefulWidget {
  const _LogSection();

  @override
  State<_LogSection> createState() => _LogSectionState();
}

class _LogSectionState extends State<_LogSection> {
  String? _logPath;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      FileSystemService.instance.getLogRootPath().then((path) {
        if (mounted) setState(() => _logPath = path);
      });
    }
  }

  Future<void> _showLogs() async {
    final logs = LogService.getRecentLogs(300);
    final text = logs.isEmpty ? '暂无日志' : logs.join('\n');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('运行日志'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 420),
          child: SingleChildScrollView(
            child: SelectableText(
              text,
              style: const TextStyle(
                fontSize: 10.5,
                height: 1.5,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext)
                    .showSnackBar(const SnackBar(content: Text('日志已复制')));
              }
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('复制'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _openFolder() async {
    final path = _logPath;
    if (path == null || path.isEmpty) return;
    final ok = await FileSystemService.instance.openDirectory(path);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('无法打开日志目录')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          kIsWeb ? 'Web 端日志只保留在内存，可在下方查看。' : '日志按天保存在用户目录，出问题时可提供日志文件。',
          style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
        ),
        if (_logPath != null && _logPath!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            _logPath!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: colors.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _showLogs,
              icon: const Icon(Icons.receipt_long_outlined, size: 16),
              label: const Text('查看日志'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 38),
                textStyle: const TextStyle(fontSize: 12.5),
              ),
            ),
            if (!kIsWeb) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _logPath == null ? null : _openFolder,
                icon: const Icon(Icons.folder_open_rounded, size: 16),
                label: const Text('打开目录'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  textStyle: const TextStyle(fontSize: 12.5),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
