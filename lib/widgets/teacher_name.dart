import 'package:flutter/material.dart';

import '../data/teachers.dart';
import '../theme.dart';

/// Имя преподавателя: длинное нажатие открывает полную форму ФИО
/// (Material 3 bottom sheet) с часами предмета.
class TeacherName extends StatelessWidget {
  const TeacherName({
    super.key,
    required this.subject,
    required this.teacherShort,
    required this.style,
  });

  final String subject;
  final String teacherShort;
  final TextStyle? style;

  void _show(BuildContext context) {
    final info = teacherInfoFor(subject, teacherShort);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _TeacherSheet(
        info: info,
        subject: subject,
        teacherShort: teacherShort,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _show(context),
      child: Text(teacherShort, style: style, maxLines: 1),
    );
  }
}

class _TeacherSheet extends StatelessWidget {
  const _TeacherSheet({
    required this.info,
    required this.subject,
    required this.teacherShort,
  });

  final TeacherInfo? info;
  final String subject;
  final String teacherShort;

  /// Инициалы для аватара: «КУ» из полного ФИО.
  String get _initials {
    final full = info?.fullName ?? teacherShort;
    final parts = full
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w.substring(0, 1).toUpperCase());
    return parts.join();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final info = this.info;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    _initials,
                    style: AppText.body(
                      18,
                      color: scheme.onPrimaryContainer,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info?.fullName ?? teacherShort,
                        style: AppText.heading(18, height: 24 / 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Преподаватель',
                        style:
                            AppText.body(13, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject,
                    style: AppText.body(16),
                  ),
                  if (info?.hours != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _PlanChip(
                          icon: Icons.timer_outlined,
                          label: '${info!.hours} ч',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Полное имя и план предмета — из учебного плана группы.',
              style: AppText.body(
                12,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  const _PlanChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppText.body(13, color: scheme.onSecondaryContainer),
          ),
        ],
      ),
    );
  }
}
