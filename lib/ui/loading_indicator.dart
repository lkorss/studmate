import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Material 3 Loading Indicator (expressive).
///
/// Реализация по официальной спеке/реализации
/// (https://m3.material.io/components/loading-indicator/overview,
/// androidx.compose.material3.LoadingIndicator):
/// * контейнер 80×80, внутри — активный индикатор 50 (62.5%);
/// * глобальная ротация 360° за 4666 мс, линейно;
/// * каждые 650 мс индикатор морфится в следующую форму из последовательности
///   SoftBurst → Cookie9 → Pentagon → Pill → Sunny → Cookie4 → Oval,
///   с подсадкой на четверть оборота за каждый морф и лёгким overshoot.
class M3LoadingIndicator extends StatefulWidget {
  const M3LoadingIndicator({
    super.key,
    this.color,
    this.size = 80,
  });

  final Color? color;

  /// Сторона контейнера в логических пикселях (спека: 80).
  final double size;

  @override
  State<M3LoadingIndicator> createState() => _M3LoadingIndicatorState();
}

class _M3LoadingIndicatorState extends State<M3LoadingIndicator>
    with TickerProviderStateMixin {
  // Спека: 360°/4666мс.
  late final AnimationController _global = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4666),
  )..repeat();

  // Спека: новый морф каждые 650 мс.
  late final AnimationController _morph = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  int _shapeIndex = 0;

  @override
  void initState() {
    super.initState();
    _runMorphCycle();
  }

  /// Морф каждые 650 мс — по спеке (MorphIntervalMillis).
  void _runMorphCycle() {
    _morph.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() => _shapeIndex = (_shapeIndex + 1) % kShapeCount);
      Future<void>.delayed(Duration.zero, _runMorphCycle);
    });
  }

  @override
  void dispose() {
    _global.dispose();
    _morph.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.color ?? Theme.of(context).colorScheme.primary;

    return Semantics(
      label: 'Загрузка',
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: Listenable.merge([_global, _morph]),
          builder: (context, _) {
            final t = _morph.value;
            // Каждый морф «подкручивает» форму на четверть оборота.
            final quarter = (t * 90 + _shapeIndex * 90) % 360;
            final angle =
                (quarter + _global.value * 360) * math.pi / 180;

            return CustomPaint(
              painter: _ShapeMorphPainter(
                morph: t,
                from: _shapeIndex,
                to: (_shapeIndex + 1) % kShapeCount,
                color: color,
                angle: angle,
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────── Формы M3 (радиальные) ───────────
// Каждая форма задаётся радиальной функцией r(θ), 0…1,
// нормированной к максимуму 1. Морф — интерполяция радиусов.

const int kShapeCount = 7;

/// Радиус формы [index] как функция угла [t] (радианы):
/// kShape: 0 softBurst, 1 cookie9, 2 pentagon, 3 pill, 4 sunny,
/// 5 cookie4, 6 oval.
double shapeRadius(int index, double theta) {
  return switch (index) {
    // SoftBurst: 12-конечная звезда с мягкими лучами.
    0 => _burst(theta, points: 12, inner: 0.72),
    // Cookie9: 9-угольник (скругления даёт сглаживание отрисовки).
    1 => _polygon(theta, sides: 9),
    // Pentagon: 5-угольник.
    2 => _polygon(theta, sides: 5),
    // Pill: мягкая капсула — вытянутый суперэллипс.
    3 => 0.88 + 0.12 * math.cos(2 * theta),
    // Sunny: 5-лепестковый «солнечный» цветок.
    4 => 0.68 + 0.30 * _absCos(5 * theta),
    // Cookie4: 4-угольник (квадрат с мягкими вершинами).
    5 => _polygon(theta, sides: 4),
    // Oval: сплюснутый овал.
    6 => 0.72 / _hypot(0.72 * _absCos(theta), _absSin(theta)),
    _ => 1.0,
  };
}

double _polygon(double theta, {required int sides}) {
  // Классическая радиальная функция правильного N-угольника.
  final a = math.pi / sides;
  return math.cos(a) / math.cos(_mod(theta, 2 * a) - a);
}

double _burst(double theta, {required int points, required double inner}) {
  // Звезда: интерполяция вершин и впадин с мягким сглаживанием.
  final seg = _mod(theta, 2 * math.pi / points) / (math.pi / points);
  final s = _smoothstep(seg);
  return _lerp(inner, 1.0, s);
}

double _absCos(double x) => math.cos(x).abs();

double _absSin(double x) => math.sin(x).abs();

double _hypot(double a, double b) => math.sqrt(a * a + b * b);

double _mod(double x, double m) => ((x % m) + m) % m;

double _smoothstep(double t) => t * t * (3 - 2 * t);

double _lerp(double a, double b, double t) => a + (b - a) * t;

class _ShapeMorphPainter extends CustomPainter {
  const _ShapeMorphPainter({
    required this.morph,
    required this.from,
    required this.to,
    required this.color,
    required this.angle,
  });

  final double morph;
  final int from;
  final int to;
  final Color color;
  final double angle;

  static const sampleCount = 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Спека: активный индикатор занимает 62.5% контейнера (50/80).
    final maxR = 0.625 * size.shortestSide / 2;

    // Overshoot-морф (пружина damping 0.6 слегка перелетает).
    final t = _overshoot(morph);

    final path = Path();
    for (var i = 0; i <= sampleCount; i++) {
      final theta = 2 * math.pi * i / sampleCount;
      var r = _lerp(
        shapeRadius(from, theta),
        shapeRadius(to, theta),
        t,
      );
      // «Пружинное» масштабирование имитирует bounce морфа.
      r *= 1 + 0.06 * math.sin(t * math.pi);
      final rr = maxR * r;
      final offset = center +
          Offset(rr * math.cos(theta + angle), rr * math.sin(theta + angle));
      if (i == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  // easeOutBack: лёгкий перелёт, как пружина damping 0.6.
  static double _overshoot(double t) {
    const c1 = 1.70158;
    const c3 = c1 + 1;
    final x = t - 1;
    return 1 + c3 * x * x * x + c1 * x * x;
  }

  @override
  bool shouldRepaint(_ShapeMorphPainter oldPainter) =>
      oldPainter.morph != morph ||
      oldPainter.from != from ||
      oldPainter.to != to ||
      oldPainter.color != color ||
      oldPainter.angle != angle;
}
