import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_assets.dart';
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
import '../controllers/register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

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
                              'Daftar Akun',
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
                        seed: 2, // Seed 2 for Register
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                          child: Form(
                          key: controller.formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Title
                                  Text(
                                    'Hai Pendatang Baru',
                                    style: AppTextStyles.h1.copyWith(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),

                                  const SizedBox(height: 8),

                                  Text(
                                    'Isi data diri dulu ya',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),

                                  const SizedBox(height: 28),

                                  // Name field
                                  CustomTextField(
                                    controller: controller.nameController,
                                    labelText: AuthStrings.fullName,
                                    hintText: 'Ucup Surucup',
                                    prefixIcon: Icons.person_outline,
                                    textInputAction: TextInputAction.next,
                                    validator: Validators.name,
                                  ),

                                  const SizedBox(height: 16),

                                  // Email field
                                  CustomTextField(
                                    controller: controller.emailController,
                                    labelText: AuthStrings.email,
                                    hintText: 'nama@email.com',
                                    prefixIcon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    validator: Validators.email,
                                    autofillHints: const [AutofillHints.email],
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
                                      validator: (value) {
                                        if (controller.selectedDate.value == null) {
                                          return 'Tanggal lahirnya diisi dulu ya';
                                        }
                                        return null;
                                      },
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

                                  const SizedBox(height: 16),

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

                                  // Password field
                                  Obx(
                                    () => CustomTextField(
                                      controller: controller.passwordController,
                                      labelText: AuthStrings.password,
                                      hintText: '••••••••',
                                      prefixIcon: Icons.lock_outline,
                                      obscureText: controller.obscurePassword.value,
                                      showPasswordToggle: true,
                                      textInputAction: TextInputAction.next,
                                      validator: Validators.password,
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Confirm Password field
                                  Obx(
                                    () => CustomTextField(
                                      controller: controller.confirmPasswordController,
                                      labelText: AuthStrings.confirmPassword,
                                      hintText: '••••••••',
                                      prefixIcon: Icons.lock_outline,
                                      obscureText: controller.obscureConfirmPassword.value,
                                      showPasswordToggle: true,
                                      textInputAction: TextInputAction.done,
                                      validator: (value) => Validators.confirmPassword(
                                        value,
                                        controller.passwordController.text,
                                      ),
                                      onSubmitted: (_) => controller.register(),
                                    ),
                                  ),

                                  const SizedBox(height: 28),

                                  // Register button
                                  CustomButton.primary(
                                    text: AuthStrings.register,
                                    onPressed: controller.register,
                                    borderRadius: 16.0,
                                  ),

                                  const SizedBox(height: 20),

                                  // Login link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        AuthStrings.alreadyHaveAccount,
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      TextButton(
                                        onPressed: controller.goToLogin,
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          AuthStrings.login,
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ), // Form
                        ), // Padding
                      ), // AnimatedAuthFormBackground
                    ], // slivers
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
                        onPressed: controller.goToLogin,
                      ),
                    ),
                  ),
                ], // Stack children
              ), // Stack
            ), // SafeArea
          ), // Scaffold
        ), // LoadingOverlay
      ); // Obx
  }
}
