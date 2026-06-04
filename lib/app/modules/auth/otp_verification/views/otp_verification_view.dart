import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../widgets/buttons/primary_button.dart';
import '../../../../widgets/inputs/otp_input.dart';
import '../../../../widgets/loaders/loading_overlay.dart';
import '../../widgets/animated_auth_form_background.dart';
import '../../widgets/auth_header_graphic.dart';
import '../controllers/otp_verification_controller.dart';

class OtpVerificationView extends GetView<OtpVerificationController> {
  const OtpVerificationView({super.key});

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
                                Icons.mail_outline,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Cek Email Kamu',
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
                        seed: 5, // Seed 5
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                          child: Column(
                          children: [
                            // Title
                            Text(
                              'Verifikasi OTP',
                              style: AppTextStyles.h1.copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 12),

                            // Subtitle
                            Text(
                              'Masukkin kode OTP yang udah dikirim ke\n${controller.email}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 32),

                            // OTP Input
                            Form(
                              key: controller.formKey,
                              child: OtpInput(
                                controller: controller.otpController,
                                length: 6,
                                onCompleted: (pin) {
                                  controller.otpController.text = pin;
                                },
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Countdown & Resend
                            Obx(
                              () => Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (!controller.canResend.value)
                                    Text(
                                      'Minta OTP lagi dalam ${controller.countdown.value}s',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  if (controller.canResend.value)
                                    TextButton(
                                      onPressed: controller.isLoading.value
                                          ? null
                                          : controller.resendOtp,
                                      child: controller.isLoading.value
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              'Minta OTP lagi',
                                              style: AppTextStyles.bodyMedium.copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Verify button
                            Obx(
                              () => PrimaryButton(
                                onPressed: controller.isLoading.value
                                    ? null
                                    : controller.verifyOtp,
                                isLoading: controller.isLoading.value,
                                borderRadius: BorderRadius.circular(16),
                                child: const Text('Verifikasi'),
                              ),
                            ),
                          ],
                        ), // Column
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
