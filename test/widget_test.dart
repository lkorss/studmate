// Простой smoke-тест приложения.
import 'package:flutter_test/flutter_test.dart';

import 'package:studmate/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ScheduleApp());

    // Даём доиграть вход-анимациям (не наступая на 10-секундный таймер Clock).
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Навигация присутствует, вкладка «Главная» открыта.
    expect(find.text('Главная'), findsOneWidget);
  });
}
