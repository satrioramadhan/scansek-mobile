import 'package:get/get.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../history/controllers/history_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/main_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainController>(() => MainController());
    Get.lazyPut<DashboardController>(() => DashboardController());
    Get.lazyPut<HistoryController>(() => HistoryController());
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
