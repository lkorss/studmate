import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';
import 'ui/progress.dart';

/// Глобальные настройки приложения: тема и цветовая гамма.
///
/// Живёт на самом верху (см. ScheduleApp), уведомляет слушателей
/// при каждом изменении — MaterialApp перестраивается.
class AppSettings extends ChangeNotifier {
  AppSettings() {
    _load();
  }

  static const _kThemeMode = 'themeMode';
  static const _kPalette = 'seedPalette';
  static const _kTextSpacing = 'textSpacing';
  static const _kProgressStyle = 'progressStyle';
  static const _kUpdateSkipped = 'updateSkippedVersion';

  ThemeMode _themeMode = ThemeMode.system;

  /// наследует светлую/тёмную от системы.
  ThemeMode get themeMode => _themeMode;

  SeedPalette _palette = SeedPalette.studmate;

  /// Цветовая гамма (по умолчанию прежняя — индиго).
  SeedPalette get palette => _palette;

  double _textSpacing = 0.0;

  /// Ширина текста (трекинг букв), px: от -1 (плотно) до 2 (широко).
  double get textSpacing => _textSpacing;

  ProgressStyle _progressStyle = ProgressStyle.linear;

  /// Стиль прогресс-индикатора в счётчиках дней (сессии/практики/каникулы).
  ProgressStyle get progressStyle => _progressStyle;

  String? _updateSkippedVersion;

  /// Версия, которую пользователь решил «не показывать» при автопроверке.
  /// (В настройках её всё равно можно скачать вручную.)
  String? get updateSkippedVersion => _updateSkippedVersion;

  Future<void> _load() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final modeName = sp.getString(_kThemeMode);
      if (modeName != null) {
        _themeMode =
            ThemeMode.values.firstWhere((m) => m.name == modeName,
                orElse: () => ThemeMode.system);
      }
      final paletteName = sp.getString(_kPalette);
      if (paletteName != null) {
        _palette = SeedPalette.values
            .firstWhere((p) => p.name == paletteName, orElse: () => _palette);
      }
      _textSpacing = sp.getDouble(_kTextSpacing) ?? _textSpacing;
      final styleName = sp.getString(_kProgressStyle);
      if (styleName != null) {
        _progressStyle = ProgressStyle.values
            .firstWhere((s) => s.name == styleName, orElse: () => _progressStyle);
      }
      _updateSkippedVersion = sp.getString(_kUpdateSkipped);
    } catch (_) {
      // Нет доступа к хранилищу (например, в тестах) — используем дефолты.
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kThemeMode, mode.name);
  }

  Future<void> setPalette(SeedPalette palette) async {
    if (palette == _palette) return;
    _palette = palette;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kPalette, palette.name);
  }

  Future<void> setTextSpacing(double spacing) async {
    if (spacing == _textSpacing) return;
    _textSpacing = spacing;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble(_kTextSpacing, spacing);
  }

  Future<void> setProgressStyle(ProgressStyle style) async {
    if (style == _progressStyle) return;
    _progressStyle = style;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kProgressStyle, style.name);
  }

  Future<void> skipUpdateVersion(String version) async {
    if (version == _updateSkippedVersion) return;
    _updateSkippedVersion = version;
    notifyListeners();
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kUpdateSkipped, version);
  }

  /// Вернуть все настройки к значениям по умолчанию.
  Future<void> reset() async {
    _themeMode = ThemeMode.system;
    _palette = SeedPalette.studmate;
    _textSpacing = 0.0;
    _progressStyle = ProgressStyle.linear;
    notifyListeners();
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.remove(_kThemeMode);
      await sp.remove(_kPalette);
      await sp.remove(_kTextSpacing);
      await sp.remove(_kProgressStyle);
      await sp.remove(_kUpdateSkipped);
      // Старые ключи из предыдущих версий тоже чистим.
      await sp.remove('reminderEnabled');
      await sp.remove('reminderMinutes');
    } catch (_) {}
  }
}
