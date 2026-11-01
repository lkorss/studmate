import 'package:flutter/material.dart';

import '../data/calendar_data.dart';
import '../data/schedule_data.dart';
import '../settings.dart';
import '../theme.dart';
import '../ui/motion.dart';
import '../ui/progress.dart';

class PeriodStyle {
  const PeriodStyle(this.bg, this.fg, this.icon);
  final Color bg;
  final Color fg;
  final IconData icon;
}

PeriodStyle styleFor(
  PeriodKind kind,
  ColorScheme scheme,
  StatusColors status,
) {
  switch (kind) {
    case PeriodKind.practice:
      return PeriodStyle(
          status.successContainer, status.onSuccessContainer, Icons.work_outline);
    case PeriodKind.session:
      return PeriodStyle(scheme.tertiaryContainer,
          scheme.onTertiaryContainer, Icons.fact_check_outlined);
    case PeriodKind.vacation:
      return PeriodStyle(scheme.secondaryContainer,
          scheme.onSecondaryContainer, Icons.beach_access_outlined);
    case PeriodKind.theory:
      return PeriodStyle(scheme.primaryContainer, scheme.onPrimaryContainer,
          Icons.school_outlined);
  }
}

/// Экран со списком периодов одного вида: «Практики» или «Сессия».
class PeriodsScreen extends StatelessWidget {
  const PeriodsScreen({
    super.key,
    required this.clock,
    required this.kind,
    required this.title,
    required this.settings,
    this.active = true,
  });

  final Clock clock;
  final PeriodKind kind;
  final String title;

  /// Настройки (стиль прогресс-индикатора).
  final AppSettings settings;

  /// Вкладка сейчас перед пользователем (для вход-анимаций).
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: Listenable.merge([clock, settings]),
        builder: (context, _) {
          final today = dateOnly(clock.now);
          final children = <Widget>[];
          int? lastSemester;
          var cardIndex = 0;
          for (final p in periodsOfKind(kind)) {
            if (p.semester != lastSemester) {
              lastSemester = p.semester;
              children.add(Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  '${p.semester} семестр',
                  style: AppText.body(
                    13,
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
              ));
            }
            children.add(Entrance(
              active: active,
              delay: Duration(milliseconds: 60 * (cardIndex++ % 6)),
              child: _PeriodCard(
                period: p,
                today: today,
                progressStyle: settings.progressStyle,
              ),
            ));
            children.add(const SizedBox(height: 12));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'II курс · $kGroupName',
                        style: AppText.body(
                          14,
                          color: context.scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Entrance(
                        active: active,
                        child: Text(
                          title,
                          style: AppText.heading(22, height: 30 / 22),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.period,
    required this.today,
    required this.progressStyle,
  });

  final AcademicPeriod period;
  final DateTime today;
  final ProgressStyle progressStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final status = context.status;
    final p = period;
    final isSession = p.kind == PeriodKind.session;

    late final String chipText;
    late final Color chipBg;
    late final Color chipFg;
    late final String caption;
    switch (p.statusOn(today)) {
      case PeriodStatus.done:
        chipText = isSession ? 'Закончилась' : 'Завершена';
        chipBg = status.successContainer;
        chipFg = status.onSuccessContainer;
        caption = 'Завершено';
      case PeriodStatus.active:
        chipText = 'Идёт';
        chipBg = scheme.primaryContainer;
        chipFg = scheme.onPrimaryContainer;
        caption = dayCaption(p, today);
      case PeriodStatus.soon:
        chipText = 'Скоро';
        chipBg = scheme.tertiaryContainer;
        chipFg = scheme.onTertiaryContainer;
        caption = 'Начало через ${ruDays(p.start.difference(today).inDays)}';
      case PeriodStatus.later:
        chipText = 'Позже';
        chipBg = scheme.secondaryContainer;
        chipFg = scheme.onSecondaryContainer;
        caption = 'Начало через ${ruDays(p.start.difference(today).inDays)}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  p.title,
                  style: AppText.heading(14, height: 20 / 14),
                ),
              ),
              const SizedBox(width: 8),
              // Плавная смена статуса (M3 shape modulate).
              AnimatedContainer(
                duration: Motion.short,
                curve: Motion.emphasized,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AnimatedDefaultTextStyle(
                  duration: Motion.short,
                  style: AppText.body(12, color: chipFg),
                  child: Text(chipText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _Meta(
            icon: Icons.event_outlined,
            text: periodLabel(p),
          ),
          const SizedBox(height: 4),
          _Meta(
            icon: Icons.hourglass_empty_outlined,
            text: 'Длительность: ${ruDays(p.totalDays)}',
          ),
          const SizedBox(height: 14),
          AdaptiveProgress(
            progress: p.progressOn(today),
            style: progressStyle,
            color: scheme.primary,
            trackColor: scheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            style: AppText.body(12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: AppText.body(13, color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// Карточка вместо пар в «Расписании», когда идёт практика, сессия или каникулы.
class PeriodDayCard extends StatelessWidget {
  const PeriodDayCard({
    super.key,
    required this.period,
    required this.date,
    required this.progressStyle,
  });

  final AcademicPeriod period;
  final DateTime date;

  /// Стиль прогресс-индикатора из настроек.
  final ProgressStyle progressStyle;

  @override
  Widget build(BuildContext context) {
    final st = styleFor(period.kind, context.scheme, context.status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: st.bg,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.scheme.surface.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            child: Icon(st.icon, color: st.fg),
          ),
          const SizedBox(height: 14),
          Text(
            periodKindLabel(period.kind),
            style: AppText.body(13, color: st.fg, letterSpacing: 0.4),
          ),
          const SizedBox(height: 4),
          Text(
            period.title,
            style: AppText.heading(16, color: st.fg, height: 24 / 16),
          ),
          const SizedBox(height: 6),
          Text(periodLabel(period), style: AppText.body(13, color: st.fg)),
          const SizedBox(height: 16),
          AdaptiveProgress(
            progress: period.progressOn(date),
            style: progressStyle,
            color: st.fg,
            trackColor: st.fg.withValues(alpha: 0.18),
          ),
          const SizedBox(height: 8),
          Text(dayCaption(period, date),
              style: AppText.body(12, color: st.fg)),
          const SizedBox(height: 12),
          Text(
            'Занятия по расписанию в этот период не проводятся.',
            style: AppText.body(13, color: st.fg),
          ),
        ],
      ),
    );
  }
}
