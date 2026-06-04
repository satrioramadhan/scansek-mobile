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
import '../controllers/forgot_password_controller.dart';

class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

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
                                Icons.lock_reset,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Lupa Password?',
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
                        seed: 3, // Seed 3
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                          child: Form(
                          key: controller.formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Title
                              Text(
                                'Tenang Aja 🔐',
                                style: AppTextStyles.h1.copyWith(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 12),

                              // Subtitle
                              Text(
                                'Masukkin email kamu, nanti kita kirim kode OTP buat reset password',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 32),

                              // Email field
                              CustomTextField(
                                controller: controller.emailController,
                                labelText: 'Email',
                                hintText: 'nama@email.com',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.done,
                                validator: controller.validateEmail, // Use validator from controller
                                onSubmitted: (_) => controller.sendResetOTP(),
                                autofillHints: const [AutofillHints.email],
                              ),
                              
                              const SizedBox(height: 32),

                              // Send OTP button
                              PrimaryButton(
                                onPressed: controller.sendResetOTP,
                                borderRadius: BorderRadius.circular(16),
                                child: const Text('Kirim OTP'),
                              ),
                              
                              const SizedBox(height: 20),

                              // Back to login
                              TextButton(
                                onPressed: () => Get.back(),
                                child: Text(
                                  'Kembali ke Login',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
