import 'package:get/get.dart';
import '../controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    print('🟠 SPLASH BINDING: Creating SplashController...');
    Get.put<SplashController>(SplashController());
    print('🟠 SPLASH BINDING: SplashController created!');
  }
}
