import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/updates.dart';
import '../theme.dart';
import '../ui/progress.dart';

/// Показывает окно «Обновление доступно» с выбором:
/// «Скачать» (качает APK внутри приложения и запускает установщик пакетов),
/// «Не показывать» (skip [version]) — обновление всё равно можно
/// скачать вручную через настройки.
Future<void> promptUpdate(
  BuildContext context, {
  required AppUpdate update,
  required VoidCallback onDontShow,
  ProgressStyle progressStyle = ProgressStyle.linear,
}) {
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (dialogContext) => _UpdateDialog(
      update: update,
      progressStyle: progressStyle,
      onDontShow: () {
        onDontShow();
        Navigator.of(dialogContext).pop();
      },
    ),
  );
}

enum _Phase { confirm, downloading, error }

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({
    required this.update,
    required this.progressStyle,
    required this.onDontShow,
  });

  final AppUpdate update;
  final ProgressStyle progressStyle;
  final VoidCallback onDontShow;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  _Phase _phase = _Phase.confirm;
  double _progress = 0;
  String? _error;
  HttpClient? _activeClient;

  @override
  void dispose() {
    // Диалог закрыли посреди загрузки — рвём соединение.
    _activeClient?.close(force: true);
    super.dispose();
  }

  Future<void> _startDownload() async {
    setState(() {
      _phase = _Phase.downloading;
      _progress = 0;
    });
    try {
      final apkPath = await downloadApk(
        widget.update,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
        registerCancel: (client) => _activeClient = client,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      // Отдаём APK системному установщику пакетов. На первой установке
      // Android спросит «разрешить установку из этого источника» — это ок системы.
      if (Platform.isAndroid) {
        unawaited(
          OpenFilex.open(
            apkPath,
            type: 'application/vnd.android.package-archive',
          ),
        );
      } else {
        // Windows/macOS и т.п.: открываем страницу релиза в браузере.
        await launchUrl(
          Uri.parse(widget.update.releaseUrl),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _error = 'Не удалось скачать обновление. Проверьте интернет.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return AlertDialog(
      icon: Icon(
        switch (_phase) {
          _Phase.error => Icons.error_outline,
          _ => Icons.system_update_alt_outlined,
        },
        size: 28,
        color: scheme.primary,
      ),
      title: Text(
        switch (_phase) {
          _Phase.confirm => 'Обновление доступно',
          _Phase.downloading => 'Загрузка…',
          _Phase.error => 'Ошибка',
        },
        style: AppText.heading(18),
      ),
      content: switch (_phase) {
        _Phase.confirm => Text(
            'Доступна версия ${widget.update.version}. '
            'Скачать и установить?',
            style: AppText.body(14),
          ),
        _Phase.downloading => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdaptiveProgress(
                progress: _progress,
                style: widget.progressStyle,
                color: scheme.primary,
                trackColor: scheme.surfaceContainerHighest,
              ),
              const SizedBox(height: 8),
              Text(
                '${(_progress * 100).round()} %',
                style: AppText.body(12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        _Phase.error => Text(_error ?? '', style: AppText.body(14)),
      },
      actions: switch (_phase) {
        _Phase.confirm => [
            TextButton(
              onPressed: widget.onDontShow,
              child: const Text('Не показывать'),
            ),
            FilledButton.icon(
              onPressed: _startDownload,
              icon: const Icon(Icons.download_rounded),
              label: Text('Скачать', style: AppText.body(15)),
            ),
          ],
        _Phase.downloading => [
            TextButton(
              // Отмена = просто закрыть диалог: HttpClient закроется
              // в dispose, соединение оборвётся, частичный файл удалится.
              onPressed: Navigator.of(context).pop,
              child: const Text('Отмена'),
            ),
          ],
        _Phase.error => [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('Закрыть'),
            ),
            FilledButton.icon(
              onPressed: _startDownload,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('Повторить', style: AppText.body(15)),
            ),
          ],
      },
    );
  }
}
