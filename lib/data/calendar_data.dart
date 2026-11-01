import 'schedule_data.dart';

enum PeriodKind { theory, practice, session, vacation }

enum PeriodStatus { done, active, soon, later }

/// Период учебного года из графика учебного процесса.
class AcademicPeriod {
  AcademicPeriod(this.kind, this.title, this.semester, this.start, this.end);

  final PeriodKind kind;
  final String title;
  final int semester;
  final DateTime start;
  final DateTime end;

  int get totalDays => end.difference(start).inDays + 1;

  bool contains(DateTime d) => !d.isBefore(start) && !d.isAfter(end);

  PeriodStatus statusOn(DateTime today) {
    if (today.isAfter(end)) return PeriodStatus.done;
    if (today.isBefore(start)) {
      return start.difference(today).inDays <= 30
          ? PeriodStatus.soon
          : PeriodStatus.later;
    }
    return PeriodStatus.active;
  }

  double progressOn(DateTime date) {
    if (date.isAfter(end)) return 1;
    if (date.isBefore(start)) return 0;
    return ((date.difference(start).inDays + 1) / totalDays)
        .clamp(0.0, 1.0)
        .toDouble();
  }
}

/// ПО-24, II курс — график по скриншоту.
final List<AcademicPeriod> kPeriods = [
  // 3 семестр
  AcademicPeriod(PeriodKind.theory, 'Теоретическое обучение', 3,
      DateTime.utc(2026, 9, 2), DateTime.utc(2026, 11, 10)),
  AcademicPeriod(PeriodKind.practice, 'Производственное обучение', 3,
      DateTime.utc(2026, 11, 11), DateTime.utc(2026, 12, 1)),
  AcademicPeriod(PeriodKind.practice, 'Производственная практика', 3,
      DateTime.utc(2026, 12, 2), DateTime.utc(2027, 1, 5)),
  AcademicPeriod(PeriodKind.session, 'Зимняя экзаменационная сессия', 3,
      DateTime.utc(2027, 1, 6), DateTime.utc(2027, 1, 12)),
  AcademicPeriod(PeriodKind.vacation, 'Зимние каникулы', 3,
      DateTime.utc(2027, 1, 13), DateTime.utc(2027, 1, 26)),
  // 4 семестр
  AcademicPeriod(PeriodKind.theory, 'Теоретическое обучение', 4,
      DateTime.utc(2027, 1, 27), DateTime.utc(2027, 3, 18)),
  AcademicPeriod(PeriodKind.practice, 'Производственное обучение', 4,
      DateTime.utc(2027, 3, 19), DateTime.utc(2027, 4, 23)),
  AcademicPeriod(PeriodKind.session, 'Летняя экзаменационная сессия', 4,
      DateTime.utc(2027, 4, 26), DateTime.utc(2027, 6, 30)),
  AcademicPeriod(PeriodKind.practice, 'Производственная практика', 4,
      DateTime.utc(2027, 5, 3), DateTime.utc(2027, 6, 25)),
  AcademicPeriod(PeriodKind.vacation, 'Летние каникулы', 4,
      DateTime.utc(2027, 6, 28), DateTime.utc(2027, 8, 31)),
];

List<AcademicPeriod> periodsOfKind(PeriodKind kind) {
  final list = kPeriods.where((p) => p.kind == kind).toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  return list;
}

// Если периоды пересекаются (практика внутри летней сессии), побеждает
// тот, у кого приоритет выше: практика → каникулы → сессия → занятия.
int _priority(PeriodKind k) {
  switch (k) {
    case PeriodKind.practice:
      return 0;
    case PeriodKind.vacation:
      return 1;
    case PeriodKind.session:
      return 2;
    case PeriodKind.theory:
      return 3;
  }
}

/// Какой период идёт в этот день (null — календарь день не покрывает).
AcademicPeriod? periodOn(DateTime date) {
  final d = dateOnly(date);
  AcademicPeriod? best;
  for (final p in kPeriods) {
    if (p.contains(d) && (best == null || _priority(p.kind) < _priority(best.kind))) {
      best = p;
    }
  }
  return best;
}

