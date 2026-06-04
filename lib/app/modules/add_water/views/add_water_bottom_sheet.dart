import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../add_water/controllers/add_water_controller.dart';

class AddWaterBottomSheet extends GetView<AddWaterController> {
  const AddWaterBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is initialized if not already
    try {
      Get.find<AddWaterController>();
    } catch (e) {
      Get.put(AddWaterController());
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Text(
            'Tambah Air Minum',
            textAlign: TextAlign.center,
            style: AppTextStyles.h3.copyWith(
              color: const Color(0xFF2196F3), // Blue 200 - Matches History View
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),

          // Manual Input (Compact)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE1F5FE), // Light background for input
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  IntrinsicWidth(
                    child: TextField(
                      controller: controller.amountController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 40, // Slightly smaller than full screen
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2196F3),
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
                        hintStyle: TextStyle(color: Colors.black12),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'ml',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2196F3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Presets (Bubble Style)
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [100, 250, 500, 600].map((amount) {
              return InkWell(
                onTap: () => controller.setAmount(amount),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 60, // Smaller bubbles
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFB3E5FC),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB3E5FC).withOpacity(0.5),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.local_drink_rounded, size: 18, color: Color(0xFF2196F3)),
                      const SizedBox(height: 2),
                      Text(
                        '$amount',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        color: const Color(0xFF2196F3),
                        fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Time Picker Tile
          InkWell(
            onTap: () => controller.selectTime(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE1F5FE)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Row(
                    children: [
                      const Icon(Icons.access_time_filled_rounded, color: Color(0xFF2196F3), size: 20),
                      const SizedBox(width: 12),
                      const Text(
                        'Waktu Minum',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Obx(() => Text(
                    DateFormat('HH:mm').format(controller.intakeTime.value),
                    style: const TextStyle(
                      color: Color(0xFF2196F3),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Save Button
          SafeArea(
            child: Obx(() => ElevatedButton(
              onPressed: controller.isLoading.value ? null : controller.saveWater,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: const Color(0xFF90CAF9).withOpacity(0.4),
              ),
              child: controller.isLoading.value
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Simpan Air Minum',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
            )),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
