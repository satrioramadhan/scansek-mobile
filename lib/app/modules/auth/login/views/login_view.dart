import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:scansek/app/core/theme/app_colors.dart';
import 'package:scansek/app/core/theme/app_text_styles.dart';
import 'package:scansek/app/core/utils/validators.dart';
import 'package:scansek/app/widgets/buttons/primary_button.dart';
import 'package:scansek/app/widgets/inputs/custom_text_field.dart';
import 'package:scansek/app/widgets/loaders/loading_overlay.dart';
import '../../widgets/animated_auth_form_background.dart';
import '../../widgets/auth_header_graphic.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => LoadingOverlay(
        isLoading: controller.isLoading.value,
        child: Scaffold(
          backgroundColor: AppColors.primary, // Solid green background
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: AuthHeaderGraphic(
                  isSolid: true, // Make blobs translucent white
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 110,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome to ScanSek',
                        style: AppTextStyles.h1.copyWith(
                          color: Colors.white, // White text on solid background
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
                  seed: 1,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                    child: Form(
                    key: controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title
                        Text(
                          'Login',
                                style: AppTextStyles.h1.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 8),

                              // Subtitle
                              Text(
                                'Selalu jaga kesehatan yaa, pastinya bersama ScanSek. Yuk login dulu',
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
                                textInputAction: TextInputAction.next,
                                validator: Validators.email,
                                autofillHints: const [AutofillHints.email],
                              ),

                              const SizedBox(height: 16),

                              // Password field
                              Obx(
                                () => CustomTextField(
                                  controller: controller.passwordController,
                                  labelText: 'Password',
                                  hintText: '••••••••',
                                  prefixIcon: Icons.lock_outline,
                                  obscureText: controller.obscurePassword.value,
                                  showPasswordToggle: true,
                                  textInputAction: TextInputAction.done,
                                  validator: Validators.password,
                                  onSubmitted: (_) => controller.login(),
                                  autofillHints: const [AutofillHints.password],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Forgot password link
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: controller.goToForgotPassword,
                                  child: Text(
                                    'Lupa password ya?',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Login button
                              PrimaryButton(
                                onPressed: controller.login,
                                borderRadius: BorderRadius.circular(16),
                                child: const Text('Masuk'),
                              ),

                              const SizedBox(height: 24),

                              // Divider with text
                              Row(
                                children: [
                                  const Expanded(
                                    child: Divider(color: AppColors.borderColor),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'Atau masuk pakai',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const Expanded(
                                    child: Divider(color: AppColors.borderColor),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Google Sign In button
                              Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: AppColors.borderColor, width: 1.5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: controller.googleSignIn,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SvgPicture.asset(
                                          'assets/icons/google.svg',
                                          width: 24,
                                          height: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Masuk pakai Google',
                                          style: AppTextStyles.bodyLarge.copyWith(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Register link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Belum punya akun? ',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: controller.goToRegister,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Daftar dulu yuk',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ), // Column
                        ), // Form
                      ), // Padding
                    ), // AnimatedAuthFormBackground
                  ), // SliverFillRemaining
                ], // slivers
              ), // CustomScrollView
            ), // Scaffold
          ), // LoadingOverlay
        ); // Obx
  }
}
