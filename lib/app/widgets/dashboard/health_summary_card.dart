import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scansek/app/core/theme/app_colors.dart';
import 'package:scansek/app/core/theme/app_text_styles.dart';
import 'package:scansek/app/modules/main/controllers/main_controller.dart';
import 'package:scansek/app/modules/history/controllers/history_controller.dart';
import 'package:scansek/app/data/models/dashboard_stats_model.dart';
import 'dart:math' as math;

class HealthSummaryCard extends StatelessWidget {
  final DashboardStatsModel stats;

  const HealthSummaryCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    // Calorie intake stats
    final consumed = stats.calories.consumed.toInt();
    final goal = stats.calories.goal.toInt();
    
    // Activity burn stats
    final burned = stats.activity.caloriesBurned.toInt();
    final goalBurn = stats.activity.goalBurn.toInt();
    
    // Activity metrics
    final durationMinutes = stats.activity.duration.round();
    final distance = stats.activity.distance;
    final steps = stats.activity.steps;

    // Progress calculations
    final consumedProgress = goal > 0 ? (consumed / goal).clamp(0.0, 1.0) : 0.0;
    final burnedProgress = goalBurn > 0 ? (burned / goalBurn).clamp(0.0, 1.0) : 0.0;
    
    // Net Calories logic (Sisa Kalori)
    final remaining = math.max(0, goal - consumed); // Keeping it simple for UI focus

    return GestureDetector(
      onTap: () {
        final mainController = Get.find<MainController>();
        mainController.changeTab(1); // Navigate to history tab
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // Pure white background
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0), // Pale cream/orange
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.assignment_rounded,
                      color: Color(0xFFFF5722), // Deep Orange
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Kalori dan Aktivitas',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Donut chart & Stats row
              Row(
                children: [
                  // Left: Dual-Ring Donut Chart
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CustomPaint(
                      painter: DualRingDonutPainter(
                        outerProgress: burnedProgress,
                        innerProgress: consumedProgress,
                        outerColor: const Color(0xFFFF5722), // Solid Deep Orange (Terbakar)
                        innerColor: const Color(0xFFFFCC80), // Cream (Masuk)
                        outerBackgroundColor: const Color(0xFFFFCCBC), // Pale Orange
                        innerBackgroundColor: const Color(0xFFFFF3E0), // Pale Cream
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$remaining',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Kkal Sisa',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Right: Stats Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Masuk
                        _buildStatRow(
                          Icons.restaurant_rounded,
                          '$consumed / $goal Kkal',
                          'Masuk',
                          const Color(0xFFFFCC80), // Cream/Orange
                        ),
                        const SizedBox(height: 12),
                        // Terbakar
                        _buildStatRow(
                          Icons.whatshot,
                          '$burned / $goalBurn Kkal',
                          'Terbakar',
                          const Color(0xFFFF5722), // Solid Deep Orange
                        ),
                        const SizedBox(height: 12),
                        // Durasi
                        _buildStatRow(
                          Icons.timer_rounded,
                          '$durationMinutes Menit',
                          'Aktif',
                          const Color(0xFF90CAF9), // Biru soft
                        ),
                        const SizedBox(height: 12),
                        // Jarak (pakai asset icon khusus)
                        _buildStatRowAsset(
                          'assets/images/card/distance.png',
                          '${distance.toStringAsFixed(2)} KM',
                          'Jarak',
                          const Color(0xFFEF9A9A), // Merah Muda
                        ),
                        const SizedBox(height: 12),
                        // Langkah
                        _buildStatRow(
                          Icons.directions_walk_rounded,
                          '$steps Langkah',
                          'Langkah',
                          const Color(0xFF81C784), // Hijau
                        ),
                      ],
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

  Widget _buildStatRow(IconData iconData, String value, String label, Color indicatorColor, {Color? iconColor, Color? textColor}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(
            color: indicatorColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          iconData,
          size: 20,
          color: iconColor ?? indicatorColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor ?? AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: textColor ?? AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRowAsset(String assetPath, String value, String label, Color indicatorColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(
            color: indicatorColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Image.asset(
          assetPath,
          width: 20,
          height: 20,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRowEmoji(String emoji, String value, String label, Color indicatorColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(
            color: indicatorColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          emoji,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DualRingDonutPainter extends CustomPainter {
  final double outerProgress; // Masuk
  final double innerProgress; // Terbakar
  final Color outerColor;
  final Color innerColor;
  final Color outerBackgroundColor;
  final Color innerBackgroundColor;

  DualRingDonutPainter({
    required this.outerProgress,
    required this.innerProgress,
    required this.outerColor,
    required this.innerColor,
    required this.outerBackgroundColor,
    required this.innerBackgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2;
    const strokeWidth = 12.0;
    final innerRadius = outerRadius - strokeWidth - 4; // 4px gap between rings

    // Background Paints
    final outerBgPaint = Paint()
      ..color = outerBackgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final innerBgPaint = Paint()
      ..color = innerBackgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw Background Rings
    canvas.drawCircle(center, outerRadius - strokeWidth / 2, outerBgPaint);
    canvas.drawCircle(center, innerRadius - strokeWidth / 2, innerBgPaint);

    // Progress Paints
    final outerPaint = Paint()
      ..color = outerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final innerPaint = Paint()
      ..color = innerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw Outer Arc (Masuk)
    if (outerProgress > 0) {
      final sweepAngle = 2 * math.pi * outerProgress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius - strokeWidth / 2),
        -math.pi / 2,
        sweepAngle,
        false,
        outerPaint,
      );
    }

    // Draw Inner Arc (Terbakar)
    if (innerProgress > 0) {
      final sweepAngle = 2 * math.pi * innerProgress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius - strokeWidth / 2),
        -math.pi / 2,
        sweepAngle,
        false,
        innerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
