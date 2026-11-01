import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Цветовые гаммы. По умолчанию — прежняя индиго-гамма StudMate.
enum SeedPalette {
  /// Прежняя гамма приложения (индиго, #4355B9).
  studmate('StudMate', 'Индиго', Color(0xFF4355B9)),

  /// Базовая гамма Material 3 (https://m3.material.io/styles/color/static/baseline).
  baseline('Материал 3', 'Базовая', Color(0xFF6750A4)),

  /// Зелёная гамма.
  green('Хвоя', 'Зелёная', Color(0xFF006D3B)),

  /// Оранжевая гамма.
  orange('Терракота', 'Оранжевая', Color(0xFFBF5B1D));

  const SeedPalette(this.label, this.hint, this.seedColor);

  final String label;
  final String hint;
  final Color seedColor;
}

// ─────────── Проверенные тона для гаммы StudMate (прежние цвета) ───────────
const _kLightPrimary = Color(0xFF4355B9);
const _kLightOnPrimary = Color(0xFFFFFFFF);
const _kLightPrimaryContainer = Color(0xFFDEE0FF);
const _kLightOnPrimaryContainer = Color(0xFF00105C);
const _kLightSecondaryContainer = Color(0xFFE1E0F9);
const _kLightOnSecondaryContainer = Color(0xFF00105C);
const _kLightTertiaryContainer = Color(0xFFFFD9E2);
const _kLightOnTertiaryContainer = Color(0xFF3E001D);
const _kLightErrorContainer = Color(0xFFF9DEDC);
const _kLightOnErrorContainer = Color(0xFF410E0B);
const _kLightSurface = Color(0xFFFBF8FD);
const _kLightOnSurface = Color(0xFF1B1B1F);
const _kLightOnSurfaceVariant = Color(0xFF46464F);
const _kLightSurfaceContainer = Color(0xFFF0EDF4);
const _kLightSurfaceContainerHighest = Color(0xFFE4E1EC);
const _kLightOutline = Color(0xFF777680);

/// Тоны тёмной темы для гаммы StudMate (контейнеры tone 30/90).
const _kDarkSurface = Color(0xFF131318);
const _kDarkOnSurface = Color(0xFFE4E1E9);
const _kDarkOnSurfaceVariant = Color(0xFFC8C5D0);
const _kDarkSurfaceContainer = Color(0xFF211F26);
const _kDarkSurfaceContainerHighest = Color(0xFF3A3843);
const _kDarkPrimary = Color(0xFFBAC3FF);
const _kDarkOnPrimary = Color(0xFF19266F);
const _kDarkPrimaryContainer = Color(0xFF25378D);
const _kDarkOnPrimaryContainer = Color(0xFFDEE0FF);
const _kDarkSecondaryContainer = Color(0xFF3E4166);
const _kDarkOnSecondaryContainer = Color(0xFFE1E0F9);
const _kDarkTertiaryContainer = Color(0xFF5C1133);
const _kDarkOnTertiaryContainer = Color(0xFFFFD9E2);
const _kDarkErrorContainer = Color(0xFF833555);
const _kDarkOnErrorContainer = Color(0xFFFFD9E2);
const _kDarkOutline = Color(0xFF928F9A);

/// Пользовательские семантические цвета (статусы), которых нет
/// в стандартной палитре M3. Регистрируются в ThemeData.extensions.
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.successContainer,
    required this.onSuccessContainer,
    required this.curatorContainer,
    required this.onCuratorContainer,
  });

  final Color successContainer;

  final Color onSuccessContainer;

  /// Оранжевая подсветка кураторского часа.
  final Color curatorContainer;

  final Color onCuratorContainer;

  static StatusColors of(BuildContext context) =>
      Theme.of(context).extension<StatusColors>()!;

  static const light = StatusColors(
    successContainer: Color(0xFFC8F0D0),
    onSuccessContainer: Color(0xFF00210B),
    curatorContainer: Color(0xFFFFDCC2),
    onCuratorContainer: Color(0xFF4A2000),
  );

  static const dark = StatusColors(
    successContainer: Color(0xFF1E5634),
    onSuccessContainer: Color(0xFFC8F0D0),
    curatorContainer: Color(0xFF5C3A16),
    onCuratorContainer: Color(0xFFFFDCC2),
  );

  @override
  StatusColors copyWith({
    Color? successContainer,
    Color? onSuccessContainer,
    Color? curatorContainer,
    Color? onCuratorContainer,
  }) =>
      StatusColors(
        successContainer: successContainer ?? this.successContainer,
        onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
        curatorContainer: curatorContainer ?? this.curatorContainer,
        onCuratorContainer: onCuratorContainer ?? this.onCuratorContainer,
      );

  @override
  StatusColors lerp(StatusColors? other, double t) => other == null
      ? this
      : StatusColors(
          successContainer:
              Color.lerp(successContainer, other.successContainer, t)!,
          onSuccessContainer:
              Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
          curatorContainer:
              Color.lerp(curatorContainer, other.curatorContainer, t)!,
          onCuratorContainer:
              Color.lerp(onCuratorContainer, other.onCuratorContainer, t)!,
        );

  @override
  bool operator ==(Object other) =>
      other is StatusColors &&
      other.successContainer == successContainer &&
      other.onSuccessContainer == onSuccessContainer &&
      other.curatorContainer == curatorContainer &&
      other.onCuratorContainer == onCuratorContainer;

  @override
  int get hashCode => Object.hash(
      successContainer, onSuccessContainer, curatorContainer, onCuratorContainer);
}

