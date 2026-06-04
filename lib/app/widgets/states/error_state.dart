import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../buttons/custom_button.dart';
import '../snackbars/snackbar_designs.dart';

/// Error state widget dengan retry button
class ErrorState extends StatelessWidget {
  final String message;
  final String? subtitle;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorState({
    super.key,
    required this.message,
    this.subtitle,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  /// Network error state
  const ErrorState.network({
    super.key,
    this.onRetry,
  })  : message = 'Koneksi internet bermasalah nih',
        subtitle = null,
        icon = Icons.wifi_off_outlined;

  /// Server error state
  const ErrorState.server({
    super.key,
    this.onRetry,
  })  : message = 'Server lagi bermasalah, coba lagi nanti ya',
        subtitle = null,
        icon = Icons.cloud_off_outlined;

  /// Unknown error state
  const ErrorState.unknown({
    super.key,
    this.onRetry,
  })  : message = 'Waduh, ada error nih',
        subtitle = null,
        icon = Icons.error_outline;

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
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.h4.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              CustomButton.outlined(
                text: 'Coba Lagi',
                onPressed: onRetry,
                icon: Icons.refresh,
                width: 160,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error snackbar helper - Using Elegant Design
class ErrorSnackbar {
  ErrorSnackbar._();

  static void show(BuildContext? context, String message) {
    ElegantSnackbar.error(context, message);
  }
}

/// Success snackbar helper - Using Elegant Design
class SuccessSnackbar {
  SuccessSnackbar._();

  static void show(BuildContext? context, String message) {
    ElegantSnackbar.success(context, message);
  }
}
