import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/local/storage_service.dart';
import '../../../routes/app_pages.dart';

class OnboardingController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final PageController pageController = PageController();

  final RxInt currentPage = 0.obs;

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  /// Handle page changed
  void onPageChanged(int page) {
    currentPage.value = page;
  }

  /// Go to next page
  void nextPage() {
    if (currentPage.value < 4) { // 5 pages: index 0-4
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      completeOnboarding();
    }
  }

  /// Skip onboarding
  void skip() {
    completeOnboarding();
  }

  /// Complete onboarding and navigate to login
  Future<void> completeOnboarding() async {
    // Mark first launch as false
    await _storage.setFirstLaunch(false);

    // Navigate to login
    Get.offAllNamed(Routes.LOGIN);
  }
}
