import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/values/auth_strings.dart' as AuthStrings;
import '../../../../widgets/buttons/custom_button.dart';
import '../../../../widgets/inputs/custom_text_field.dart';
import '../../../../widgets/loaders/loading_overlay.dart';
import '../../widgets/animated_auth_form_background.dart';
import '../../widgets/auth_header_graphic.dart';
import '../controllers/complete_profile_controller.dart';

class CompleteProfileView extends GetView<CompleteProfileController> {
  const CompleteProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => LoadingOverlay(
        isLoading: controller.isLoading.value,
        child: Scaffold(
          backgroundColor: AppColors.primary, // Solid green background
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: AuthHeaderGraphic(
                    isSolid: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person_add_alt_1,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Obx(() {
                          final name = controller.userName.value;
                          final greeting = name.isNotEmpty ? 'Hai $name!' : 'Hai!';
                          return Text(
                            greeting,
                            style: AppTextStyles.h1.copyWith(
                              color: Colors.white, // Changed to white
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AnimatedAuthFormBackground(
                    seed: 7, // Seed 7
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                      child: Form(
                      key: controller.formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Lengkapin profil kamu dulu ya',
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Isi data berikut buat tracking yang lebih akurat',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // Weight & Height
                          Row(
                            children: [
                              Expanded(
                                child: NumberTextField(
                                  controller: controller.weightController,
                                  labelText: AuthStrings.weight,
                                  hintText: '70',
                                  prefixIcon: Icons.monitor_weight_outlined,
                                  suffixText: AuthStrings.kg,
                                  validator: Validators.weight,
                                  allowDecimal: true,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: NumberTextField(
                                  controller: controller.heightController,
                                  labelText: AuthStrings.height,
                                  hintText: '170',
                                  prefixIcon: Icons.height_outlined,
                                  suffixText: AuthStrings.cm,
                                  validator: Validators.height,
                                  allowDecimal: true,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Date of Birth
                          Obx(
                            () => CustomTextField(
                              labelText: AuthStrings.dateOfBirth,
                              hintText: 'Pilih tanggal lahir',
                              prefixIcon: Icons.calendar_today_outlined,
                              readOnly: true,
                              onTap: () => controller.selectDateOfBirth(context),
                              controller: TextEditingController(
                                text: controller.selectedDate.value != null
                                    ? DateFormatter.formatDate(
                                        controller.selectedDate.value!)
                                    : '',
                              ),
                              // No validator needed - handled in controller
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Gender
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AuthStrings.gender,
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Obx(
                                () => Row(
                                  children: [
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: Text(
                                          AuthStrings.male,
                                          style: AppTextStyles.bodyMedium,
                                        ),
                                        value: 'male',
                                        groupValue: controller.selectedGender.value,
                                        onChanged: (value) {
                                          controller.selectedGender.value = value!;
                                        },
                                        activeColor: AppColors.primary,
                                        contentPadding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                    Expanded(
                                      child: RadioListTile<String>(
                                        title: Text(
                                          AuthStrings.female,
                                          style: AppTextStyles.bodyMedium,
                                        ),
                                        value: 'female',
                                        groupValue: controller.selectedGender.value,
                                        onChanged: (value) {
                                          controller.selectedGender.value = value!;
                                        },
                                        activeColor: AppColors.primary,
                                        contentPadding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Info card
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Data ini diperlukan buat hitung BMI dan tracking nutrisi yang akurat',
                                    style: AppTextStyles.caption.copyWith(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Submit button
                          CustomButton.primary(
                            text: 'Simpan & Lanjutkan',
                            onPressed: () => controller.completeProfile(context),
                            borderRadius: 16.0,
                          ),
                        ],
                      ), // Column
                    ), // Form
                  ), // Padding
                ), // AnimatedAuthFormBackground
                ), // SliverFillRemaining
              ],
            ), // CustomScrollView
          ), // SafeArea
        ), // Scaffold
      ), // LoadingOverlay
    ); // Obx
  }
}
