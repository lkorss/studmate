import 'package:flutter/material.dart';

import '../data/calendar_data.dart';
import '../data/schedule_data.dart';
import '../theme.dart';
import '../ui/motion.dart';
import '../widgets/teacher_name.dart';
import 'account_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.clock,
    required this.onOpenTab,
    required this.onShowLesson,
    required this.onOpenSettings,
    this.active = true,
  });

  final Clock clock;
  final ValueChanged<int> onOpenTab;

  /// Открыть вкладку «Расписание» на нужной паре.
  final void Function(DateTime date, Lesson lesson) onShowLesson;

  /// Открыть настройки (аватар в шапке).
  final VoidCallback onOpenSettings;

  /// Вкладка сейчас перед пользователем (для вход-анимаций).
  final bool active;

  String _greeting(int hour) {
    if (hour >= 5 && hour < 12) return 'Доброе утро';
    if (hour >= 12 && hour < 18) return 'Добрый день';
    if (hour >= 18 && hour < 23) return 'Добрый вечер';
    return 'Доброй ночи';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final status = context.status;

    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: clock,
        builder: (context, _) {
          final now = clock.now;
          final today = dateOnly(now);
          final sec = secOfDay(now);
          final info = nowInfo(now);
          final cur = info.current;
          final nxt = info.next;
          final todayMode = sameDay(info.date, today);

          // Содержимое главной карточки
          String label;
          String title;
          String? detail;
          double? progress;
          String? caption;

          final period = info.period;
          if (period != null) {
            // Практика, сессия или каникулы — пар нет
            label =
                '${periodKindLabel(period.kind)} · ДО ${pad2(period.end.day)}.${pad2(period.end.month)}';
            title = period.title;
            detail = periodLabel(period);
            progress = period.progressOn(today);
            caption = dayCaption(period, today);
          } else if (cur != null) {
            label = 'СЕЙЧАС · ДО ${cur.end}';
            title = cur.subject;
            detail = '${roomLabel(cur.room)} · ${cur.teacher}';
            progress = ((sec - cur.startSec) / (cur.endSec - cur.startSec))
                .clamp(0.0, 1.0)
                .toDouble();
            caption = 'Осталось ${formatRemaining(cur.endSec - sec)}';
          } else if (nxt != null && todayMode) {
            label = 'ДАЛЕЕ · В ${nxt.start}';
            title = nxt.subject;
            detail = '${roomLabel(nxt.room)} · ${nxt.teacher}';
            caption = 'Начало через ${formatRemaining(nxt.startSec - sec)}';
          } else if (nxt != null) {
            final days = info.date.difference(today).inDays;
            final when = days == 1
                ? 'ЗАВТРА'
                : '${kWeekdayShort[info.date.weekday - 1].toUpperCase()}, '
                    '${pad2(info.date.day)}.${pad2(info.date.month)}';
            label = 'СЛЕДУЮЩАЯ ПАРА · $when · ${nxt.start}';
            title = nxt.subject;
            detail = '${roomLabel(nxt.room)} · ${nxt.teacher}';
          } else {
            label = 'ПАР НЕТ';
            title = 'Ближайших пар не найдено';
          }

          // Список «дальше»
          final hero = cur ?? nxt;
          List<Lesson> rest;
          String sectionTitle;
          if (todayMode) {
            sectionTitle = 'Дальше сегодня';
            rest = lessonsOn(today)
                .where((l) => l.startSec > sec && l.start != hero?.start)
                .toList();
          } else {
            sectionTitle = 'Потом в этот день';
            final ls = lessonsOn(info.date);
            rest = ls.length > 1 ? ls.sublist(1) : <Lesson>[];
          }

          final weekLabel =
              isNumerator(today) ? 'числитель' : 'знаменатель';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Entrance(
                  active: active,
                  child: _Header(
                    subtitle: '${kWeekdayFull[today.weekday - 1]}, '
                        '${today.day} ${kMonthsGen[today.month - 1]} · $weekLabel',
                    greeting: _greeting(now.hour),
                    onAvatarTap: () => showAccountSheet(
                      context,
                      onOpenSettings: onOpenSettings,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Entrance(
                        active: active,
                        delay: const Duration(milliseconds: 60),
                        child: _NowCard(
                          label: label,
                          title: title,
                          detail: detail,
                          progress: progress,
                          caption: caption,
                          onTap: period != null
                              ? () => onOpenTab(
                                    period.kind == PeriodKind.practice
                                        ? 3
                                        : period.kind == PeriodKind.session
                                            ? 2
                                            : 1,
                                  )
                              : (hero == null
                                  ? null
                                  : () => onShowLesson(info.date, hero)),
                        ),
                      ),
                      if (period == null &&
                          (rest.isNotEmpty || todayMode)) ...[
                        const SizedBox(height: 20),
                        Entrance(
                          active: active,
                          delay: const Duration(milliseconds: 120),
                          child: Text(sectionTitle, style: AppText.heading(14)),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (period == null && rest.isEmpty && todayMode)
                        Entrance(
                          active: active,
                          delay: const Duration(milliseconds: 120),
                          child: Text(
                            'Больше пар сегодня нет',
                            style: AppText.body(
                              14,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    for (var i = 0; i < rest.length; i++) ...[
                        Entrance(
                          key: ValueKey(rest[i].start),
                          active: active,
                          delay: Duration(
                              milliseconds: 150 + (25 * i).clamp(0, 150)),
                          child: _LessonRow(
                            lesson: rest[i],
                            onTap: () => onShowLesson(info.date, rest[i]),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      const SizedBox(height: 4),
                      Entrance(
                        active: active,
                        delay: Duration(
                            milliseconds: 180 + (25 * rest.length).clamp(0, 100)),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _Tile(
                                  background: scheme.tertiaryContainer,
                                  foreground: scheme.onTertiaryContainer,
                                  icon: Icons.fact_check_outlined,
                                  title: 'Сессия',
                                  subtitle: periodsSummary(
                                      PeriodKind.session, today),
                                  onTap: () => onOpenTab(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _Tile(
                                  background: status.successContainer,
                                  foreground: status.onSuccessContainer,
                                  icon: Icons.work_outline,
                                  title: 'Практика',
                                  subtitle: periodsSummary(
                                      PeriodKind.practice, today),
                                  onTap: () => onOpenTab(3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.subtitle,
    required this.greeting,
    required this.onAvatarTap,
  });

  final String subtitle;
  final String greeting;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: AppText.body(14, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(greeting, style: AppText.heading(22, height: 30 / 22)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Аватар открывает настройки.
          Tooltip(
            message: 'Настройки',
            child: Material(
              color: scheme.primaryContainer,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onAvatarTap,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: Text(
                      'ПО',
                      style:
                          AppText.body(16, color: scheme.onPrimaryContainer),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NowCard extends StatelessWidget {
  const _NowCard({
    required this.label,
    required this.title,
    this.detail,
    this.progress,
    this.caption,
    this.onTap,
  });

  final String label;
  final String title;
  final String? detail;
  final double? progress;
  final String? caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final radius = BorderRadius.circular(28);
    return Material(
      color: scheme.primary,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: AppText.body(
                        13,
                        color: scheme.onPrimary,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(Icons.arrow_forward, size: 20, color: scheme.onPrimary),
                ],
              ),
              const SizedBox(height: 8),
              // Кроссфейд при смене пары/статуса.
              AnimatedSwitcher(
                duration: Motion.short,
                switchInCurve: Motion.emphasizedDecelerate,
                switchOutCurve: Motion.emphasizedAccelerate,
                layoutBuilder: (current, previous) => layoutChildSwitcher(
                  current,
                  previous,
                  alignment: Alignment.topLeft,
                ),
                child: Text(
                  title,
                  key: ValueKey(title),
                  style: AppText.heading(
                    19,
                    color: scheme.onPrimary,
                    height: 26 / 19,
                  ),
                ),
              ),
              if (detail != null) ...[
                const SizedBox(height: 4),
                Text(
                  detail!,
                  style: AppText.body(14, color: scheme.onPrimary),
                ),
              ],
              if (progress != null) ...[
                const SizedBox(height: 18),
                AnimatedProgressBar(
                  progress: progress!,
                  color: scheme.onPrimary,
                  trackColor: scheme.onPrimary.withValues(alpha: 0.3),
                ),
              ],
              if (caption != null) ...[
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: Motion.short,
                  child: Text(
                    caption!,
                    key: ValueKey(caption),
                    style: AppText.body(12, color: scheme.onPrimary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Стек с выравниванием, чтобы AnimatedSwitcher не прыгал по ширине.
Widget layoutChildSwitcher(
  Widget? current,
  List<Widget> previous, {
  AlignmentGeometry alignment = Alignment.centerLeft,
}) {
      return Stack(
    alignment: alignment,
    children: [
      ...previous,
      ?current,
    ],
  );
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({required this.lesson, required this.onTap});

  final Lesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final status = context.status;
    // Кураторский час подсвечивается оранжевым контейнером.
    final bg =
        lesson.curator ? status.curatorContainer : scheme.surfaceContainer;
    final fg = lesson.curator
        ? status.onCuratorContainer
        : scheme.onSurface;
    final fgVar = lesson.curator
        ? status.onCuratorContainer.withValues(alpha: 0.8)
        : scheme.onSurfaceVariant;
    final radius = BorderRadius.circular(20);
    return Material(
      color: bg,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                child: Column(
                  children: [
                    Text(lesson.start, style: AppText.body(16, color: fg)),
                    Text(
                      lesson.end,
                      style: AppText.body(12, color: fgVar),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.subject, style: AppText.body(16, color: fg)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: fgVar,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            roomLabel(lesson.room),
                            style: AppText.body(13, color: fgVar),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('·', style: AppText.body(13, color: fgVar)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: TeacherName(
                            subject: lesson.subject,
                            teacherShort: lesson.teacher,
                            style: AppText.body(13, color: fgVar),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.background,
    required this.foreground,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color background;
  final Color foreground;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final radius = BorderRadius.circular(24);
    return Material(
      color: background,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: foreground),
              ),
              const SizedBox(height: 10),
              Text(title,
                  style: AppText.body(16, color: foreground, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle, style: AppText.body(13, color: foreground)),
            ],
          ),
        ),
      ),
    );
  }
}
