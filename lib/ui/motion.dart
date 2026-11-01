import 'package:flutter/material.dart';

/// Токены движения Material 3
/// (https://m3.material.io/styles/motion/easing-and-duration/tokens-specs).
///
/// Длительности соответствуют уровням «short / medium / long»,
/// кривые — наборам Emphasized и Standard.
abstract final class Motion {
  static const short = Duration(milliseconds: 200);
  static const medium = Duration(milliseconds: 350);
  static const long = Duration(milliseconds: 500);

  /// Emphasized easing — рекомендуется для большинства переходов.
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  /// Decelerate-часть кривой Emphasized (вход элементов).
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);

  /// Accelerate-часть кривой Emphasized (выход элементов).
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);

  /// Standard easing — для мелких служебных переходов.
  static const Curve standard = Curves.easeInOutCubic;
}

/// Вход-анимация элемента: fade + подъём на [slide] px («змейка» по списку).
///
/// Проигрывается ровно один раз на каждое событие:
/// * при первом построении, если [active] — true;
/// * при каждом возвращении на вкладку ([active] false → true);
/// * при смене [widget.key] (например, смена дня в расписании) — новый
///   виджет создаёт новый стейт и анимируется заново.
///
/// Важно: у карточки не должно быть второй «глобальной» анимации
/// (перехода вкладки), иначе движение получится задвоенным.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.active = true,
    this.delay = Duration.zero,
    this.slide = 16,
  });

  final Widget child;
  final bool active;
  final Duration delay;

  /// Смещение в пикселях, из которого элемент «выезжает».
  final double slide;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.medium,
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _schedulePlay();
  }

  @override
  void didUpdateWidget(covariant Entrance old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _schedulePlay();
  }

  void _schedulePlay() {
    Future<void>.delayed(widget.delay, () {
      if (mounted) _c.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_c.value);
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.slide),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Полоса прогресса, плавно едущая к новому значению.
class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({
    super.key,
    required this.progress,
    required this.color,
    required this.trackColor,
    this.height = 6,
    this.radius = 3,
    this.duration = Motion.long,
  });

  /// 0…1 (значения вне диапазона обрезаются).
  final double progress;
  final Color color;
  final Color trackColor;
  final double height;
  final double radius;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: p),
      duration: duration,
      curve: Motion.emphasized,
      builder: (context, value, _) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
          ),
        );
      },
    );
  }
}
