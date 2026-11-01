import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'motion.dart';

/// Стиль прогресс-индикатора по гайдам Material 3
/// (https://m3.material.io/components/progress-indicators/overview).
enum ProgressStyle {
  /// Линейный (progress bar).
  linear,

  /// Сегментированный линейный (M3 expressive: 4 сегмента с зазорами).
  expressive;

  String get label => switch (this) {
        linear => 'Линия',
        expressive => 'Сегменты',
      };
}

/// Прогресс-индикатор выбранного стиля: значение плавно едет к новому
/// значению во всех стилях.
class AdaptiveProgress extends StatelessWidget {
  const AdaptiveProgress({
    super.key,
    required this.progress,
    required this.style,
    required this.color,
    required this.trackColor,
  });

  /// 0…1 (значения вне диапазона обрезаются).
  final double progress;
  final ProgressStyle style;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween(end: p),
      duration: Motion.long,
      curve: Motion.emphasized,
      builder: (context, value, _) {
        switch (style) {
          case ProgressStyle.linear:
            return AnimatedProgressBar(
              progress: value,
              color: color,
              trackColor: trackColor,
            );
          case ProgressStyle.expressive:
            return SegmentedProgressBar(
              progress: value,
              color: color,
              trackColor: trackColor,
            );
        }
      },
    );
  }
}

/// Сегментированный линейный индикатор M3 expressive: трек из 4 сегментов
/// с зазорами; активный индикатор едет по «склейке» — зазоры позади него
/// схлопываются, так ведёт себя expressive-индикатор по спеке M3.
class SegmentedProgressBar extends StatelessWidget {
  const SegmentedProgressBar({
    super.key,
    required this.progress,
    required this.color,
    required this.trackColor,
    this.height = 10,
    this.segments = 4,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double height;
  final int segments;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SegmentedPainter(
          progress: progress.clamp(0.0, 1.0),
          color: color,
          trackColor: trackColor,
          segments: segments,
        ),
      ),
    );
  }
}

class _SegmentedPainter extends CustomPainter {
  const _SegmentedPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.segments,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final int segments;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 6.0;
    final radius = size.height / 2;
    final segWidth = (size.width - gap * (segments - 1)) / segments;

    RRect seg(double left, double width) {
      final w = math.max(width, size.height); // не уже скругления
      return RRect.fromRectAndRadius(
        Rect.fromLTWH(left, 0, w, size.height),
        Radius.circular(radius),
      );
    }

    // Трек: все сегменты с зазорами.
    for (var i = 0; i < segments; i++) {
      final left = i * (segWidth + gap);
      canvas.drawRRect(seg(left, segWidth), Paint()..color = trackColor);
    }

    // Активный индикатор.
    if (progress <= 0) return;
    // Длина, «пройденная» по склейке сегментов (без зазоров).
    final crossed = progress * segments * segWidth;
    final fill = Paint()..color = color;
    for (var i = 0; i < segments; i++) {
      final left = i * (segWidth + gap);
      if (crossed >= (i + 1) * segWidth) {
        // Сегмент полностью за индикатором — закрываем зазор перед ним.
        canvas.drawRRect(seg(left, segWidth), fill);
        if (i < segments - 1) {
          canvas.drawRect(
            Rect.fromLTWH(left + segWidth - radius, 0, gap + 2 * radius, size.height),
            fill,
          );
        }
      } else if (crossed > i * segWidth) {
        // Текущий сегмент — заполняем частично.
        canvas.drawRRect(seg(left, crossed - i * segWidth), fill);
        break;
      }
    }
  }

  @override
  bool shouldRepaint(_SegmentedPainter oldPainter) =>
      oldPainter.progress != progress ||
      oldPainter.color != color ||
      oldPainter.trackColor != trackColor ||
      oldPainter.segments != segments;
}
