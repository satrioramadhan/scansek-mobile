import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../../history/views/history_view.dart';
import '../../history/controllers/history_controller.dart';
import '../../profile/views/profile_view.dart';
import '../../activity_tracker/views/activity_tracker_view.dart';
import '../../activity_tracker/controllers/activity_tracker_controller.dart';
import 'package:scansek/app/modules/add_water/views/add_water_bottom_sheet.dart';
import '../controllers/main_controller.dart';
import 'offset_notched_shape.dart';
import 'smooth_notched_rectangle.dart';

class MainView extends GetView<MainController> {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: Obx(() => IndexedStack(
        index: controller.currentIndex.value,
        children: [
          // Tab 0: Dashboard
          const DashboardView(),
          
          // Tab 1: History
          const HistoryView(),
          
          // Tab 2: Scanner (handled by FAB, this is just placeholder)
          _buildPlaceholder('Scanner'),
          
          // Tab 3: Activity Tracker
          const ActivityTrackerView(),
          
          // Tab 4: Profile
          const ProfileView(),
        ],
      )),
      
      // Animated Toggle FAB - 3 States
      floatingActionButton: Obx(() {
        final fabMode = controller.currentFABMode.value;
        final currentIndex = controller.currentIndex.value;
        
        // Calculate active color based on current page
        Color activeColor = AppColors.primary;
        
        // Dashboard and Profile pages - use teal to match app bar
        if (currentIndex == 0 || currentIndex == 4) {
          activeColor = const Color(0xFF80CBC4); // Soft Teal (matches app bar)
        } else if (currentIndex == 1) {
          try {
            final historyController = Get.find<HistoryController>();
            final currentTab = historyController.currentTab.value;
            final categoryColors = [
              const Color(0xFF80CBC4), // Food - Soft Teal
              const Color(0xFF90CAF9), // Water - Soft Blue
              const Color(0xFFEF9A9A), // Sugar - Soft Pink
              const Color(0xFFFFCC80), // Calorie - Soft Orange
            ];
            if (currentTab >= 0 && currentTab < categoryColors.length) {
              activeColor = categoryColors[currentTab];
            }
          } catch (e) {
            activeColor = AppColors.primary;
          }
        } else if (currentIndex == 3) {
          // Activity tab - green
          activeColor = const Color(0xFF81C784);
        }
        
        // Determine icon and action based on FAB mode
        IconData icon;
        VoidCallback onPressed;
        String key;
        
        switch (fabMode) {
          case 0: // Scanner
            icon = Icons.qr_code_scanner_rounded;
            onPressed = controller.onFABPressed;
            key = 'scanner';
            break;
          case 1: // Add Food
            icon = Icons.restaurant;
            onPressed = () => Get.toNamed('/add-food');
            key = 'add_food';
            break;
          case 2: // Start Activity
            icon = Icons.directions_run;
            onPressed = () {
              try {
                Get.find<ActivityTrackerController>().getCurrentLocation();
              } catch (e) {
                // Controller might not be ready, ignore
              }
              Get.toNamed('/start-activity');
            };
            key = 'start_activity';
            break;
          case 3: // Add Water
            icon = Icons.local_drink_rounded;
            onPressed = () {
              Get.bottomSheet(
                const AddWaterBottomSheet(),
                 isScrollControlled: true,
                 enterBottomSheetDuration: const Duration(milliseconds: 300),
              );
            };
            key = 'add_water';
            break;
          default:
            icon = Icons.qr_code_scanner_rounded;
            onPressed = controller.onFABPressed;
            key = 'scanner';
        }
        
        return SizedBox(
          width: 65,
          height: 65,
          child: FloatingActionButton(
            backgroundColor: activeColor,
            elevation: 8,
            onPressed: onPressed,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: Icon(
                icon,
                key: ValueKey(key),
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      
      // Bottom Navigation Bar - With Notch
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          child: BottomAppBar(
            clipBehavior: Clip.antiAlias,
            shape: const OffsetNotchedShape(
              SmoothNotchedRectangle(smoothness: 45.0, cornerRadius: 24.0),
              Offset(16.0, 0),
            ),
            notchMargin: 2.0, 
            color: Colors.white,
            elevation: 8,
            shadowColor: Colors.black45,
            padding: EdgeInsets.zero,
            height: 75,
            child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
                  // Dashboard
                  _buildNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Beranda',
                    index: 0,
                  ),
              
              // History
              _buildNavItem(
                icon: Icons.history_outlined,
                activeIcon: Icons.history,
                label: 'Riwayat',
                index: 1,
              ),
              
              // Spacer for FAB
              const SizedBox(width: 48),
              
              // Activity
              _buildNavItem(
                icon: Icons.insert_chart_outlined,
                activeIcon: Icons.insert_chart,
                label: 'Aktivitas',
                index: 3,
              ),
              
              // Profile
              _buildNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profil',
                index: 4,
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    return Obx(
      () {
        final isActive = controller.currentIndex.value == index;
        final currentIndex = controller.currentIndex.value;
        
        // Calculate active color based on current page
        Color activeColor = AppColors.primary;
        
        // Dashboard and Profile pages - use teal to match app bar
        if (currentIndex == 0 || currentIndex == 4) {
          activeColor = const Color(0xFF80CBC4); // Soft Teal (matches app bar)
        } else if (currentIndex == 1) {
          try {
            final historyController = Get.find<HistoryController>();
            final currentTab = historyController.currentTab.value;
            final categoryColors = [
              const Color(0xFF80CBC4), // Food - Soft Teal
              const Color(0xFF90CAF9), // Water - Soft Blue
              const Color(0xFFEF9A9A), // Sugar - Soft Red
              const Color(0xFFFFCC80), // Calorie - Soft Orange
            ];
            activeColor = categoryColors[currentTab];
          } catch (e) {
            activeColor = AppColors.primary;
          }
        } else if (currentIndex == 3) {
          // Activity tab - green
          activeColor = const Color(0xFF81C784);
        }
        
        return InkWell(
          onTap: () => controller.changeTab(index),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? activeColor : AppColors.textHint,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: isActive ? activeColor : AppColors.textHint,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(String title) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction_outlined,
              size: 80,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              '$title belum tersedia',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
