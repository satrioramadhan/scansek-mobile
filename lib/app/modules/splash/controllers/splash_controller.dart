import 'package:get/get.dart';
import '../../../data/providers/local/storage_service.dart';
import '../../../routes/app_pages.dart';

class SplashController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();

  SplashController() {
    print('🔴 SPLASH CONTROLLER: Constructor called');
  }

  @override
  void onInit() {
    super.onInit();
    print('🔴 SPLASH CONTROLLER: onInit called');
  }

  @override
  void onReady() {
    super.onReady();
    print('🔴 SPLASH CONTROLLER: onReady called');
    _checkInitialRoute();
  }

  /// Check initial route based on app state
  Future<void> _checkInitialRoute() async {
    print('🔵 SPLASH: Starting route check...');
    
    // Wait 2 seconds untuk splash animation
    await Future.delayed(const Duration(seconds: 2));

    print('🔵 SPLASH: Checking first launch...');
    print('🔵 SPLASH: isFirstLaunch = ${_storage.isFirstLaunch}');
    
    // Check if first launch
    if (_storage.isFirstLaunch) {
      // Navigate to onboarding
      print('🔵 SPLASH: Navigating to ONBOARDING');
      Get.offNamed(Routes.ONBOARDING);
      return;
    }

    print('🔵 SPLASH: Checking login status...');
    // Check if user is logged in
    final isLoggedIn = await _storage.isLoggedIn;
    print('🔵 SPLASH: isLoggedIn = $isLoggedIn');

    if (isLoggedIn) {
      // Navigate to main (dashboard with bottom nav)
      print('🔵 SPLASH: Navigating to MAIN');
      Get.offNamed(Routes.MAIN);
    } else {
      // Navigate to login
      print('🔵 SPLASH: Navigating to LOGIN');
      Get.offNamed(Routes.LOGIN);
    }
    
    print('🔵 SPLASH: Navigation completed');
  }
}
