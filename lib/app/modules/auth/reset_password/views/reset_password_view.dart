import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../widgets/buttons/primary_button.dart';
import '../../../../widgets/inputs/custom_text_field.dart';
import '../../../../widgets/loaders/loading_overlay.dart';
import '../../widgets/animated_auth_form_background.dart';
import '../../widgets/auth_header_graphic.dart';
import '../controllers/reset_password_controller.dart';

class ResetPasswordView extends GetView<ResetPasswordController> {
  const ResetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => LoadingOverlay(
        isLoading: controller.isLoading.value,
        child: Scaffold(
          backgroundColor: AppColors.primary, // Solid green background
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: AuthHeaderGraphic(
                        isSolid: true,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
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
                                Icons.vpn_key,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Buat Password',
                              style: AppTextStyles.h1.copyWith(
                                color: Colors.white, // Changed to white
                                fontSize: 26,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: AnimatedAuthFormBackground(
                        seed: 6, // Seed 6
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                          child: Form(
                          key: controller.formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Title
                              Text(
                                'Reset Password 🔑',
                                style: AppTextStyles.h1.copyWith(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 12),

                              // Subtitle
                              Text(
                                'Buat password baru buat akun kamu',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 32),

                              // New Password field
                              Obx(
                                () => CustomTextField(
                                  controller: controller.newPasswordController,
                                  labelText: 'Password Baru',
                                  hintText: '••••••••',
                                  prefixIcon: Icons.lock_outline,
                                  obscureText: !controller.isNewPasswordVisible.value,
                                  showPasswordToggle: true,
                                  textInputAction: TextInputAction.next,
                                  validator: controller.validatePassword,
                                ),
                              ),
                              
                              const SizedBox(height: 16),

                              // Confirm Password field
                              Obx(
                                () => CustomTextField(
                                  controller: controller.confirmPasswordController,
                                  labelText: 'Konfirmasi Password',
                                  hintText: '••••••••',
                                  prefixIcon: Icons.lock_outline,
                                  obscureText: !controller.isConfirmVisible.value,
                                  showPasswordToggle: true,
                                  textInputAction: TextInputAction.done,
                                  validator: (value) => controller.validateConfirmPassword(value),
                                  onSubmitted: (_) => controller.resetPassword(),
                                ),
                              ),
                              
                              const SizedBox(height: 32),

                              // Reset button
                              PrimaryButton(
                                onPressed: controller.resetPassword,
                                borderRadius: BorderRadius.circular(16),
                                child: const Text('Reset Password'),
                              ),
                            ],
                          ), // Column
                        ), // Form
                      ), // Padding
                    ), // AnimatedAuthFormBackground
                    ), // SliverFillRemaining
                  ],
                ), // CustomScrollView
                
                // Floating back button
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      onPressed: () => Get.back(),
                    ),
                  ),
                ),
              ],
            ), // Stack
          ), // SafeArea
        ),
      ),
    );
  }
}
