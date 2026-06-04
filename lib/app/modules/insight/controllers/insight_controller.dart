import 'package:get/get.dart';
import '../../../data/providers/local/storage_service.dart';
import '../../../core/utils/bmi_helper.dart';

import 'package:flutter/material.dart';

class InsightController extends GetxController {
  final Rx<BMICategory?> currentBMICategory = Rx<BMICategory?>(null);
  final StorageService _storage = StorageService();
  
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;
  
  @override
  void onInit() {
    super.onInit();
    _loadBMICategory();
  }
  
  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
  
  Future<void> _loadBMICategory() async {
    try {
      final user = await _storage.getUserData();
      if (user != null) {
        // Handle variations in JSON structure (e.g. nested data or direct properties)
        final weight = (user['weight'] ?? 0.0) as double;
        final height = (user['height'] ?? 0.0) as double;
        
        if (weight > 0 && height > 0) {
           final bmiValue = BMIHelper.hitungBMI(weight, height);
           currentBMICategory.value = BMIHelper.getCategory(bmiValue);
        }
      }
    } catch (e) {
      print('Could not load BMI category dynamically: $e');
    }
  }
}

