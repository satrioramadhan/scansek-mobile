import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:scansek/app/core/theme/app_colors.dart';
import 'package:scansek/app/core/theme/app_text_styles.dart';
import 'package:scansek/app/widgets/buttons/primary_button.dart';
import 'package:scansek/app/widgets/cards/custom_card.dart';
import '../controllers/goals_controller.dart';

class GoalsView extends GetView<GoalsController> {
  const GoalsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Atur Target Harian',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF80CBC4),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
      ),
      body: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info card
                      CustomCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.info_outline,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Atur target harian kamu sesuai kebutuhan. Nanti dikasih peringatan kalo melebihi rekomendasi.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Calories goal (moved to first)
                      _buildGoalInput(
                        icon: Icons.local_fire_department,
                        iconColor: const Color(0xFFFFCC80),
                        iconBgColor: const Color(0xFFFFF3E0),
                        label: 'Target Kalori',
                        subtitle: 'Biasanya: 2000 kcal per hari',
                        controller: controller.caloriesController,
                        suffix: 'kcal',
                      ),

                      const SizedBox(height: 16),

                      // Sugar goal
                      _buildGoalInput(
                        icon: Icons.cookie_outlined,
                        iconColor: const Color(0xFFEF9A9A),
                        iconBgColor: const Color(0xFFFFEBEE),
                        label: 'Target Gula',
                        subtitle: 'Rekomendasi WHO: 50g per hari',
                        controller: controller.sugarController,
                        suffix: 'gram',
                      ),

                      const SizedBox(height: 16),

                      // Water goal
                      _buildGoalInput(
                        icon: Icons.water_drop,
                        iconColor: const Color(0xFF90CAF9),
                        iconBgColor: const Color(0xFFE3F2FD),
                        label: 'Target Air',
                        subtitle: 'Sebaiknya: 2000ml (8 gelas) per hari',
                        controller: controller.waterController,
                        suffix: 'ml',
                      ),

                      const SizedBox(height: 16),

                      // Burn goal
                      _buildGoalInput(
                        icon: Icons.whatshot,
                        iconColor: const Color(0xFFE53935),
                        iconBgColor: const Color(0xFFFFEBEE),
                        label: 'Target Bakar Kalori Aktivitas',
                        subtitle: 'Sebaiknya: 400 Kkal per hari (Diluar BMR)',
                        controller: controller.burnController,
                        suffix: 'Kkal',
                      ),

                      const SizedBox(height: 32),

                      // Save button
                      Obx(() => PrimaryButton(
                        text: 'Simpan',
                        backgroundColor: const Color(0xFF80CBC4), // Match appbar teal
                        onPressed: controller.isSaving.value
                            ? null
                            : controller.saveGoals,
                        isLoading: controller.isSaving.value,
                      )),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
      }),
    );
  }

  Widget _buildGoalInput({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String subtitle,
    required TextEditingController controller,
    required String suffix,
  }) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                hintText: 'Masukkan nilai',
                suffixText: suffix,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: iconColor, width: 2), // Changed from AppColors.primary
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
                errorMaxLines: 3, // Increased to allow longer roasting
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Isi dong, jangan dikosongin';
                }
                
                // Parse based on type
                final num = (suffix == 'langkah' || suffix == 'Kkal' && !value.contains('.')) 
                    ? int.tryParse(value.trim())?.toDouble() ?? double.tryParse(value.trim())
                    : double.tryParse(value.trim());
                    
                if (num == null) {
                  return 'Angka yang bener dong';
                }
                
                if (num <= 0) {
                  return 'Masa $num? Isi yang bener ya';
                }
                
                // Reasonable range validation based on suffix (Very loose sanity checks only, let controller handle detailed warnings)
                if (suffix == 'gram') {
                  // Sugar: allow any extreme up to 200g before completely blocking
                  if (num > 200) {
                    return 'Kalo mau mati mati aja ga usah pake aplikasi ini. Kok bisa inputnya ngaco banget!';
                  }
                } else if (suffix == 'kcal') {
                  // Calories: allow up to 5000 kcal before blocking
                  if (num > 7000) {
                    return 'Sok iye banget ngisi segitu, berasa keren lu? ini apk buat bantu orang. Gausah main-main!';
                  }
                } else if (suffix == 'ml') {
                  // Water: allow up to 12000ml (12L) before blocking
                  if (num > 12000) {
                    return 'Sini gw kasih tau, motor CB150 aja tangkinya 12 liter, jadi gausah ngaco!';
                  }
                } else if (suffix == 'Kkal' && label.contains('Bakar')) {
                  // Burn calories: allow up to 5000 kcal
                  if (num > 5000) {
                    return 'Apaan dah? Lagi ngincer orang lu sampe segitunya defisit kalori?. Realistis dikit lah!';
                  }
                }
                
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
