import 'dart:async';

import 'package:flutter/foundation.dart';

const kGroupName = 'ПО-24';

/// Понедельник недели, в которой лежит 15.09.2026 (эта неделя — числитель).
final DateTime kRefNumeratorWeek = DateTime.utc(2026, 9, 14);

const kWeekdayFull = [
  'Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье',
];
const kWeekdayShort = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
const kMonthsGen = [
  'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
  'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
];
const kMonthsShort = [
  'янв', 'фев', 'мар', 'апр', 'мая', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
];

enum WeekType { numerator, denominator }

extension WeekTypeX on WeekType {
  String get label =>
      this == WeekType.numerator ? 'Числитель' : 'Знаменатель';
  String get onlyLabel =>
      this == WeekType.numerator ? 'Только числитель' : 'Только знаменатель';
}

class Lesson {
  const Lesson({
    required this.pairLabel,
    required this.start,
    required this.end,
    required this.subject,
    required this.teacher,
    required this.room,
    this.onlyWeek,
    this.curator = false,
  });

  final String pairLabel;
  final String start;
  final String end;
  final String subject;
  final String teacher;
  final String room;

  /// Если задано — предмет бывает только на этой неделе (персональная плашка).
  final WeekType? onlyWeek;
  final bool curator;

  int get startSec => timeToSec(start);
  int get endSec => timeToSec(end);
}

int timeToSec(String t) {
  final p = t.split(':');
  return int.parse(p[0]) * 3600 + int.parse(p[1]) * 60;
}

// ───────────────────────── Время (Алматы, UTC+5) ─────────────────────────

/// Текущее время в Алматы. Поля (year, hour…) — это «настенное» время Алматы.
DateTime almatyNow() =>
    DateTime.now().toUtc().add(const Duration(hours: 5));

DateTime dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

int secOfDay(DateTime t) => t.hour * 3600 + t.minute * 60 + t.second;

String pad2(int n) => n.toString().padLeft(2, '0');

DateTime mondayOf(DateTime d) =>
    dateOnly(d).subtract(Duration(days: d.weekday - 1));

bool isNumerator(DateTime d) {
  final weeks = mondayOf(d).difference(kRefNumeratorWeek).inDays ~/ 7;
  return weeks.isEven;
}

/// Тикающие часы: перерисовывают экраны каждые 10 секунд.
class Clock extends ChangeNotifier {
  Clock() {
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      now = almatyNow();
      notifyListeners();
    });
  }

  DateTime now = almatyNow();
  late final Timer _timer;

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

String formatRemaining(int totalSec) {
  if (totalSec <= 0) return '0 мин';
  final mins = (totalSec / 60).ceil();
  if (mins >= 60) {
    final h = mins ~/ 60;
    final m = mins % 60;
    return m > 0 ? '$h ч $m мин' : '$h ч';
  }
  return '$mins мин';
}

String roomLabel(String room) =>
    RegExp(r'^\d+$').hasMatch(room) ? 'каб. $room' : room;

// ───────────────────────────── Звонки ─────────────────────────────

const Map<int, List<String>> _bellsMondayNum = {
  1: ['8:00', '9:20'],
  2: ['9:30', '10:50'],
  3: ['11:10', '12:30'],
  4: ['13:10', '14:30'],
  5: ['14:40', '16:00'],
  6: ['16:10', '17:30'],
  7: ['17:40', '19:00'],
};
const List<String> _curatorBell = ['12:30', '13:00'];

const Map<int, List<String>> _bellsMondayDen = {
  1: ['8:00', '9:20'],
  2: ['9:30', '10:50'],
  3: ['11:10', '12:30'],
  4: ['12:40', '14:00'],
  5: ['14:40', '16:00'],
  6: ['16:10', '17:30'],
  7: ['17:40', '19:00'],
};

const Map<int, List<String>> _bellsWeek = {
  1: ['8:00', '9:20'],
  2: ['9:30', '10:50'],
  3: ['11:10', '12:30'],
  4: ['12:40', '14:00'],
  5: ['14:20', '15:40'],
  6: ['15:50', '17:10'],
  7: ['17:20', '18:40'],
};

// ───────────────────────────── Предметы ─────────────────────────────

class _Item {
  const _Item(this.pair, this.subject, this.teacher, this.room);
  final int pair;
  final String subject;
  final String teacher;
  final String room;
}

