import 'package:get/get.dart';
import 'package:scansek/app/services/reminder_storage_service.dart';
import '../controllers/reminder_controller.dart';

class ReminderBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize storage service synchronously with lazy init
    // This ensures it's registered before controller tries to use it
    if (!Get.isRegistered<ReminderStorageService>()) {
      Get.put(ReminderStorageService(), permanent: true);
    }
    
    // Lazy load controller
    Get.lazyPut<ReminderController>(
      () => ReminderController(),
    );
  }
}
