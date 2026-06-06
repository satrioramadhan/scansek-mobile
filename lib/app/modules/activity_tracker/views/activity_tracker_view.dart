import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scansek/app/modules/activity_tracker/controllers/activity_tracker_controller.dart';
import 'package:scansek/app/core/theme/app_colors.dart';
import 'package:scansek/app/core/theme/app_text_styles.dart';
import 'package:intl/intl.dart';
import 'package:scansek/app/data/models/dashboard_stats_model.dart';
import 'package:scansek/app/widgets/dashboard/health_summary_card.dart';
import 'package:scansek/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'dart:math' as math;
import 'package:scansek/app/widgets/snackbars/snackbar_designs.dart';
class ActivityTrackerView extends GetView<ActivityTrackerController> {
  const ActivityTrackerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Aktivitas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF81C784), // Activity Green
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.fetchActivitiesForDate(controller.selectedDate.value);
          await controller.loadUserGoal(); // Refresh goal from storage
        },
        color: const Color(0xFF81C784), // Activity Green
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              sliver: SliverToBoxAdapter(
                child: _buildActivityProgressCard(context),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyCalendarDelegate(
                minHeight: 88,
                maxHeight: 88,
                child: Container(
                  color: AppColors.background, // Match background to hide scrolling items underneath
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildHorizontalCalendar(),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: _buildActivityList(),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }

  /// Custom Activity Progress Card - updates with selected date
  Widget _buildActivityProgressCard(BuildContext context) {
    return Obx(() {
      // Calculate stats from selected date activities
      int totalSteps = 0;
      int walkingSteps = 0;
      int joggingSteps = 0;
      int totalDurationMinutes = 0; // Add duration calculation
      double totalCaloriesBurned = 0.0;
      double totalDistance = 0.0;

      for (var activity in controller.activitiesForDate) {
        final steps = activity['steps'] as int? ?? 0;
        totalSteps += steps;
        
        final calories = (activity['caloriesBurned'] as num?)?.toDouble() ?? 0.0;
        totalCaloriesBurned += calories;
        
        final dist = (activity['distance'] as num?)?.toDouble() ?? 0.0;
        totalDistance += dist;
        
        // Calculate duration from activity (handle both int and double from backend)
        // Use round() not toInt() — toInt() truncates (0.9 min → 0), round() → 1
        final durationValue = activity['duration'];
        final duration = (durationValue as num?)?.round() ?? 0;
        totalDurationMinutes += duration;
        
        if (activity['type'] == 'walking') {
          walkingSteps += steps;
        } else if (activity['type'] == 'jogging') {
          joggingSteps += steps;
        }
      }
      
      // Construct ActivityStatsModel for the card
      final goal = controller.dailyBurnGoal.value;
      final activityStats = ActivityStatsModel(
        duration: totalDurationMinutes.toDouble(),
        steps: totalSteps,
        distance: totalDistance,
        caloriesBurned: totalCaloriesBurned,
        goalSteps: 0,
        goalBurn: goal,
        walkingSteps: walkingSteps,
        joggingSteps: joggingSteps,
      );
      
      final dashboardController = Get.isRegistered<DashboardController>() ? Get.find<DashboardController>() : null;
      final dashboardStats = dashboardController?.stats.value;

      final mockDashboardStats = DashboardStatsModel(
        date: controller.selectedDate.value,
        calories: CalorieStatsModel(
          consumed: controller.consumedCaloriesForDate.value, 
          burned: totalCaloriesBurned, 
          goal: dashboardStats?.calories.goal ?? 2000.0,
        ),
        sugar: dashboardStats?.sugar ?? const SugarStatsModel(consumed: 0, goal: 50),
        water: dashboardStats?.water ?? const WaterStatsModel(consumed: 0, goal: 2000),
        activity: activityStats,
      );
      
      return HealthSummaryCard(stats: mockDashboardStats);
    });
  }
  
  Widget _buildSmallTooltipBubble(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFC8E6C9), // Light green background
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF388E3C), // Dark green text
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  String _getLayerLabel(int layer, int walkingSteps, int joggingSteps) {
    switch (layer) {
      case 1:
        return 'Base Layer';
      case 2:
        return 'Jogging + Walking';
      case 3:
        return walkingSteps > joggingSteps ? 'Walking' : 'Jogging';
      case 4:
        return walkingSteps < joggingSteps ? 'Walking' : 'Jogging';
      default:
        return '';
    }
  }
  
  Widget _buildActivityPill(String label, int steps, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent, // Transparent background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2), // Green border
      ),
      child: Text(
        '$label : $steps',
        style: TextStyle(
          color: color, // Green text
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  Widget _buildActivityStatCompact(String emoji, String steps, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  steps,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActivityStatInCard(String emoji, String value, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }


  /// Horizontal Calendar (date selector)
  Widget _buildHorizontalCalendar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() {
        final selectedDate = controller.selectedDate.value;
        final today = DateTime.now();
        
        // Generate 14 days (7 past + today + 6 future)
        final dates = List.generate(14, (index) {
          return today.subtract(Duration(days: 7 - index));
        });
        
        return ListView.builder(
          controller: controller.calendarScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: dates.length,
          itemBuilder: (context, index) {
            final date = dates[index];
            final isSelected = DateFormat('yyyy-MM-dd').format(date) ==
                DateFormat('yyyy-MM-dd').format(selectedDate);
            final isToday = DateFormat('yyyy-MM-dd').format(date) ==
                DateFormat('yyyy-MM-dd').format(today);
            
            // Indonesian day names
            const dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
            final dayName = dayNames[date.weekday % 7];
            
            return GestureDetector(
              onTap: () => controller.selectDate(date),
              child: Container(
                width: 60,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF81C784) // Activity Green
                      : (isToday ? const Color(0xFF81C784).withOpacity(0.1) : Colors.transparent),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isToday && !isSelected
                        ? const Color(0xFF81C784).withOpacity(0.3)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayName,
                      style: AppTextStyles.caption.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('d').format(date),
                      style: AppTextStyles.h3.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  /// Activity List for selected date
  Widget _buildActivityList() {
    return Obx(() {
      final activities = controller.activitiesForDate;
      
      if (controller.isLoading.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        );
      }
      
      final listContent = activities.isEmpty 
        ? Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.directions_run,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada aktivitas',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return _buildActivityCard(activity);
            },
          );
      
      return Column(
        children: [

          listContent,
        ],
      );
    });
  }

  bool _isOutdoorActivity(Map<String, dynamic> activity) {
    return (activity['category'] as String? ?? 'outdoor') == 'outdoor';
  }

  String _formatActivityType(String type) {
    if (type.isEmpty) return type;
    return type[0].toUpperCase() + type.substring(1).toLowerCase();
  }

  /// Individual Activity Card
  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final typeStr = activity['type']?.toString() ?? 'walking';
    final isOutdoor = _isOutdoorActivity(activity);
    final source = activity['source']?.toString() ?? 'manual';
    
    // Use Controller for label
    final displayType = ActivityTrackerController.getActivityLabel(typeStr);

    // Dynamic icon and color from controller
    final iconData = ActivityTrackerController.getActivityIcon(typeStr);
    Color iconColor = isOutdoor ? const Color(0xFFFFA726) : const Color(0xFF42A5F5);
    Color bgColor = isOutdoor ? const Color(0xFFFFF3E0) : const Color(0xFFE3F2FD);
    
    return GestureDetector(
      onTap: () => controller.showActivityDetail(activity),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                iconData,
                color: iconColor,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayType,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isOutdoor ? Colors.orange[50] : Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isOutdoor ? Colors.orange[200]! : Colors.blue[200]!,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          isOutdoor ? 'OUTDOOR' : 'INDOOR',
                          style: TextStyle(
                            fontSize: 9,
                            color: isOutdoor ? Colors.orange[800] : Colors.blue[800],
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(activity['startTime']),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.whatshot,
                      size: 16,
                      color: Color(0xFFFF5722),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${activity['caloriesBurned']?.toStringAsFixed(0) ?? '0'} kcal',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${activity['duration']?.toStringAsFixed(0) ?? '0'} menit',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(dynamic timeString) {
    try {
      var ts = timeString.toString();
      if (!ts.endsWith('Z')) ts += 'Z';
      final time = DateTime.parse(ts).toLocal();
      return DateFormat('HH:mm').format(time);
    } catch (e) {
      return '--:--';
    }
  }
}

// Activity Donut Chart Painter (jogging vs walking)
class ActivityDonutChartPainter extends CustomPainter {
  final double joggingPercentage;
  final double walkingPercentage;
  final Color joggingColor;
  final Color walkingColor;
  final Color backgroundColor;

  ActivityDonutChartPainter({
    required this.joggingPercentage,
    required this.walkingPercentage,
    required this.joggingColor,
    required this.walkingColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = 12.0;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    // Jogging arc
    final joggingPaint = Paint()
      ..color = joggingColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final joggingSweepAngle = 2 * math.pi * joggingPercentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2, // Start from top
      joggingSweepAngle,
      false,
      joggingPaint,
    );

    // Walking arc - continues after jogging
    final walkingPaint = Paint()
      ..color = walkingColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final walkingSweepAngle = 2 * math.pi * walkingPercentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2 + joggingSweepAngle, // Start after jogging
      walkingSweepAngle,
      false,
      walkingPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _StickyCalendarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;

  _StickyCalendarDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyCalendarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxExtent ||
           minHeight != oldDelegate.minExtent ||
           child != oldDelegate.child;
  }
}
