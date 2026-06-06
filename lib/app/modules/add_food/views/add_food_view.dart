import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../controllers/add_food_controller.dart';

class AddFoodView extends GetView<AddFoodController> {
  const AddFoodView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Obx(() => Text(
          controller.isEditMode.value
              ? 'Edit Konsumsi'
              : controller.isFromScan.value
                  ? 'Lengkapi Data Scan'
                  : 'Tambah Konsumsi Manual',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        )),
        centerTitle: true,
        backgroundColor: const Color(0xFF80CBC4),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
      ),

      body: Form(
        key: controller.formKey,
        child: SingleChildScrollView(
          controller: controller.scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card if from scan
              Obx(() {
                if (controller.isFromScan.value) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1), // Soft Teal (Colors.teal[50])
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF80CBC4), width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.qr_code_scanner,
                          color: Color(0xFF00796B), // Darker Teal untuk kontras yg jelas
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Data gula dan kalori terisi otomatis dari hasil scan, kamu tinggal lengkapi data lainnya yaa',
                            style: AppTextStyles.caption.copyWith(
                              color: const Color(0xFF00796B), // Darker text
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // Manual Input Fields
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // Name Field
              Text(
                'Nama Makanan/Minuman',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                controller: controller.nameController,
                hint: 'Contoh: Indomie Goreng',
                icon: Icons.fastfood,
                iconColor: const Color(0xFFFFB74D), // Orange untuk makanan
                borderColor: const Color(0xFFFFB74D),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama makanannya diisi dong';
                  }
                  if (value.trim().length < 2) {
                    return 'Namanya minimal 2 karakter';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Sugar Content Field with Unit Selector
              Text(
                'Kandungan Gula',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildNumberField(
                      controller: controller.sugarContentController,
                      hint: '0.0',
                      icon: Icons.cookie_outlined,
                      iconColor: const Color(0xFFE57373), // Pink/Red untuk gula
                      borderColor: const Color(0xFFE57373),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final num = double.tryParse(value);
                          if (num == null || num < 0) {
                            return 'Harus >= 0';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Obx(() => _buildUnitDropdown(
                          value: controller.sugarUnit.value,
                          items: const ['gram', 'sdt', 'sdm'],
                          onChanged: controller.changeSugarUnit,
                        )),
                  ),
                ],
              ),
              

              
              const SizedBox(height: 16),

              Text(
                'Kandungan Kalori',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _buildNumberField(
                controller: controller.calorieContentController,
                hint: '0',
                icon: Icons.local_fire_department,
                iconColor: const Color(0xFFFF7043), // Deep Orange
                borderColor: const Color(0xFFFF7043),
                suffix: 'kcal',
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final num = double.tryParse(value);
                    if (num == null || num < 0) {
                      return 'Kalori harus >= 0';
                    }
                  }
                  return null;
                },
              ),

              ],
              ),

              // Weight Field with Unit

              // Weight Field with Unit

              // Weight Field with Unit
              const SizedBox(height: 8), // Additional spacing to separate from above
              Text(
                'Berat Isi (Opsional)',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildNumberField(
                      controller: controller.weightController,
                      hint: '0',
                      icon: Icons.scale,
                      iconColor: const Color(0xFF81C784), // Green untuk weight
                      borderColor: const Color(0xFF81C784),
                      validator: (value) {
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Obx(() => _buildUnitDropdown(
                          value: controller.weightUnit.value,
                          items: const ['gram', 'ml'],
                          onChanged: controller.changeWeightUnit,
                        )),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                'Berapa kali Konsumsi',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              _buildNumberField(
                controller: controller.quantityController,
                hint: '1',
                icon: Icons.format_list_numbered,
                iconColor: const Color(0xFF64B5F6), // Blue untuk quantity
                borderColor: const Color(0xFF64B5F6),
                suffix: 'kali',
                isInteger: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Yang ini wajib diisi dong';
                  }
                  final num = int.tryParse(value);
                  if (num == null || num < 1) {
                    return 'Minimal 1 porsi';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Date Time Picker
              Text(
                'Waktu Konsumsi',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Obx(() => InkWell(
                    onTap: () => controller.pickDateTime(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Color(0xFF9575CD), // Purple untuk waktu
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              controller.formattedDateTime,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.textHint,
                          ),
                        ],
                      ),
                    ),
                  )),

              const SizedBox(height: 24),

              // Intake Summary (Receipt Style)
              Obx(() => controller.intakeSummaryLines.isNotEmpty
                  ? Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1), // Soft Teal
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF80CBC4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.receipt_long, color: Color(0xFF009688), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Rincian Asupan',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF00695C),
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Color(0xFFB2DFDB), height: 16),
                          ...controller.intakeSummaryLines.map((line) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  line,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: const Color(0xFF004D40),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              )),
                        ],
                      ),
                    )
                  : const SizedBox.shrink()),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : controller.saveFood,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF80CBC4), // Match appbar color
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    disabledForegroundColor: Colors.white,
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          controller.isEditMode.value ? 'Update' : 'Simpan',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                )),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    Color? iconColor,
    Color? borderColor,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor ?? AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor ?? AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    Color? iconColor,
    Color? borderColor,
    String? suffix,
    bool isInteger = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType:
              TextInputType.numberWithOptions(decimal: !isInteger),
          inputFormatters: [
            if (isInteger)
              FilteringTextInputFormatter.digitsOnly
            else
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
            suffixText: suffix,
            suffixStyle: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor ?? AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor ?? AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildUnitDropdown({
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textHint),
          style: AppTextStyles.bodyMedium,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
      ),
    );
  }
}
