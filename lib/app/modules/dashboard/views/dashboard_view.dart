import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scansek/app/core/theme/app_colors.dart';
import 'package:scansek/app/core/theme/app_text_styles.dart';
import 'package:scansek/app/routes/app_pages.dart';
import 'package:scansek/app/widgets/cards/custom_card.dart';
import 'package:scansek/app/widgets/dashboard/health_summary_card.dart';
import 'package:scansek/app/widgets/dashboard/sugar_tracker_card.dart';
import 'package:scansek/app/widgets/dashboard/water_tracker_card.dart';
import 'package:scansek/app/widgets/dashboard/last_food_card.dart';
import 'package:scansek/app/widgets/dashboard/menu_card.dart';
import 'package:scansek/app/widgets/loaders/shimmer_loader.dart';
import 'package:scansek/app/modules/add_water/views/add_water_bottom_sheet.dart';
import 'package:scansek/app/widgets/bottom_sheets/update_body_metrics_bottom_sheet.dart' as scansek_bottom_sheet;
import '../controllers/dashboard_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Styled AppBar with gradient and date
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF80CBC4), // Soft Teal
                  const Color(0xFF80CBC4).withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 2),
                ),
              ],
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Greeting + Name (Expanded)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Greeting with emoji
                          Text(
                            '${_getGreetingEmoji()} ${controller.greeting}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Name
                          Row(
                            children: [
                              Flexible(
                                child: Obx(() => Text(
                                  controller.userName.value.isNotEmpty
                                      ? controller.userName.value
                                      : 'User',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )),
                              ),
                              Obx(() {
                                if (controller.isFastingMode.value) {
                                  return Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.nights_stay_rounded, color: Colors.white, size: 14),
                                        SizedBox(width: 4),
                                        Text('Puasa', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Date Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _getCurrentDay(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _getCurrentDate(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Insight Lamp Icon (Edukasi Kesehatan Khusus / Manual Book)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => Get.toNamed(Routes.INSIGHT),
                        icon: const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: Obx(
              () {
                if (controller.isLoading.value && controller.stats.value == null) {
                  return _buildShimmerLoading();
                }

                if (controller.stats.value == null) {
                  return _buildError();
                }

                return RefreshIndicator(
                  onRefresh: controller.fetchDashboardData,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Weekly Metrics Update Banner
                        Obx(() {
                          if (controller.shouldShowUpdateMetricsBanner.value) {
                            return GestureDetector(
                              onTap: () {
                                Get.bottomSheet(
                                  const scansek_bottom_sheet.UpdateBodyMetricsBottomSheet(),
                                  isScrollControlled: true,
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF9C4), // Soft yellow pastel
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFFE082), width: 1),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFF57F17), size: 24),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Waktunya update MBI kamu nih! Udah lebih 1 minggu kamu ga update BB dan TB kamu.',
                                        style: TextStyle(
                                          color: Color(0xFFF57F17),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: Color(0xFFF57F17)),
                                  ],
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                        
                        // Health Summary Card (Combined Calorie & Activity)
                        HealthSummaryCard(stats: controller.stats.value!),
                        
                        const SizedBox(height: 16),

                        // Sugar Tracker Card
                        SugarTrackerCard(stats: controller.stats.value!),
                        
                        const SizedBox(height: 16),

                        // Water Tracker Card
                        WaterTrackerCard(
                          stats: controller.stats.value!,
                          lastWater: controller.lastWater.value,
                          onQuickAdd: () {
                            Get.bottomSheet(
                              const AddWaterBottomSheet(),
                              isScrollControlled: true,
                              enterBottomSheetDuration: const Duration(milliseconds: 300),
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // Last Food Card
                        LastFoodCard(food: controller.lastFood.value),

                        const SizedBox(height: 16),

                        // Menu Card
                        const MenuCard(),

                        const SizedBox(height: 80), // Extra space for FAB
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const ShimmerTrackerCard(),
          const SizedBox(height: 16),
          const ShimmerTrackerCard(),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: ShimmerTrackerCard()),
              const SizedBox(width: 16),
              const Expanded(child: ShimmerTrackerCard()),
            ],
          ),
          const SizedBox(height: 16),
          const ShimmerTrackerCard(),
          const SizedBox(height: 16),
          const ShimmerTrackerCard(),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'Yahh, Servernya lagi ngambek, coba lagi nanti yaa',
            style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: controller.fetchDashboardData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF80CBC4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Refresh',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }


  /// Show quick add water bottom sheet
  void _showQuickAddWater(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quick Add Water',
              style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [250, 500, 750, 1000].map((ml) {
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 72) / 2,
                  child: ElevatedButton(
                    onPressed: () {
                      controller.quickAddWater(ml);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '${ml}ml',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getCurrentDay() {
    const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
    return days[DateTime.now().weekday % 7];
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Selamat Pagi';
    } else if (hour < 15) {
      return 'Selamat Siang';
    } else if (hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }


  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.day} ${_getMonthName(now.month)}';
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[month - 1];
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour >= 0 && hour < 11) return '☀️'; // Pagi
    if (hour >= 11 && hour < 15) return '🌤️'; // Siang
    if (hour >= 15 && hour < 18) return '🌅'; // Sore
    return '🌙'; // Malam
  }
}
