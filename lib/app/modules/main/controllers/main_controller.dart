import 'package:get/get.dart';
import 'dart:async';
import '../../activity_tracker/controllers/activity_tracker_controller.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../history/controllers/history_controller.dart';

class MainController extends GetxController {
  // Current tab index
  final RxInt currentIndex = 0.obs;
  
  // FAB 3-state mode: 0=scanner, 1=add food, 2=start activity
  final RxInt currentFABMode = 0.obs;
  Timer? _fabTimer;

  @override
  void onInit() {
    super.onInit();
    
    // Init ActivityTrackerController for tab 3
    Get.put(ActivityTrackerController());
    
    // Toggle FAB every 2 seconds (3 states)
    _fabTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      currentFABMode.value = (currentFABMode.value + 1) % 4;
    });
    
    // Listen to tab changes - refresh dashboard when switching to it
    ever(currentIndex, (index) {
      if (index == 0) {
        // Dashboard tab - refresh user name
        try {
          final dashboardController = Get.find<DashboardController>();
          dashboardController.fetchDashboardData();
        } catch (e) {
          // Controller not initialized yet, ignore
        }
      } else if (index == 1) {
        // History tab - refresh data for today
        try {
          if (Get.isRegistered<HistoryController>()) {
            final historyController = Get.find<HistoryController>();
            historyController.changeDate(DateTime.now());
          }
        } catch (e) {
          print('Error refreshing history: $e');
        }
      } else if (index == 3) {
        // Activity Tracker tab - refresh data and goal
        try {
          final activityController = Get.find<ActivityTrackerController>();
          activityController.loadUserGoal(); // Sync goal
          activityController.fetchActivitiesForDate(activityController.selectedDate.value); // Refresh list
        } catch (e) {
          print('Error refreshing activity tracker: $e');
        }
      }
    });
  }

  @override
  void onClose() {
    _fabTimer?.cancel();
    super.onClose();
  }

  // Change tab
  void changeTab(int index) {
    currentIndex.value = index;
  }
  
  // Handle FAB action
  void onFABPressed() {
    Get.toNamed('/scanner');
  }
}
