import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../data/providers/api/api_client.dart';
import '../../../../data/providers/api/api_endpoints.dart';
import '../../../../routes/app_pages.dart';
import '../../../../widgets/snackbars/snackbar_designs.dart'; // Import ElegantSnackbar

class ResetPasswordController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();

  // Form controllers
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Data from previous screens
  late String email;
  late String resetToken;

  // Observable states
  final RxBool isLoading = false.obs;
  final RxBool isNewPasswordVisible = false.obs;
  final RxBool isConfirmVisible = false.obs;

  // Form key
  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    // Get email and resetToken from arguments
    final args = Get.arguments as Map<String, dynamic>?;
    email = args?['email'] ?? '';
    resetToken = args?['resetToken'] ?? '';
  }

  @override
  void onClose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  /// Toggle new password visibility
  void toggleNewPasswordVisibility() {
    isNewPasswordVisible.value = !isNewPasswordVisible.value;
  }

  /// Toggle confirm password visibility
  void toggleConfirmVisibility() {
    isConfirmVisible.value = !isConfirmVisible.value;
  }

  /// Validate password
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Passwordnya diisi dulu ya';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter ya';
    }
    return null;
  }

  /// Validate confirm password
  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi passwordnya diisi juga dong';
    }
    if (value != newPasswordController.text) {
      return 'Passwordnya nggak sama nih';
    }
    return null;
  }

  /// Reset password
  Future<void> resetPassword() async {
    // Validate Form
    if (!formKey.currentState!.validate()) {
      return;
    }

    try {
      isLoading.value = true;

      final response = await _apiClient.post(
        ApiEndpoints.resetPassword,
        data: {
          'email': email,
          'resetToken': resetToken,
          'newPassword': newPasswordController.text,
        },
      );

      if (response.data['success'] == true) {
        //Set loading to false FIRST before navigation
        isLoading.value = false;

        ElegantSnackbar.success(
          Get.context,
          'Password berhasil direset! Login pake password baru ya.',
        );

        // Wait for snackbar
        await Future.delayed(const Duration(milliseconds: 500));

        // Use offNamed instead of offAllNamed to prevent clearing all routes
        // This ensures LoginController stays alive during navigation
        Get.offNamed(Routes.LOGIN);
        
        return; // Early return to prevent finally block
      }
    } catch (e) {
      ElegantSnackbar.error(Get.context, e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
