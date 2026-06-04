import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Empty state widget dengan icon dan message
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
    this.action,
  });

  /// Empty state untuk food history
  const EmptyState.foodHistory({
    super.key,
    this.action,
  })  : icon = Icons.restaurant_outlined,
        message = 'Belum ada data makanan nih',
        subtitle = null;

  /// Empty state untuk water history
  const EmptyState.waterHistory({
    super.key,
    this.action,
  })  : icon = Icons.water_drop_outlined,
        message = 'Belum ada data minum nih',
        subtitle = null;

  /// Empty state untuk activity history
  const EmptyState.activityHistory({
    super.key,
    this.action,
  })  : icon = Icons.directions_run_outlined,
        message = 'Belum ada aktivitas nih',
        subtitle = null;

  /// Empty state untuk reminders
  const EmptyState.reminders({
    super.key,
    this.action,
  })  : icon = Icons.notifications_none_outlined,
        message = 'Belum ada pengingat nih',
        subtitle = null;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: AppColors.gray400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.h4.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textHint,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
