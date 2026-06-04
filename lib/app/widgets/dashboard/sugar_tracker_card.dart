import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scansek/app/core/theme/app_colors.dart';
import 'package:scansek/app/core/theme/app_text_styles.dart';
import 'package:scansek/app/modules/main/controllers/main_controller.dart';
import 'package:scansek/app/modules/history/controllers/history_controller.dart';
import 'package:scansek/app/data/models/dashboard_stats_model.dart';

class SugarTrackerCard extends StatelessWidget {
  final DashboardStatsModel stats;

  const SugarTrackerCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final current = stats.sugar.current;
    final goal = stats.sugar.goal;
    final percentage = stats.sugar.percentage();
    
    // Dynamic colors based on percentage
    Color mainColor;
    Color lightColor;
    String statusText;
    
    if (percentage < 50) {
      // Safe zone - Pink lembut
      mainColor = const Color(0xFFEF9A9A); // Soft pink
      lightColor = const Color(0xFFFCE4EC);
      statusText = 'Aman';
    } else if (percentage < 100) {
      // Warning zone - Orange lembut
      mainColor = const Color(0xFFFFCC80); // Soft orange
      lightColor = const Color(0xFFFFF3E0);
      statusText = 'Awas Sudah Setengahnya';
    } else {
      // Danger zone - Red lembut
      mainColor = const Color(0xFFEF5350); // Soft red
      lightColor = const Color(0xFFFFEBEE);
      statusText = 'Waduh Kamu Lewatin Batasnya';
    }

    return GestureDetector(
      onTap: () {
        // Use MainController to switch tab and set initial history tab
        final mainController = Get.find<MainController>();
        mainController.changeTab(1); // Navigate to History tab (index 1)
        
        // Set initial tab after navigation
        Future.delayed(const Duration(milliseconds: 100), () {
          Get.find<HistoryController>().jumpToTab(2);
        });
      },
      child: Container(
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: lightColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: mainColor.withOpacity(0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.cookie_outlined,
                    color: mainColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Pelacak Gula',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (percentage >= 50) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: lightColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          percentage >= 100 ? Icons.error_outline : Icons.warning_amber_rounded,
                          size: 12,
                          color: mainColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: AppTextStyles.caption.copyWith(
                            color: mainColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 20),

            // Main Stats
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Current
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            current.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: mainColor,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'g',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dikonsumsi',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right: Goal
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${goal.toStringAsFixed(0)}g',
                      style: AppTextStyles.h4.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Target',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (percentage / 100).clamp(0.0, 1.0),
                backgroundColor: lightColor.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(mainColor),
                minHeight: 8,
              ),
            ),

            const SizedBox(height: 8),

            // Percentage
            Text(
              '${percentage.toStringAsFixed(0)}% dari batas harian',
              style: AppTextStyles.caption.copyWith(
                color: mainColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
