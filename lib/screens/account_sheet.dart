import 'package:flutter/material.dart';

import '../data/schedule_data.dart';
import '../theme.dart';

/// Меню аккаунта: открывается тапом по аватару «ПО» на главной.
///
/// Пока это заглушка — пункт «Настройки» рабочий, «Аккаунт» появится позже.
Future<void> showAccountSheet(
  BuildContext context, {
  required VoidCallback onOpenSettings,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => _AccountSheet(onOpenSettings: onOpenSettings),
  );
}

class _AccountSheet extends StatelessWidget {
  const _AccountSheet({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Заглушка профиля.
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    'ПО',
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Профиль студента',
                              style: AppText.heading(18, height: 24 / 18),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Скоро',
                              style: AppText.body(
                                12,
                                color: scheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Студент · $kGroupName',
                        style:
                            AppText.body(13, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _MenuTile(
              icon: Icons.school_outlined,
              title: 'Аккаунт',
              subtitle: 'Вход и профиль',
              onTap: null, // заглушка
            ),
            const SizedBox(height: 8),
            _MenuTile(
              icon: Icons.palette_outlined,
              title: 'Настройки',
              subtitle: 'Тема, гамма и ширина текста',
              onTap: () {
                Navigator.of(context).pop();
                onOpenSettings();
              },
            ),
            const SizedBox(height: 12),
            Text(
              'StudMate · версия 1.0',
              textAlign: TextAlign.center,
              style: AppText.body(12, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final enabled = onTap != null;

    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: scheme.surface.withValues(alpha: 0.55),
                child: Icon(
                  icon,
                  color: enabled
                      ? scheme.onSurfaceVariant
                      : scheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.body(16),
                    ),
                    Text(
                      subtitle,
                      style: AppText.body(13, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: enabled
                    ? scheme.onSurfaceVariant
                    : scheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
