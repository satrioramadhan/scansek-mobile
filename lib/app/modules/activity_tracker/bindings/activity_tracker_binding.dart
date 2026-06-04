import 'package:get/get.dart';

import '../controllers/activity_tracker_controller.dart';

class ActivityTrackerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ActivityTrackerController>(
      () => ActivityTrackerController(),
    );
  }
}
