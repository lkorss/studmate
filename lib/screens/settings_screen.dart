import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/schedule_data.dart';
import '../settings.dart';
import '../theme.dart';
import '../ui/motion.dart';
import '../ui/progress.dart';

/// Экран настроек приложения.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    this.onCheckUpdates,
  });

  final AppSettings settings;

  /// Ручная проверка обновлений (умолчание: см. ScheduleApp).
  final VoidCallback? onCheckUpdates;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Шапка
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
              child: Row(
                children: [
                  IconButton.outlined(
                    tooltip: 'Назад',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 12),
                  Entrance(
                    slide: 10,
                    child: Text(
                      'Настройки',
                      style: AppText.heading(22, height: 30 / 22),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListenableBuilder(
                  listenable: settings,
                  builder: (context, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Entrance(
                        slide: 12,
                        delay: const Duration(milliseconds: 60),
                        child: _PaletteSection(settings: settings),
                      ),
                      const SizedBox(height: 32),
                      Entrance(
                        slide: 12,
                        delay: const Duration(milliseconds: 140),
                        child: _ThemeModeSection(settings: settings),
                      ),
                      const SizedBox(height: 32),
                      Entrance(
                        slide: 12,
                        delay: const Duration(milliseconds: 220),
                        child: _ProgressStyleSection(settings: settings),
                      ),
                      const SizedBox(height: 32),
                      Entrance(
                        slide: 12,
                        delay: const Duration(milliseconds: 300),
                        child: _TextWidthSection(settings: settings),
                      ),
                      const SizedBox(height: 32),
                      Entrance(
                        slide: 12,
                        delay: const Duration(milliseconds: 380),
                        child: _UpdatesSection(onCheck: onCheckUpdates),
                      ),
                      const SizedBox(height: 32),
                      Entrance(
                        slide: 12,
                        delay: const Duration(milliseconds: 460),
                        child: _ResetSection(settings: settings),
                      ),
                      const SizedBox(height: 32),
                      Entrance(
                        slide: 12,
                        delay: const Duration(milliseconds: 540),
                        child: _AboutCard(),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── Цветовая гамма ───────────────────────

class _PaletteSection extends StatelessWidget {
  const _PaletteSection({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Цветовая гамма', style: AppText.heading(16)),
        const SizedBox(height: 2),
        Text(
          'Базовые палитры по Material 3. «Индиго» — прежние цвета приложения.',
          style: AppText.body(13, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: scheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: Column(
            children: [
              for (final p in SeedPalette.values) ...[
                if (p != SeedPalette.values.first)
                  const Divider(height: 1, indent: 16, endIndent: 16),
                _PaletteTile(
                  palette: p,
                  selected: settings.palette == p,
                  onTap: () => settings.setPalette(p),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final SeedPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    // Небольшое живое превью выбираемой гаммы.
    final preview = palette == SeedPalette.studmate
        ? const ColorScheme.light(primary: Color(0xFF4355B9),
            primaryContainer: Color(0xFFDEE0FF),
            secondaryContainer: Color(0xFFE1E0F9),
            surfaceContainer: Color(0xFFF0EDF4))
        : ColorScheme.fromSeed(seedColor: palette.seedColor);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Три кружка-превью (primary, container, surface).
              _PreviewSwatch(
                color: preview.primary,
                border: scheme.outline,
              ),
              const SizedBox(width: 4),
              _PreviewSwatch(
                color: preview.primaryContainer,
                border: scheme.outline,
              ),
              const SizedBox(width: 4),
              _PreviewSwatch(
                color: preview.surfaceContainer,
                border: scheme.outline,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(palette.label, style: AppText.body(16)),
                    Text(
                      palette.hint,
                      style:
                          AppText.body(13, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: Motion.short,
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: Tween(begin: 0.6, end: 1.0).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.check_circle,
                          color: scheme.primary,
                          key: ValueKey('on-${palette.name}'),
                        ),
                      )
                    : const SizedBox(
                        width: 32,
                        height: 32,
                        key: ValueKey('off'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewSwatch extends StatelessWidget {
  const _PreviewSwatch({required this.color, required this.border});

  final Color color;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border.withValues(alpha: 0.4)),
      ),
    );
  }
}

// ─────────────────────── Режим темы ───────────────────────

class _ThemeModeSection extends StatelessWidget {
  const _ThemeModeSection({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Режим темы', style: AppText.heading(16)),
        const SizedBox(height: 2),
        Text(
          'Светлая, тёмная или как в системе.',
          style: AppText.body(13, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_outlined),
                label: Text('Системная'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_outlined),
                label: Text('Светлая'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_outlined),
                label: Text('Тёмная'),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (s) =>
                settings.setThemeMode(s.first),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────── Стиль прогресс-индикатора ───────────────────────

class _ProgressStyleSection extends StatelessWidget {
  const _ProgressStyleSection({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Прогресс-индикатор', style: AppText.heading(16)),
        const SizedBox(height: 2),
        Text(
          'Стиль индикатора в счётчиках дней сессии, практики и каникул '
          '(по Material 3).',
          style: AppText.body(13, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ProgressStyle>(
            segments: [
              for (final s in ProgressStyle.values)
                ButtonSegment(value: s, label: Text(s.label)),
            ],
            selected: {settings.progressStyle},
            onSelectionChanged: (sel) => settings.setProgressStyle(sel.first),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: scheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Живое превью',
                  style: AppText.body(
                    13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                // Превью со значением, как в счётчике дней периода.
                AdaptiveProgress(
                  progress: 0.62,
                  style: settings.progressStyle,
                  color: scheme.primary,
                  trackColor: scheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 8),
                Text(
                  'Завершено на 62%',
                  style: AppText.body(12, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────── Ширина текста ───────────────────────

class _TextWidthSection extends StatelessWidget {
  const _TextWidthSection({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final labels = ['Плотно', 'Обычно', 'Широк'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ширина текста', style: AppText.heading(16)),
        const SizedBox(height: 2),
        Text(
          'Трекинг букв — применяется во всём приложении.',
          style: AppText.body(13, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: scheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Живое превью: стили берутся из AppText, который уже
                // подстраивается под текущее значение ширины.
                Text('Операционные системы · каб. 305',
                    style: AppText.body(16)),
                const SizedBox(height: 4),
                Text(
                  'Петров А. В.',
                  style: AppText.body(
                    13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Slider(
                  value: settings.textSpacing,
                  min: -1.0,
                  max: 2.0,
                  divisions: 30, // шаг 0.1
                  label: settings.textSpacing == 0
                      ? labels[1]
                      : (settings.textSpacing < 0
                          ? labels[0]
                          : labels[2]),
                  onChanged: (v) => settings.setTextSpacing(v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Плотно',
                      style:
                          AppText.body(12, color: scheme.onSurfaceVariant),
                    ),
                    Text(
                      'Широко',
                      style:
                          AppText.body(12, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────── Обновление ───────────────────────

class _UpdatesSection extends StatelessWidget {
  const _UpdatesSection({required this.onCheck});

  /// Ручная проверка обновлений (null — не показывать кнопку).
  final VoidCallback? onCheck;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Обновление', style: AppText.heading(16)),
        const SizedBox(height: 2),
        Text(
          'Проверка новых версий — по релизам GitHub.',
          style: AppText.body(13, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: scheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.system_update_alt_outlined,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final version = snapshot.data?.version ?? '—';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('StudMate · v$version', style: AppText.body(14)),
                          const SizedBox(height: 2),
                          Text(
                            'Канал релизов: github.com/lkorss/studmate',
                            style: AppText.body(
                              12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: onCheck,
                  child: Text('Скачать', style: AppText.body(14)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────── Сброс ───────────────────────

class _ResetSection extends StatelessWidget {
  const _ResetSection({required this.settings});

  final AppSettings settings;

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Сбросить настройки?', style: AppText.heading(16)),
        content: Text(
          'Тема, гамма, стиль прогресса и ширина текста вернутся '
          'к значениям по умолчанию.',
          style: AppText.body(14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
    if (ok == true) await settings.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.tonalIcon(
        onPressed: () => _confirmReset(context),
        icon: const Icon(Icons.restart_alt_outlined),
        label: Text('Сбросить настройки', style: AppText.body(16)),
      ),
    );
  }
}

// ─────────────────────── О приложении ───────────────────────

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.scheme.surface.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_outlined),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'StudMate',
                  style: AppText.body(
                    16,
                    color: scheme.onPrimaryContainer,
                    weight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Расписание $kGroupName · версия 1.0',
                  style: AppText.body(
                    13,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
