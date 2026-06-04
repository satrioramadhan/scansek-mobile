import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../data/providers/api/api_client.dart';
import '../../../../data/providers/api/api_endpoints.dart';
import '../../../../routes/app_pages.dart';
import '../../../../widgets/snackbars/snackbar_designs.dart';

class ForgotPasswordController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();

  // Form controller
  final emailController = TextEditingController();

  // Observable state
  final RxBool isLoading = false.obs;

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

  // Form attributes
  final formKey = GlobalKey<FormState>();

  /// Validate email format
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Emailnya diisi dulu ya';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format emailnya kurang pas nih';
    }
    return null;
  }

  /// Send reset OTP to email
  Future<void> sendResetOTP() async {
    // Validate Form
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      isLoading.value = true;

      final response = await _apiClient.post(
        ApiEndpoints.resendOtp,
        data: {
          'email': emailController.text.trim(),
          'purpose': 'reset_password',
        },
      );

      if (response.data['success'] == true) {
        ElegantSnackbar.success(
          Get.context,
          'Kode OTP udah dikirim ke email kamu ya',
        );

        // Navigate to verify reset OTP screen
        Get.toNamed(
          Routes.VERIFY_RESET_OTP,
          arguments: {'email': emailController.text.trim()},
        );
      }
    } catch (e) {
      ElegantSnackbar.error(Get.context, e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
