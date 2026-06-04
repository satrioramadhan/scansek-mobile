import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../../data/providers/api/api_client.dart';
import '../../../../data/providers/api/api_endpoints.dart';
import '../../../../routes/app_pages.dart';
import '../../../../widgets/snackbars/snackbar_designs.dart';

class VerifyResetOtpController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();

  // Form controller
  final otpController = TextEditingController();

  // Email from previous screen
  late String email;

  // Observable states
  final RxBool isLoading = false.obs;
  final RxBool isResending = false.obs;
  final RxInt countdown = 60.obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    // Get email from arguments
    final args = Get.arguments as Map<String, dynamic>?;
    email = args?['email'] ?? '';

    // Start countdown
    _startCountdown();
  }

  @override
  void onClose() {
    otpController.dispose();
    _timer?.cancel();
    super.onClose();
  }

  /// Start countdown timer
  void _startCountdown() {
    countdown.value = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value > 0) {
        countdown.value--;
      } else {
        timer.cancel();
      }
    });
  }

  /// Resend OTP
  Future<void> resendOTP() async {
    if (countdown.value > 0) {
      ElegantSnackbar.warning(
        Get.context,
        'Tunggu ${countdown.value} detik dulu ya buat kirim ulang',
      );
      return;
    }

    try {
      isResending.value = true;

      final response = await _apiClient.post(
        ApiEndpoints.resendOtp,
        data: {
          'email': email,
          'purpose': 'reset_password',
        },
      );

      if (response.data['success'] == true) {
        ElegantSnackbar.success(
          Get.context,
          'Kode OTP udah dikirim ulang ya',
        );

        _startCountdown();
      }
    } catch (e) {
      ElegantSnackbar.error(Get.context, e.toString());
    } finally {
      isResending.value = false;
    }
  }

  /// Verify reset OTP
  Future<void> verifyResetOTP() async {
    final otp = otpController.text.trim();

    if (otp.length != 6) {
      ElegantSnackbar.error(Get.context, 'Kode OTP harus 6 digit ya');
      return;
    }

    try {
      isLoading.value = true;

      final response = await _apiClient.post(
        ApiEndpoints.verifyResetOtp,
        data: {
          'email': email,
          'otp': otp,
        },
      );

      if (response.data['success'] == true) {
        final resetToken = response.data['data']?['resetToken'];
        
        if (resetToken != null) {
          ElegantSnackbar.success(
            Get.context,
            'OTP bener! Lanjut reset password yuk',
          );

          // Navigate to reset password screen with resetToken
          Get.offNamed(
            Routes.RESET_PASSWORD,
            arguments: {
              'email': email,
              'resetToken': resetToken,
            },
          );
        } else {
          ElegantSnackbar.error(Get.context, 'Token reset nggak ketemu nih');
        }
      }
    } catch (e) {
      ElegantSnackbar.error(Get.context, e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