/// Период, в который пар нет (практика, сессия, каникулы), иначе null.
AcademicPeriod? offPeriodOn(DateTime date) {
  final p = periodOn(date);
  return (p != null && p.kind != PeriodKind.theory) ? p : null;
}

/// Пары на дату с учётом графика: вне теоретического обучения пар нет.
List<Lesson> lessonsOn(DateTime date) =>
    offPeriodOn(date) != null ? const <Lesson>[] : lessonsFor(date);

// ───────────────────────── Подписи ─────────────────────────

String ruDays(int n) {
  final m10 = n % 10;
  final m100 = n % 100;
  if (m10 == 1 && m100 != 11) return '$n день';
  if (m10 >= 2 && m10 <= 4 && (m100 < 10 || m100 >= 20)) return '$n дня';
  return '$n дней';
}

String periodLabel(AcademicPeriod p) {
  final s = p.start;
  final e = p.end;
  final startPart = s.year == e.year
      ? '${s.day} ${kMonthsGen[s.month - 1]}'
      : '${s.day} ${kMonthsGen[s.month - 1]} ${s.year}';
  return '$startPart – ${e.day} ${kMonthsGen[e.month - 1]} ${e.year}';
}

String periodKindLabel(PeriodKind k) {
  switch (k) {
    case PeriodKind.practice:
      return 'ПРАКТИКА';
    case PeriodKind.session:
      return 'СЕССИЯ';
    case PeriodKind.vacation:
      return 'КАНИКУЛЫ';
    case PeriodKind.theory:
      return 'ЗАНЯТИЯ';
  }
}

/// «День 5 из 21 · осталось 16 дней» относительно даты [date].
String dayCaption(AcademicPeriod p, DateTime date) {
  final day = date.difference(p.start).inDays + 1;
  final left = p.end.difference(date).inDays;
  final tail = left == 0 ? 'последний день' : 'осталось ${ruDays(left)}';
  return 'День $day из ${p.totalDays} · $tail';
}

/// Короткая подпись для плиток главной.
String periodsSummary(PeriodKind kind, DateTime today) {
  final list = periodsOfKind(kind);
  for (final p in list) {
    if (p.statusOn(today) == PeriodStatus.active) {
      return 'Идёт · до ${pad2(p.end.day)}.${pad2(p.end.month)}';
    }
  }
  for (final p in list) {
    if (p.start.isAfter(today)) {
      return 'Старт ${p.start.day} ${kMonthsGen[p.start.month - 1]}';
    }
  }
  return kind == PeriodKind.session ? 'Сессий больше нет' : 'Практик больше нет';
}

// ───────────────────── Что происходит прямо сейчас ─────────────────────

class NowInfo {
  const NowInfo({this.current, this.next, this.period, required this.date});

  /// Идущая сейчас пара.
  final Lesson? current;

  /// Следующая пара (сегодня или в ближайший учебный день).
  final Lesson? next;

  /// Если сегодня практика / сессия / каникулы — этот период.
  final AcademicPeriod? period;

  /// Дата, к которой относится [next] (или сегодня).
  final DateTime date;
}

NowInfo nowInfo(DateTime now) {
  final today = dateOnly(now);
  final sec = secOfDay(now);

  final off = offPeriodOn(today);
  if (off != null) return NowInfo(period: off, date: today);

  Lesson? cur;
  Lesson? nxt;
  for (final l in lessonsOn(today)) {
    if (sec >= l.startSec && sec < l.endSec) {
      cur = l;
    } else if (sec < l.startSec && nxt == null) {
      nxt = l;
    }
  }
  if (cur != null || nxt != null) {
    return NowInfo(current: cur, next: nxt, date: today);
  }
  for (var i = 1; i <= 500; i++) {
    final d = today.add(Duration(days: i));
    final ls = lessonsOn(d);
    if (ls.isNotEmpty) return NowInfo(next: ls.first, date: d);
  }
  return NowInfo(date: today);
}
