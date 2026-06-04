import 'package:get/get.dart';
import 'package:scansek/app/data/providers/local/storage_service.dart';
import 'package:scansek/app/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:scansek/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:scansek/app/modules/profile/controllers/profile_controller.dart';
import 'package:scansek/app/widgets/snackbars/snackbar_designs.dart';

class SystemNotificationsController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final RxBool isFastingMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    isFastingMode.value = _storage.isFastingMode;
  }

  void toggleFastingMode(bool value) async {
    isFastingMode.value = value;
    await _storage.setFastingMode(value);
    
    // Also sync the visual indicators in Profile and Dashboard
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().isFastingMode.value = value;
    }
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().isFastingMode.value = value;
    }

    // Dynamically rebuild the notification schedule instantly based on new state
    await NotificationService().refreshSystemNotifications();

    // Show popup
    if (value) {
      Get.dialog(
        Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.nights_stay_rounded,
                    color: Color(0xFF1E88E5),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Mode Puasa Aktif!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3E50),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Pengingat makan & minum reguler dimatikan.\n\nJangan lupa catat asupan nutrisimu pas Sahur dan Buka ya! Semangat puasanya! 🤗',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                   width: double.infinity,
                   child: ElevatedButton(
                     onPressed: () => Get.back(),
                     style: ElevatedButton.styleFrom(
                       padding: const EdgeInsets.symmetric(vertical: 14),
                       backgroundColor: const Color(0xFF1E88E5),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(12),
                       ),
                       elevation: 0,
                     ),
                     child: const Text(
                       'Siap Laksanakan!',
                       style: TextStyle(
                         color: Colors.white,
                         fontSize: 16,
                         fontWeight: FontWeight.w600,
                       ),
                     ),
                   ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      ElegantSnackbar.success(
        Get.context,
        'Mode normal aktif. Jadwal pengingat kembali ke semula.',
      );
    }
  }
}
