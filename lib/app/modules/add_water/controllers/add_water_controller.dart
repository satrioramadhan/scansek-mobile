import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scansek/app/widgets/states/error_state.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/providers/api/api_client.dart';
import '../../../data/providers/api/api_endpoints.dart';
import '../../../data/providers/api/network_exception.dart';
import '../../../widgets/snackbars/snackbar_designs.dart';
import '../../../data/providers/local/storage_service.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../history/controllers/history_controller.dart';
import '../../../services/notification_service.dart';

class AddWaterController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();

  // Form controllers
  final amountController = TextEditingController();

  // Observable states
  final RxBool isLoading = false.obs;
  final Rx<DateTime> intakeTime = DateTime.now().obs;

  @override
  void onClose() {
    amountController.dispose();
    super.onClose();
  }

  /// Set preset amount
  void setAmount(int amount) {
    amountController.text = amount.toString();
  }

  /// Select intake time
  Future<void> selectTime(BuildContext context) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(intakeTime.value),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF90CAF9),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null) {
      final now = DateTime.now();
      intakeTime.value = DateTime(
        now.year,
        now.month,
        now.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    }
  }

  /// Save water intake
  Future<void> saveWater() async {
    if (amountController.text.isEmpty) {
      ElegantSnackbar.error(Get.context, 'Masukkin dulu jumlah airnya');
      return;
    }

    final amount = int.tryParse(amountController.text);
    if (amount == null || amount <= 0) {
      ElegantSnackbar.error(Get.context, 'Jumlah airnya ngaco nih');
      return;
    }

    isLoading.value = true;

    try {
      final response = await _apiClient.post(
        ApiEndpoints.addWater,
        data: {
          'amount': amount,
          'intakeTime': intakeTime.value.toIso8601String(),
        },
      );

      if (response.statusCode == 201) {
        ElegantSnackbar.success(Get.context, 'Yeay! Air minum berhasil dicatat');
        
        // Refresh dashboard if exists
        try {
          if (Get.isRegistered<DashboardController>()) {
            Get.find<DashboardController>().fetchDashboardData();
          }
        } catch (e) {}
        
        // Refresh history if exists
        try {
          if (Get.isRegistered<HistoryController>()) {
            Get.find<HistoryController>().fetchHistory();
          }
        } catch (e) {}

        // Simpan timestamp & refresh notif
        await StorageService().setLastWaterInputTime(DateTime.now());
        await NotificationService().refreshSystemNotifications();

        Get.back();
      }
    } on NetworkException catch (e) {
      ErrorSnackbar.show(Get.context!, e.message);
    } catch (e) {
      ElegantSnackbar.error(Get.context, 'Yahh, gagal simpan data');
    } finally {
      isLoading.value = false;
    }
  }
}