/// Быстрый доступ к ролям M3: `context.scheme`, `context.status`.
extension MaterialContextX on BuildContext {
  ColorScheme get scheme => Theme.of(this).colorScheme;

  StatusColors get status => StatusColors.of(this);
}

/// Основной текст: Manrope, weight 600 (роли M3).
/// Заголовки: Unbounded, weight 700.
///
/// Цвет по умолчанию не захардкожен: в тёмной теме он наследуется
/// из DefaultTextStyle (onSurface активной темы), поэтому заголовки
/// больше не сливаются с фоном.
class AppText {
  /// Ширина текста (трекинг) — задаётся из настроек, применяется ко всему
  /// основному тексту. Заголовки Unbounded не изменяются.
  static double extraSpacing = 0.0;

  static TextStyle body(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w600,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: ((letterSpacing ?? 0) + extraSpacing),
      );

  static TextStyle heading(
    double size, {
    Color? color,
    double? height,
  }) =>
      GoogleFonts.unbounded(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        height: height,
      );
}

ThemeData buildLightTheme(SeedPalette palette) {
  final scheme = ColorScheme.fromSeed(seedColor: palette.seedColor);
  return _buildTheme(
    // Для гаммы StudMate применяем проверенные тона (прежние цвета),
    // остальные гаммы берут полноценные тональные палитры M3 fromSeed.
    palette == SeedPalette.studmate ? _studmateLight(scheme) : scheme,
    StatusColors.light,
  );
}

ThemeData buildDarkTheme(SeedPalette palette) {
  final scheme = ColorScheme.fromSeed(
    seedColor: palette.seedColor,
    brightness: Brightness.dark,
  );
  return _buildTheme(
    palette == SeedPalette.studmate ? _studmateDark(scheme) : scheme,
    StatusColors.dark,
  );
}

ColorScheme _studmateLight(ColorScheme base) => base.copyWith(
      primary: _kLightPrimary,
      onPrimary: _kLightOnPrimary,
      primaryContainer: _kLightPrimaryContainer,
      onPrimaryContainer: _kLightOnPrimaryContainer,
      secondaryContainer: _kLightSecondaryContainer,
      onSecondaryContainer: _kLightOnSecondaryContainer,
      tertiaryContainer: _kLightTertiaryContainer,
      onTertiaryContainer: _kLightOnTertiaryContainer,
      errorContainer: _kLightErrorContainer,
      onErrorContainer: _kLightOnErrorContainer,
      surface: _kLightSurface,
      onSurface: _kLightOnSurface,
      onSurfaceVariant: _kLightOnSurfaceVariant,
      surfaceContainer: _kLightSurfaceContainer,
      surfaceContainerHighest: _kLightSurfaceContainerHighest,
      outline: _kLightOutline,
    );

ColorScheme _studmateDark(ColorScheme base) => base.copyWith(
      primary: _kDarkPrimary,
      onPrimary: _kDarkOnPrimary,
      primaryContainer: _kDarkPrimaryContainer,
      onPrimaryContainer: _kDarkOnPrimaryContainer,
      secondaryContainer: _kDarkSecondaryContainer,
      onSecondaryContainer: _kDarkOnSecondaryContainer,
      tertiaryContainer: _kDarkTertiaryContainer,
      onTertiaryContainer: _kDarkOnTertiaryContainer,
      errorContainer: _kDarkErrorContainer,
      onErrorContainer: _kDarkOnErrorContainer,
      surface: _kDarkSurface,
      onSurface: _kDarkOnSurface,
      onSurfaceVariant: _kDarkOnSurfaceVariant,
      surfaceContainer: _kDarkSurfaceContainer,
      surfaceContainerHighest: _kDarkSurfaceContainerHighest,
      outline: _kDarkOutline,
    );

ThemeData _buildTheme(ColorScheme scheme, StatusColors status) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    extensions: [status],
    // Диалоги и прочие системные виджеты — тем же шрифтом, что и приложение.
    fontFamily: GoogleFonts.manrope().fontFamily,
    scaffoldBackgroundColor: scheme.surface,
    navigationBarTheme: NavigationBarThemeData(
      height: 80,
      elevation: 0,
      backgroundColor: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.secondaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return AppText.body(
          12,
          color:
              selected ? scheme.onSurface : scheme.onSurfaceVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
        );
      }),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll(AppText.body(14)),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.secondaryContainer
              : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
        ),
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
      ),
    ),
  );
}
