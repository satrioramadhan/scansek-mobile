import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scansek/app/core/theme/app_colors.dart';
import 'package:scansek/app/core/theme/app_text_styles.dart';
import 'package:scansek/app/modules/main/controllers/main_controller.dart';
import 'package:scansek/app/modules/history/controllers/history_controller.dart';
import 'package:intl/intl.dart';
import 'package:scansek/app/data/models/dashboard_stats_model.dart';
import 'package:scansek/app/data/models/water_model.dart';
import 'package:scansek/app/widgets/dashboard/realistic_water_glass.dart';

class WaterTrackerCard extends StatelessWidget {
  final DashboardStatsModel stats;
  final VoidCallback onQuickAdd;

  final WaterModel? lastWater;

  const WaterTrackerCard({
    super.key,
    required this.stats,
    required this.onQuickAdd,
    this.lastWater,
  });

  @override
  Widget build(BuildContext context) {
    final current = stats.water.current;
    final goal = stats.water.goal.toInt();

    return GestureDetector(
      onTap: () {
        final mainController = Get.find<MainController>();
        mainController.changeTab(1);
        Future.delayed(const Duration(milliseconds: 100), () {
          Get.find<HistoryController>().jumpToTab(1);
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // Pure white background
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
                      color: const Color(0xFFE3F2FD), // Light blue
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.water_drop,
                      color: Color(0xFF2196F3),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Pelacak Air',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2196F3), // Matches History AppBar (Blue 200)
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Target: ${goal}ml',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Main Number + Glass Illustration
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Number
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$current',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2196F3),
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ml',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Diminum',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right: Realistic Glass Illustration
                  RealisticWaterGlass(
                    percentage: (current / goal).clamp(0.0, 1.0),
                    width: 60,
                    height: 80,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Last Intake Info & Add Button
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Terakhir Minum',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        if (lastWater != null) ...[
                          Row(
                            children: [
                              Text(
                                '${lastWater!.amount.toInt()}ml',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF90CAF9),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '•   ${DateFormat('HH:mm').format(lastWater!.intakeTime)}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                           Text(
                             'Belum ada data',
                             style: AppTextStyles.bodyMedium.copyWith(
                               color: AppColors.textHint,
                               fontStyle: FontStyle.italic,
                             ),
                           ),
                        ],
                      ],
                    ),
                  ),
                  
                  ElevatedButton(
                    onPressed: onQuickAdd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF90CAF9),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Minum',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
