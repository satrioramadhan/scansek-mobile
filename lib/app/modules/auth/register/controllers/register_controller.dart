import 'package:flutter/material.dart';
import '../../../../core/utils/bmi_helper.dart';
import 'package:get/get.dart';
import 'package:scansek/app/widgets/states/error_state.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/utils/validators.dart';
import '../../../../data/providers/api/api_client.dart';
import '../../../../data/providers/api/api_endpoints.dart';
import '../../../../data/providers/api/network_exception.dart';
import '../../../../routes/app_pages.dart';
import '../../../../widgets/snackbars/snackbar_designs.dart';

class RegisterController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();

  // Form controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();

  // Form key
  final formKey = GlobalKey<FormState>();

  // Observable states
  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;
  
  // Date of birth
  final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);
  
  // Gender
  final RxString selectedGender = 'male'.obs;

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    weightController.dispose();
    heightController.dispose();
    super.onClose();
  }

  /// Toggle password visibility
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  /// Toggle confirm password visibility
  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  /// Select date of birth
  Future<void> selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF00BFA5), // AppColors.primary
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      selectedDate.value = picked;
    }
  }

  /// Validate and register
  Future<void> register() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    // Validate date of birth
    if (selectedDate.value == null) {
      ElegantSnackbar.error(Get.context, 'Tanggal lahirnya diisi dulu ya');
      return;
    }

    final dobError = Validators.dateOfBirth(selectedDate.value);
    if (dobError != null) {
      ElegantSnackbar.error(Get.context, dobError);
      return;
    }

    isLoading.value = true;

    try {
      final weight = double.parse(weightController.text);
      final height = double.parse(heightController.text);

      // Format date as YYYY-MM-DD (API expects this format, not ISO8601)
      final formattedDate = 
          '${selectedDate.value!.year.toString().padLeft(4, '0')}-'
          '${selectedDate.value!.month.toString().padLeft(2, '0')}-'
          '${selectedDate.value!.day.toString().padLeft(2, '0')}';

      // Calculate BMI and default goals before sending to API
      final bmi = BMIHelper.hitungBMI(weight, height);
      final category = BMIHelper.getCategory(bmi);

      final response = await _apiClient.post(
        ApiEndpoints.register,
        data: {
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text,
          'dateOfBirth': formattedDate,
          'gender': selectedGender.value,
          'weight': weight,
          'height': height,
          'dailySugarGoal': category.defaultSugar.toInt(),
          'dailyCalorieGoal': category.defaultCalories.toInt(),
          'dailyWaterGoal': category.defaultWater.toInt(),
          'dailyBurnGoal': category.defaultBurn,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Navigate to OTP verification
        ElegantSnackbar.success(
          Get.context,
          'Registrasi berhasil! Cek email kamu buat verifikasi ya.',
        );

        await Future.delayed(const Duration(milliseconds: 500));

        Get.offNamed(
          Routes.OTP_VERIFICATION,
          arguments: {
            'email': emailController.text.trim(),
            'fromLogin': false,
          },
        );
      }
    } on ValidationException catch (e) {
      ElegantSnackbar.error(Get.context, e.message);
    } on NetworkException catch (e) {
      ErrorSnackbar.show(Get.context!, e.message);
    } catch (e) {
      ElegantSnackbar.error(Get.context, 'Waduh, ada error nih');
    } finally {
      isLoading.value = false;
    }
  }

  /// Navigate to login
  void goToLogin() {
    Get.back();
  }
}
