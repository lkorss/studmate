/// Справочник преподавателей: полные ФИО + часы/кредиты предметов
/// (по данным с учебного плана колледжа).
class TeacherInfo {
  const TeacherInfo(this.fullName, {this.hours, this.credits});

  /// ФИО полностью.
  final String fullName;

  /// Часы предмета по плану (если известны).
  final int? hours;

  /// Кредиты предмета (если известны).
  final double? credits;
}

/// По ключу = названием предмета в расписании (вместе с сокращениями из данных).
const Map<String, TeacherInfo> kTeachersBySubject = {
  'Физическая культура':
      TeacherInfo('Жумабеков Кайрат Серикаевич', hours: 36, credits: 1.5),
  'Этика деловых отношений':
      TeacherInfo('Кенжебаева Аяулым Жасуланкызы', hours: 24, credits: 1.0),
  'Основы эконом. теории':
      TeacherInfo('Каримова Наргиза Канатовна', hours: 48, credits: 2.0),
  'Основы экономической теории':
      TeacherInfo('Каримова Наргиза Канатовна', hours: 48, credits: 2.0),
  'Осн. предприним. и бизнеса':
      TeacherInfo('Абельдинова Саним Темиржановна', hours: 36, credits: 1.5),
  'Основы предпринимательства и бизнеса':
      TeacherInfo('Абельдинова Саним Темиржановна', hours: 36, credits: 1.5),
  'Основы инф. технологий':
      TeacherInfo('Жастулекова Талшын Серковна', hours: 84, credits: 3.5),
  'Основы информационных технологий':
      TeacherInfo('Жастулекова Талшын Серковна', hours: 84, credits: 3.5),
  'История Казахстана':
      TeacherInfo('Жагалова Дилара Багдаткызы', hours: 36, credits: 1.5),
  'Мультимедиа технологии':
      TeacherInfo('Омарова Айым Кырметкызы', hours: 84, credits: 3.5),
  'Мультимедийные технологии':
      TeacherInfo('Омарова Айым Кырметкызы', hours: 84, credits: 3.5),
  'Инстр. сред. визуал. ком. и приклад. дизайн':
      TeacherInfo('Куатова Ержекан Нурланкызы', hours: 72, credits: 3.0),
  'Инструментальные средства визуальной коммуникации и прикладной дизайн':
      TeacherInfo('Куатова Ержекан Нурланкызы', hours: 72, credits: 3.0),
  'Охрана труда':
      TeacherInfo('Имантусп Айым Жанибеккызы', hours: 30, credits: 1.25),
  'Компьютерная геометрия и графика':
      TeacherInfo('Куатова Ержекан Нурланкызы', hours: 18, credits: 0.75),
  'Кураторский час':
      TeacherInfo('Куатова Ержекан Нурланкызы'),
};

/// Резервный поиск по фамилии из короткого «Фамилия И.О.».
const Map<String, String> kFullBySurname = {
  'Жумабеков': 'Жумабеков Кайрат Серикаевич',
  'Кенжебаева': 'Кенжебаева Аяулым Жасуланкызы',
  'Каримова': 'Каримова Наргиза Канатовна',
  'Жастулекова': 'Жастулекова Талшын Серковна',
  'Абельдинова': 'Абельдинова Саним Темиржановна',
  'Жагалова': 'Жагалова Дилара Багдаткызы',
  'Омарова': 'Омарова Айым Кырметкызы',
  'Куатова': 'Куатова Ержекан Нурланкызы',
  'Имантусіп': 'Имантусп Айым Жанибеккызы',
  'Имантусп': 'Имантусп Айым Жанибеккызы',
};

/// Информация о преподавателе пары: name/фамилия → полное ФИО и план предмета.
TeacherInfo? teacherInfoFor(String subject, String teacherShort) {
  final bySubject = kTeachersBySubject[subject];
  if (bySubject != null) return bySubject;

  final surname = teacherShort.trim().split(RegExp(r'\s+')).first;
  final full = kFullBySurname[surname];
  if (full == null) return null;

  // Часы/кредиты ищем по любому предмету того же преподавателя.
  for (final info in kTeachersBySubject.values) {
    if (info.fullName == full && info.hours != null) return info;
  }
  return TeacherInfo(full);
}
