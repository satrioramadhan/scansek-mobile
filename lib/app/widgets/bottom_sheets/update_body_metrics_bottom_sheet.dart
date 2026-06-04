import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scansek/app/core/theme/app_colors.dart';
import 'package:scansek/app/core/theme/app_text_styles.dart';
import 'package:scansek/app/modules/profile/controllers/profile_controller.dart';
import 'package:scansek/app/widgets/inputs/custom_text_field.dart';

class UpdateBodyMetricsBottomSheet extends StatefulWidget {
  const UpdateBodyMetricsBottomSheet({super.key});

  @override
  State<UpdateBodyMetricsBottomSheet> createState() => _UpdateBodyMetricsBottomSheetState();
}

class _UpdateBodyMetricsBottomSheetState extends State<UpdateBodyMetricsBottomSheet> {
  final ProfileController controller = Get.find<ProfileController>();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    weightController.text = controller.weight.value?.toString() ?? '';
    heightController.text = controller.height.value?.toString() ?? '';
  }

  @override
  void dispose() {
    weightController.dispose();
    heightController.dispose();
    super.dispose();
  }

  void _submit() async {
    final weight = double.tryParse(weightController.text);
    final height = double.tryParse(heightController.text);

    if (weight == null || height == null) {
      Get.snackbar(
        'Oops!',
        'Pastikan angka berat dan tinggi badan valid ya.',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    await controller.updateBodyMetrics(weight: weight, height: height);
    await controller.fetchUserProfile();
  }

  void _submitNoChanges() async {
    final currentWeight = controller.weight.value;
    final currentHeight = controller.height.value;
    
    if (currentWeight == null || currentHeight == null) {
      Get.snackbar(
        'Oops!',
        'Data sebelumnya kosong, isi data baru ya.',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
      );
      return;
    }
    
    // Simulate updating with same data to reset the 7-day timer
    await controller.updateBodyMetrics(weight: currentWeight, height: currentHeight);
    await controller.fetchUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFDF7), // Soft pastel sweet color
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 48,
              height: 5,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE0B2).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.monitor_weight_outlined,
                  color: Color(0xFFF57C00),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Waktunya Update!',
                      style: AppTextStyles.h3.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Yuk perbarui data berat dan tinggi badan',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Weight field
          Text(
            'Berat Badan (kg)',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: weightController,
            hintText: 'Contoh: 65.5',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: Icons.fitness_center,
            focusedBorderColor: Colors.orange.shade400,
          ),

          const SizedBox(height: 16),

          // Height field
          Text(
            'Tinggi Badan (cm)',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          CustomTextField(
            controller: heightController,
            hintText: 'Contoh: 170',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: Icons.height,
            focusedBorderColor: Colors.orange.shade400,
          ),

          const SizedBox(height: 24),

          // Save button
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB74D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Simpan Data',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _submitNoChanges,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Ga Ada Perubahan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