const _mondayBase = [
  _Item(1, 'Физическая культура', 'Жумабеков К.С.', 'с/з'),
  _Item(2, 'Этика деловых отношений', 'Кенжебаева А.Ж.', 'л/з'),
  _Item(3, 'Основы эконом. теории', 'Каримова Н.К.', 'л/з'),
  _Item(4, 'Основы инф. технологий', 'Жастулекова Т.С.', '403'),
];

const _tuesday = [
  _Item(2, 'Осн. предприним. и бизнеса', 'Абельдинова С.Т.', 'л/з'),
  _Item(3, 'Основы инф. технологий', 'Жастулекова Т.С.', '403'),
  _Item(4, 'История Казахстана', 'Жагалова Д.Б.', '316'),
  _Item(5, 'Основы инф. технологий', 'Жастулекова Т.С.', '403'),
];

const _wednesday = [
  _Item(3, 'Мультимедиа технологии', 'Омарова А.К.', '406'),
  _Item(4, 'Инстр. сред. визуал. ком. и приклад. дизайн', 'Куатова Е.Н.', '411'),
  _Item(5, 'История Казахстана', 'Жагалова Д.Б.', 'л/з'),
];

const _thursdayBase = [
  _Item(3, 'Мультимедиа технологии', 'Омарова А.К.', '406'),
  _Item(4, 'Основы инф. технологий', 'Жастулекова Т.С.', '403'),
];
const _thursdayPair2Num =
    _Item(2, 'Физическая культура', 'Жумабеков К.С.', 'с/з');
const _thursdayPair2Den =
    _Item(2, 'Основы эконом. теории', 'Каримова Н.К.', 'л/з');

const _fridayBase = [
  _Item(2, 'Основы эконом. теории', 'Каримова Н.К.', 'л/з'),
  _Item(3, 'Инстр. сред. визуал. ком. и приклад. дизайн', 'Куатова Е.Н.', '411'),
  _Item(4, 'Осн. предприним. и бизнеса', 'Абельдинова С.Т.', 'л/з'),
];
const _fridayPair1Num = _Item(1, 'Охрана труда', 'Имантусіп А.Ж.', 'л/з');
const _fridayPair1Den =
    _Item(1, 'Мультимедиа технологии', 'Омарова А.К.', 'л/з');

Lesson _mk(_Item it, Map<int, List<String>> bells, {WeekType? only}) {
  final b = bells[it.pair]!;
  return Lesson(
    pairLabel: '${it.pair} пара',
    start: b[0],
    end: b[1],
    subject: it.subject,
    teacher: it.teacher,
    room: it.room,
    onlyWeek: only,
  );
}

/// Пары на конкретную дату (учитывает числитель/знаменатель).
List<Lesson> lessonsFor(DateTime date) {
  final num = isNumerator(date);

  switch (date.weekday) {
    case DateTime.monday:
      final bells = num ? _bellsMondayNum : _bellsMondayDen;
      final out = <Lesson>[];
      for (final it in _mondayBase) {
        // В числитель между 3 и 4 парой — кураторский час.
        if (it.pair == 4 && num) {
          out.add(const Lesson(
            pairLabel: 'Кур.',
            start: '12:30',
            end: '13:00',
            subject: 'Кураторский час',
            teacher: 'Куатова Е.Н.',
            room: 'л/з',
            curator: true,
          ));
        }
        out.add(_mk(it, bells));
      }
      return out;
    case DateTime.tuesday:
      return _tuesday.map((e) => _mk(e, _bellsWeek)).toList();
    case DateTime.wednesday:
      return _wednesday.map((e) => _mk(e, _bellsWeek)).toList();
    case DateTime.thursday:
      return [
        num
            ? _mk(_thursdayPair2Num, _bellsWeek, only: WeekType.numerator)
            : _mk(_thursdayPair2Den, _bellsWeek, only: WeekType.denominator),
        ..._thursdayBase.map((e) => _mk(e, _bellsWeek)),
      ];
    case DateTime.friday:
      return [
        num
            ? _mk(_fridayPair1Num, _bellsWeek, only: WeekType.numerator)
            : _mk(_fridayPair1Den, _bellsWeek, only: WeekType.denominator),
        ..._fridayBase.map((e) => _mk(e, _bellsWeek)),
      ];
    default:
      return const []; // суббота, воскресенье
  }
}

/// Запрос «показать эту пару в расписании» (с главной экрана).
class FocusRequest {
  FocusRequest(this.date, this.lessonStart);
  final DateTime date;
  final String lessonStart;
}
