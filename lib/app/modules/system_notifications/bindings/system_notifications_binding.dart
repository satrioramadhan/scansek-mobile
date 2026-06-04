import 'package:get/get.dart';
import '../controllers/system_notifications_controller.dart';

class SystemNotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SystemNotificationsController>(
      () => SystemNotificationsController(),
    );
  }
}
