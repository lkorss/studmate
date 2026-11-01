import 'package:flutter/material.dart';

import '../data/calendar_data.dart';
import '../data/schedule_data.dart';
import '../settings.dart';
import '../theme.dart';
import '../ui/motion.dart';
import '../widgets/teacher_name.dart';
import 'periods_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({
    super.key,
    required this.clock,
    required this.focus,
    required this.settings,
    this.active = true,
  });

  final Clock clock;
  final ValueNotifier<FocusRequest?> focus;

  /// Настройки (стиль прогресс-индикатора на карточках периодов).
  final AppSettings settings;

  /// Вкладка сейчас перед пользователем (для вход-анимаций).
  final bool active;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late DateTime _selected;
  String? _focusStart;
  final Map<String, GlobalKey> _keys = {};

  GlobalKey _keyFor(String start) => _keys.putIfAbsent(start, () => GlobalKey());

  @override
  void initState() {
    super.initState();
    final today = dateOnly(widget.clock.now);
    // В воскресенье сразу показываем понедельник.
    _selected = today.weekday == DateTime.sunday
        ? today.add(const Duration(days: 1))
        : today;
    widget.focus.addListener(_onFocus);
  }

  @override
  void dispose() {
    widget.focus.removeListener(_onFocus);
    super.dispose();
  }

  /// Пришёл запрос с главной: открыть день и подсветить нужную пару.
  void _onFocus() {
    final req = widget.focus.value;
    if (req == null) return;
    setState(() {
      _selected = req.date;
      _focusStart = req.lessonStart;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _keys[req.lessonStart]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: Motion.medium,
          curve: Motion.emphasizedDecelerate,
          alignment: 0.15,
        );
      }
    });
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && widget.focus.value == req) {
        setState(() => _focusStart = null);
      }
    });
  }

  /// Смена недели (числитель/знаменатель) — всегда на понедельник.
  void _shiftWeek(int weeks) => setState(() {
        _selected = mondayOf(_selected).add(Duration(days: 7 * weeks));
        _focusStart = null;
      });

  /// Переключатель «числитель / знаменатель»: переходим на ближайшую
  /// неделю нужного типа (текущую или следующую).
  void _selectWeekType(WeekType target, DateTime today) {
    final base = today.weekday == DateTime.sunday
        ? today.add(const Duration(days: 1))
        : today;
    final currentMonday = mondayOf(base);
    final currentIsNum = isNumerator(currentMonday);
    final wantNum = target == WeekType.numerator;
    final targetMonday = currentIsNum == wantNum
        ? currentMonday
        : currentMonday.add(const Duration(days: 7));
    setState(() {
      _selected = targetMonday; // переключение недели — на понедельник
      _focusStart = null;
    });
  }

  String _rangeLabel(DateTime monday) {
    final sat = monday.add(const Duration(days: 5));
    return '${monday.day} ${kMonthsShort[monday.month - 1]} – '
        '${sat.day} ${kMonthsShort[sat.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: widget.clock,
        builder: (context, _) {
          final now = widget.clock.now;
          final today = dateOnly(now);
          final sec = secOfDay(now);
          final monday = mondayOf(_selected);
          final week = isNumerator(monday)
              ? WeekType.numerator
              : WeekType.denominator;
          final lessons = lessonsOn(_selected);
          final period = offPeriodOn(_selected);
          final isToday = sameDay(_selected, today);

          final items = <Widget>[];
          for (var i = 0; i < lessons.length; i++) {
            final l = lessons[i];
            final current = isToday && sec >= l.startSec && sec < l.endSec;
            items.add(Entrance(
              // Ключ прерывает стейт при смене дня: змейка проигрывается
              // ровно один раз за событие (смена дня или возврат на вкладку).
              key: ValueKey('$_selected-${l.start}'),
              active: widget.active,
              delay: Duration(milliseconds: 40 * i),
              slide: 12,
              child: _LessonItem(
                key: _keyFor(l.start),
                lesson: l,
                current: current,
                focused: _focusStart == l.start,
                remainingSec: current ? l.endSec - sec : null,
              ),
            ));
            items.add(const SizedBox(height: 12));
            if (isToday &&
                i < lessons.length - 1 &&
                sec >= l.endSec &&
                sec < lessons[i + 1].startSec) {
              items.add(Entrance(
                active: widget.active,
                delay: const Duration(milliseconds: 120),
                slide: 12,
                child: _BreakCard(
                  nextLabel: lessons[i + 1].pairLabel.toLowerCase(),
                  remaining: formatRemaining(lessons[i + 1].startSec - sec),
                ),
              ));
              items.add(const SizedBox(height: 12));
            }
          }

          return Column(
            children: [
              // Шапка
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _rangeLabel(monday),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.body(
                                    14,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              if (!isToday) ...[
                                const SizedBox(width: 8),
                                _TodayChip(
                                  onTap: () => setState(() {
                                    _selected =
                                        today.weekday == DateTime.sunday
                                            ? today.add(
                                                const Duration(days: 1))
                                            : today;
                                  }),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Расписание',
                            style: AppText.heading(22, height: 30 / 22),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Предыдущая неделя',
                      onPressed: () => _shiftWeek(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    const SizedBox(width: 4),
                    IconButton.filledTonal(
                      tooltip: 'Следующая неделя',
                      onPressed: () => _shiftWeek(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),

              // Числитель / знаменатель
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<WeekType>(
                    showSelectedIcon: true,
                    segments: [
                      for (final w in WeekType.values)
                        ButtonSegment(value: w, label: Text(w.label)),
                    ],
                    selected: {week},
                    onSelectionChanged: (s) => _selectWeekType(s.first, today),
                  ),
                ),
              ),

              // Дни недели
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  children: List.generate(6, (i) {
                    final d = monday.add(Duration(days: i));
                    final sel = sameDay(d, _selected);
                    final isTod = sameDay(d, today);
                    return Expanded(
                      child: InkResponse(
                        onTap: () => setState(() {
                          _selected = d;
                          _focusStart = null;
                        }),
                        radius: 28,
                        child: Column(
                          children: [
                            Text(
                              kWeekdayShort[i],
                              style: AppText.body(
                                12,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Плавная анимация выбора дня (M3), ширина рамки
                            // постоянна, чтобы при выборе не было дёрганий.
                            AnimatedContainer(
                              duration: Motion.short,
                              curve: Motion.emphasized,
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: sel
                                    ? scheme.primary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: (isTod && !sel)
                                      ? scheme.primary
                                      : scheme.primary
                                          .withValues(alpha: 0.0),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                '${d.day}',
                                style: AppText.body(
                                  16,
                                  color: sel
                                      ? scheme.onPrimary
                                      : scheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Пары. Смена дня меняет ключ вход-анимаций — контент
              // появляется «змейкой» (без наложения второй переходной
              // анимации поверх, как было с AnimatedSwitcher).
              Expanded(
                child: ListenableBuilder(
                  listenable: widget.settings,
                  builder: (context, _) => period != null
                      ? SingleChildScrollView(
                          key: ValueKey('period-$_selected'),
                          child: Entrance(
                            key: ValueKey('entrance-$_selected'),
                            active: widget.active,
                            slide: 12,
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 8, 20, 20),
                              child: PeriodDayCard(
                                period: period,
                                date: _selected,
                                progressStyle: widget.settings.progressStyle,
                              ),
                            ),
                          ),
                        )
                      : lessons.isEmpty
                          ? Entrance(
                              key: ValueKey('empty-$_selected'),
                              active: widget.active,
                              child: const _EmptyDay(),
                            )
                          : SingleChildScrollView(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 8, 20, 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: items,
                              ),
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

class _TodayChip extends StatelessWidget {
  const _TodayChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Material(
      color: scheme.primaryContainer,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          child: Text(
            'На сегодня',
            style: AppText.body(12, color: scheme.onPrimaryContainer),
          ),
        ),
      ),
    );
  }
}

class _LessonItem extends StatelessWidget {
  const _LessonItem({
    super.key,
    required this.lesson,
    required this.current,
    required this.focused,
    this.remainingSec,
  });

  final Lesson lesson;
  final bool current;
  final bool focused;
  final int? remainingSec;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final status = context.status;
    final l = lesson;
    // Кураторский час — оранжевый контейнер (M3 custom role).
    final curator = l.curator;
    final fg = current
        ? scheme.onPrimary
        : (curator ? status.onCuratorContainer : scheme.onSurface);
    final fgVar = current
        ? scheme.onPrimary.withValues(alpha: 0.85)
        : curator
            ? status.onCuratorContainer.withValues(alpha: 0.8)
            : scheme.onSurfaceVariant;
    final bg = current
        ? scheme.primary
        : curator
            ? status.curatorContainer
            : (focused ? scheme.primaryContainer : scheme.surfaceContainer);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 44,
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.start,
                  style: AppText.body(
                    14,
                    color: current
                        ? scheme.onPrimary
                        : (curator ? status.onCuratorContainer : scheme.onSurface),
                  ),
                ),
                Text(
                  l.end,
                  style: AppText.body(12, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedContainer(
            duration: Motion.short,
            curve: Motion.emphasized,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: focused ? scheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Плашка только у персональных предметов
                      if (l.onlyWeek != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l.onlyWeek!.onlyLabel,
                            style: AppText.body(
                              12,
                              color: scheme.onTertiaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(l.subject, style: AppText.body(16, color: fg)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 16, color: fgVar),
                          const SizedBox(width: 4),
                          Flexible(
                            child: TeacherName(
                              subject: l.subject,
                              teacherShort: l.teacher,
                              style: AppText.body(13, color: fgVar),
                            ),
                          ),
                        ],
                      ),
                      if (current && remainingSec != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: scheme.onPrimary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'осталось ${formatRemaining(remainingSec!)}',
                              style: AppText.body(13, color: scheme.onPrimary),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // «Пузырь» с аудиторией
                Container(
                  constraints: const BoxConstraints(minWidth: 48),
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: (current || focused)
                        ? scheme.surface
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    l.room,
                    style: AppText.body(
                      14,
                      color: current ? scheme.primary : scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BreakCard extends StatelessWidget {
  const _BreakCard({required this.nextLabel, required this.remaining});

  final String nextLabel;
  final String remaining;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Padding(
      padding: const EdgeInsets.only(left: 56),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              Icons.coffee_outlined,
              size: 20,
              color: scheme.onTertiaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Перемена · до $nextLabel · $remaining',
                style: AppText.body(13, color: scheme.onTertiaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay();

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_available_outlined, size: 48),
            const SizedBox(height: 12),
            Text('Выходной', style: AppText.heading(18)),
            const SizedBox(height: 6),
            Text(
              'В этот день пар нет.\nЛистайте на учебный день.',
              textAlign: TextAlign.center,
              style: AppText.body(14, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
