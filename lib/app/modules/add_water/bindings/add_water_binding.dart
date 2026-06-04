import 'package:get/get.dart';
import '../controllers/add_water_controller.dart';

class AddWaterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddWaterController>(
      () => AddWaterController(),
    );
  }
}
