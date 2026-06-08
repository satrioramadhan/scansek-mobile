import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/providers/api/api_client.dart';
import '../../../../data/providers/local/storage_service.dart';
import '../../../../routes/app_pages.dart';
import '../../../../widgets/snackbars/snackbar_designs.dart';

class CompleteProfileController extends GetxController {
  final _apiClient = ApiClient();
  late final StorageService _storage;

  // Controllers
  final weightController = TextEditingController();
  final heightController = TextEditingController();

  // Observables
  final selectedDate = Rx<DateTime?>(null);
  final selectedGender = 'male'.obs;
  final isLoading = false.obs;
  final userName = ''.obs;

  // Form key
  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    _initStorage();
  }

  Future<void> _initStorage() async {
    _storage = StorageService();
    await _storage.init();
    
    // Get user name from storage
    final userData = await _storage.getUserData();
    if (userData != null && userData['name'] != null) {
      userName.value = userData['name'];
    }
  }

  /// Select date of birth
  Future<void> selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF80CBC4),
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

  /// Complete profile and save to backend
  Future<void> completeProfile(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    if (selectedDate.value == null) {
      ElegantSnackbar.error(context, 'Tanggal lahirnya diisi dulu ya');
      return;
    }

    final weight = double.tryParse(weightController.text);
    final height = double.tryParse(heightController.text);

    if (weight == null || height == null) {
      ElegantSnackbar.error(context, 'Berat sama tinggi badan harus bener ya');
      return;
    }

    try {
      isLoading.value = true;

      // Format date as YYYY-MM-DD (same format as register)
      final dateOfBirth =
          '${selectedDate.value!.year.toString().padLeft(4, '0')}-${selectedDate.value!.month.toString().padLeft(2, '0')}-${selectedDate.value!.day.toString().padLeft(2, '0')}';

      final response = await _apiClient.put('/users/profile', data: {
        'weight': weight,
        'height': height,
        'dateOfBirth': dateOfBirth,
        'gender': selectedGender.value,
      });

      if (response.statusCode == 200) {
        ElegantSnackbar.success(
          context,
          'Profil kamu udah lengkap nih!',
        );

        // Navigate to main/dashboard
        Future.delayed(const Duration(milliseconds: 800), () {
          Get.offAllNamed(Routes.MAIN);
        });
      } else {
        ElegantSnackbar.error(
          context,
          response.data['message'] ?? 'Yah, gagal simpen profil nih',
        );
      }
    } catch (e) {
      print('Error completing profile: $e');
      ElegantSnackbar.error(
        context,
        'Gagal menyimpan profil: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    weightController.dispose();
    heightController.dispose();
    super.onClose();
  }
}
