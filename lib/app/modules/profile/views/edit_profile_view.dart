import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scansek/app/core/theme/app_colors.dart';
import 'package:scansek/app/core/theme/app_text_styles.dart';
import 'package:scansek/app/widgets/buttons/custom_button.dart';
import 'package:scansek/app/widgets/inputs/custom_text_field.dart';
import 'package:scansek/app/widgets/snackbars/snackbar_designs.dart';
import '../controllers/profile_controller.dart';

class EditProfileView extends GetView<ProfileController> {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: controller.userName.value);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false, // Fix overflow when keyboard appears
      body: Column(
        children: [
          // Styled AppBar with gradient - matching profile view
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF80CBC4), // Soft Teal
                  const Color(0xFF80CBC4).withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  children: [
                    // Header with back button
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Edit Profil',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // Balance the back button
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Profile Avatar with Edit Button
                    Stack(
                      children: [
                        // Simple avatar using controller's userName
                        Obx(() {
                          final userName = controller.userName.value;
                          final initial = userName.isNotEmpty 
                              ? userName[0].toUpperCase() 
                              : 'U';
                          
                          return Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: Color(0xFF80CBC4),
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }),
                        
                        // Edit Photo Button
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () async {
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              
                              if (image != null) {
                                // TODO: Handle image upload
                                ElegantSnackbar.success(
                                  context,
                                  'Yeay, foto profil berhasil dipilih!',
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Color(0xFF80CBC4),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
            // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF80CBC4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF80CBC4).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF80CBC4),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Kamu bisa ubah informasi profil di bawah ini',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Name Field
                    CustomTextField(
                      controller: nameController,
                      labelText: 'Nama Lengkap',
                      hintText: 'Masukkan nama lengkap',
                      prefixIcon: Icons.person_outline,
                      validator: controller.validateName,
                    ),
                    
                    const SizedBox(height: 16),
                    // Weight & Height have been removed to prevent bypassing the stabilization lock.
                    const SizedBox(height: 16),
                    
                    // Date of Birth
                    Text(
                      'Tanggal Lahir',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() {
                      final dateText = controller.dateOfBirth.value ?? '';
                      return CustomTextField(
                        readOnly: true,
                        controller: TextEditingController(text: dateText), // Bind to controller value
                        hintText: 'Pilih tanggal lahir',
                        prefixIcon: Icons.calendar_today_outlined,
                        onTap: () async {
                          // Parse existing date or default to 20 years ago
                          DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 20));
                          if (controller.dateOfBirth.value != null && controller.dateOfBirth.value!.isNotEmpty) {
                            try {
                              initialDate = DateTime.parse(controller.dateOfBirth.value!);
                            } catch (e) {
                              // Ignore parse error, use default
                            }
                          }

                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: initialDate,
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)), // Min age 13
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
                            controller.dateOfBirth.value = 
                                '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                          }
                        },
                        validator: (value) {
                          if (controller.dateOfBirth.value == null || controller.dateOfBirth.value!.isEmpty) {
                            return 'Tanggal lahir dipilih dulu ya';
                          }
                          return null;
                        },
                      );
                    }),
                    
                    const SizedBox(height: 16),
                    
                    // Gender
                    Text(
                      'Jenis Kelamin',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text(
                              'Laki-laki',
                              style: AppTextStyles.bodyMedium,
                            ),
                            value: 'male',
                            groupValue: controller.gender.value.isEmpty 
                                ? 'male' 
                                : controller.gender.value,
                            onChanged: (value) {
                              controller.gender.value = value!;
                            },
                            activeColor: const Color(0xFF80CBC4),
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text(
                              'Perempuan',
                              style: AppTextStyles.bodyMedium,
                            ),
                            value: 'female',
                            groupValue: controller.gender.value.isEmpty 
                                ? 'male' 
                                : controller.gender.value,
                            onChanged: (value) {
                              controller.gender.value = value!;
                            },
                            activeColor: const Color(0xFF80CBC4),
                            contentPadding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    )),
                    
                    const SizedBox(height: 16),
                    
                    // Email Field (Read-only)
                    Text(
                      'Email',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => CustomTextField(
                      enabled: false,
                      hintText: controller.userEmail.value,
                      prefixIcon: Icons.email_outlined,
                      suffixIcon: Icon(
                        Icons.lock_outline,
                        color: Colors.grey[400],
                        size: 18,
                      ),
                      fillColor: Colors.grey[100],
                    )),
                    
                    const SizedBox(height: 8),
                    
                    // Email info
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Email tidak dapat diubah',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Buttons
                    Row(
                      children: [
                        // Cancel Button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Get.back(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: Colors.grey[400]!,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Batal',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Save Button
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () async {
                              // Validate Form
                              if (!controller.formKey.currentState!.validate()) {
                                return;
                              }

                              final newName = nameController.text.trim();
                              
                              try {
                                // Update profile with authorized fields
                                await controller.updateProfile(
                                  name: newName,
                                  dateOfBirth: controller.dateOfBirth.value,
                                  gender: controller.gender.value.isEmpty ? null : controller.gender.value,
                                );
                                
                                ElegantSnackbar.success(
                                  context,
                                  'Yeay! Profil berhasil diperbarui!',
                                );
                                
                                // Navigate back after short delay
                                Future.delayed(const Duration(milliseconds: 800), () {
                                  Get.back();
                                });
                              } catch (e) {
                                ElegantSnackbar.error(
                                  context,
                                  'Yah, gagal update profil nih: $e',
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF80CBC4),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Simpan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
