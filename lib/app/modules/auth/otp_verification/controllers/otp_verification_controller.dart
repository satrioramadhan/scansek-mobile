import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/validators.dart';
import '../../../../data/providers/api/api_client.dart';
import '../../../../data/providers/api/api_endpoints.dart';
import '../../../../data/providers/api/network_exception.dart';
import '../../../../data/providers/local/storage_service.dart';
import '../../../../routes/app_pages.dart';
import '../../../../widgets/states/error_state.dart';

class OtpVerificationController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();
  final StorageService _storage = Get.find<StorageService>();

  // Form controllers
  final otpController = TextEditingController();

  // Form key
  final formKey = GlobalKey<FormState>();

  // Observable states
  final RxBool isLoading = false.obs;
  final RxInt countdown = 60.obs;
  final RxBool canResend = false.obs;

  // Get email from arguments
  String email = '';
  bool fromLogin = false;

  @override
  void onInit() {
    super.onInit();
    
    // Get email from arguments
    final args = Get.arguments as Map<String, dynamic>?;
    email = args?['email'] ?? '';
    fromLogin = args?['fromLogin'] ?? false;

    // Auto-request OTP saat pertama kali masuk screen JIKA dari login
    // karena kalau dari register, API register sudah mengirim OTP secara otomatis
    if (fromLogin) {
      _autoRequestOTP();
    }

    // Start countdown
    startCountdown();
  }

  /// Auto-request OTP when screen opens
  Future<void> _autoRequestOTP() async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.resendOtp,
        data: {
          'email': email,
          'purpose': 'verification', // Fixed: harus verification bukan registration
        },
      );

      if (response.statusCode == 200) {
        print('✅ OTP automatically sent to $email');
      }
    } catch (e) {
      print('❌ Auto-request OTP failed: $e');
      // Silent fail - user can still manually resend
    }
  }

  @override
  void onClose() {
    otpController.dispose();
    super.onClose();
  }

  /// Start countdown timer for resend OTP
  void startCountdown() {
    countdown.value = 60;
    canResend.value = false;

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (countdown.value > 0) {
        countdown.value--;
        return true;
      } else {
        canResend.value = true;
        return false;
      }
    });
  }

  /// Verify OTP
  Future<void> verifyOtp() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    try {
      final response = await _apiClient.post(
        ApiEndpoints.verifyOtp,
        data: {
          'email': email,
          'otp': otpController.text.trim(),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        
        // Extract message from backend (with fallback)
        final message = response.data['message'] ?? 
                        'Yeayy! Email udah diverifikasi, selamat datang!';

        // Save tokens (dari OTP verification juga dapet token)
        if (data['accessToken'] != null) {
          await _storage.saveAccessToken(data['accessToken']);
          await _storage.saveRefreshToken(data['refreshToken']);
          await _storage.saveUserData(data['user']);

          // Navigate to main (dashboard with bottom nav)
          SuccessSnackbar.show(Get.context, message);
          
          await Future.delayed(const Duration(milliseconds: 500));
          Get.offAllNamed(Routes.MAIN);
        } else {
          // Just verification success, navigate to login
          SuccessSnackbar.show(Get.context, message);
          
          await Future.delayed(const Duration(milliseconds: 500));
          Get.offAllNamed(Routes.LOGIN);
        }
      }
    } on ValidationException catch (e) {
      ErrorSnackbar.show(Get.context, e.message);
    } on NetworkException catch (e) {
      ErrorSnackbar.show(Get.context, e.message);
    } catch (e) {
      ErrorSnackbar.show(Get.context, 'Waduh, ada error nih');
    } finally {
      isLoading.value = false;
    }
  }

  /// Resend OTP
  Future<void> resendOtp() async {
    if (!canResend.value) return;

    isLoading.value = true;

    try {
      final response = await _apiClient.post(
        ApiEndpoints.resendOtp,
        data: {
          'email': email,
          'purpose': 'verification', // Fixed: harus verification
        },
      );

      if (response.statusCode == 200) {
        final message = response.data['message'] ?? 
                        'Kode OTP udah dikirim ulang ke email kamu.';
        SuccessSnackbar.show(Get.context, message);

        // Restart countdown
        startCountdown();
        
        // Clear input
        otpController.clear();
      }
    } on NetworkException catch (e) {
      ErrorSnackbar.show(Get.context, e.message);
    } catch (e) {
      ErrorSnackbar.show(Get.context, 'Waduh, ada error nih');
    } finally {
      isLoading.value = false;
    }
  }
}
