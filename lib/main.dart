import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'data/calendar_data.dart';
import 'data/schedule_data.dart';
import 'data/updates.dart';
import 'screens/home_screen.dart';
import 'screens/periods_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/update_prompt.dart';
import 'settings.dart';
import 'theme.dart';
import 'ui/loading_indicator.dart';
import 'ui/motion.dart';

void main() => runApp(const ScheduleApp());

class ScheduleApp extends StatefulWidget {
  const ScheduleApp({super.key});

  @override
  State<ScheduleApp> createState() => _ScheduleAppState();
}

class _ScheduleAppState extends State<ScheduleApp> {
  final AppSettings _settings = AppSettings();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  bool _settingsLoaded = false;

  /// Минимальная длительность экрана загрузки, чтобы сплэш не мигал.
  static const _minSplash = Duration(milliseconds: 900);
  bool _minSplashDone = false;

  bool _updateCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    // Ширина текста применяется при любом изменении настроек.
    _settings.addListener(_applySettings);
    _applySettings();

    Future<void>.delayed(_minSplash, () {
      if (mounted) setState(() => _minSplashDone = true);
    });
  }

  void _applySettings() {
    AppText.extraSpacing = _settings.textSpacing;
    if (!_settingsLoaded) {
      setState(() => _settingsLoaded = true);
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _settings.removeListener(_applySettings);
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeReady = _settingsLoaded && _minSplashDone;
    // Автопроверка обновлений — один раз, когда приложение показалось.
    // В тестах (FLUTTER_TEST) не планируем — фейковый таймер подвешивает тест.
    if (homeReady &&
        !_updateCheckScheduled &&
        !Platform.environment.containsKey('FLUTTER_TEST')) {
      _updateCheckScheduled = true;
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (mounted) _checkForUpdates();
      });
    }
    return MaterialApp(
      title: 'StudMate — расписание $kGroupName',
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: buildLightTheme(_settings.palette),
      darkTheme: buildDarkTheme(_settings.palette),
      themeMode: _settings.themeMode,
      home: homeReady
          ? AppShell(
              settings: _settings,
              onOpenSettings: _openSettings,
            )
          : _M3LoadingScreen(),
    );
  }

  /// Проверка релизов GitHub. [manual] — открыто из настроек.
  Future<void> _checkForUpdates({bool manual = false}) async {
    final messenger =
        ScaffoldMessenger.maybeOf(_navigatorKey.currentContext!);
    try {
      final package = await PackageInfo.fromPlatform();
      final update = await checkForUpdate(package.version);
      if (!mounted) return;

      if (update != null) {
        // «Не показывать больше» действует только на автопроверку.
        if (!manual && update.version == _settings.updateSkippedVersion) {
          return;
        }
        await promptUpdate(
          _navigatorKey.currentContext!,
          update: update,
          progressStyle: _settings.progressStyle,
          onDontShow: () => _settings.skipUpdateVersion(update.version),
        );
      } else if (manual) {
        messenger?.showSnackBar(
          SnackBar(
            content: Text('Установлена последняя версия'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      // Оффлайн / тесты — молча игнорируем.
    }
  }

  Future<void> _openSettings() => _navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => SettingsScreen(
            settings: _settings,
            onCheckUpdates: () => _checkForUpdates(manual: true),
          ),
        ),
      );
}

/// Экран загрузки по гайдам Material 3: логотип + заголовок + линейный
/// прогресс, пока данные и настройки прогружаются.
class _M3LoadingScreen extends StatefulWidget {
  @override
  State<_M3LoadingScreen> createState() => _M3LoadingScreenState();
}

class _M3LoadingScreenState extends State<_M3LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Логотип, дышащий (scale 0.96…1.04).
            ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.04).animate(
                CurvedAnimation(
                  parent: _pulse,
                  curve: Motion.emphasized,
                ),
              ),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.school_outlined,
                    size: 44, color: scheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(height: 24),
            Text('StudMate', style: AppText.heading(28, height: 36 / 28)),
            const SizedBox(height: 4),
            Text(
              'Расписание $kGroupName · учебный 2026/27',
              style: AppText.body(14, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 40),
            // M3 loading indicator (expressive): морф между формами.
            M3LoadingIndicator(color: scheme.primary, size: 80),
          ],
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.settings,
    required this.onOpenSettings,
  });

  final AppSettings settings;
  final VoidCallback onOpenSettings;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final Clock _clock = Clock();
  final ValueNotifier<FocusRequest?> _focus = ValueNotifier(null);
  int _index = 0;

  @override
  void dispose() {
    _clock.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(
        clock: _clock,
        active: _index == 0,
        onOpenSettings: widget.onOpenSettings,
        onOpenTab: (i) => setState(() => _index = i),
        onShowLesson: (date, lesson) {
          _focus.value = FocusRequest(date, lesson.start);
          setState(() => _index = 1);
        },
      ),
      ScheduleScreen(
        clock: _clock,
        focus: _focus,
        settings: widget.settings,
        active: _index == 1,
      ),
      PeriodsScreen(
        clock: _clock,
        kind: PeriodKind.session,
        title: 'Сессия',
        settings: widget.settings,
        active: _index == 2,
      ),
      PeriodsScreen(
        clock: _clock,
        kind: PeriodKind.practice,
        title: 'Практики',
        settings: widget.settings,
        active: _index == 3,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Расписание',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Сессия',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Практика',
          ),
        ],
      ),
    );
  }
}
