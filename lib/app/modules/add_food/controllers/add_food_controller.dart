import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scansek/app/widgets/states/error_state.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../data/providers/api/api_client.dart';
import '../../../data/providers/api/api_endpoints.dart';
import '../../../data/providers/api/network_exception.dart';
import '../../../widgets/snackbars/snackbar_designs.dart';
import '../../../data/providers/local/storage_service.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../history/controllers/history_controller.dart';
import '../../../data/models/dashboard_stats_model.dart';
import '../../../services/notification_service.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/values/api_keys.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class AddFoodController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();

  // Form controllers
  final nameController = TextEditingController();
  final sugarContentController = TextEditingController();
  final calorieContentController = TextEditingController();
  final weightController = TextEditingController();
  final quantityController = TextEditingController(text: '1');

  // Form key
  final formKey = GlobalKey<FormState>();

  // Scroll controller
  final ScrollController scrollController = ScrollController();

  // Observable states
  final RxBool isLoading = false.obs;
  final RxString sugarUnit = 'gram'.obs; // gram, sdt, sdm
  final RxString weightUnit = 'gram'.obs; // gram, ml
  final Rx<DateTime> consumptionTime = DateTime.now().obs;

  // From scan data
  final RxBool isFromScan = false.obs;
  
  // Edit mode
  final RxBool isEditMode = false.obs;
  String? foodId;

  // AI Mode
  final RxBool isAiMode = false.obs;
  final RxBool hasAiResult = false.obs;
  final TextEditingController aiPromptController = TextEditingController();
  final RxString aiImagePath = ''.obs;

  // Add properties to store original values when in edit mode
  double _oldTotalSugar = 0.0;
  double _oldTotalCalories = 0.0;

  // Helper message for total intake summary
  final RxList<String> intakeSummaryLines = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    
    // Listen to changes for conversion message
    sugarContentController.addListener(_updateIntakeSummary);
    calorieContentController.addListener(_updateIntakeSummary);
    quantityController.addListener(_updateIntakeSummary);
    ever(sugarUnit, (_) => _updateIntakeSummary());

    _loadScanDataIfExists();
  }

  @override
  void onClose() {
    nameController.dispose();
    sugarContentController.dispose();
    calorieContentController.dispose();
    weightController.dispose();
    quantityController.dispose();
    aiPromptController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  /// Load scan data if coming from scanner or edit data
  void _loadScanDataIfExists() {
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      // Check for edit mode
      isEditMode.value = args['isEditMode'] == true;
      
      if (isEditMode.value) {
        // Load existing food data for editing
        foodId = args['id'] as String?;
        nameController.text = args['name'] ?? '';
        
        final sugarContent = args['sugarContent'] as double?;
        final calorieContent = args['calorieContent'] as double?;
        final weight = args['weight'] as double?;
        final quantity = args['quantity'] as int?;
        final weightUnitValue = args['weightUnit'] as String?;
        final consumptionTimeStr = args['consumptionTime'] as String?;
        
        if (sugarContent != null) {
          sugarContentController.text = sugarContent.toStringAsFixed(1);
          _oldTotalSugar = sugarContent * (quantity ?? 1);
        }
        if (calorieContent != null) {
          calorieContentController.text = calorieContent.toStringAsFixed(0);
          _oldTotalCalories = calorieContent * (quantity ?? 1);
        }
        if (weight != null) {
          weightController.text = weight.toStringAsFixed(0);
        }
        if (quantity != null) {
          quantityController.text = quantity.toString();
        }
        if (weightUnitValue != null) {
          weightUnit.value = weightUnitValue;
        }
        if (consumptionTimeStr != null) {
          try {
            consumptionTime.value = DateTime.parse(consumptionTimeStr);
          } catch (e) {
            print('Error parsing consumption time: $e');
          }
        }
      } else {
        // Scan mode
        isFromScan.value = args['isFromScan'] == true;
        
        if (isFromScan.value) {
          final sugar = args['sugar'] as double?;
          final calories = args['calories'] as double?;
          final name = args['name'] as String?;

          if (name != null) {
            nameController.text = name;
          }
          if (sugar != null) {
            sugarContentController.text = sugar.toStringAsFixed(1);
          }
          if (calories != null) {
            calorieContentController.text = calories.toStringAsFixed(0);
          }
        }
      }
    }
  }

  /// Update intake summary message
  void _updateIntakeSummary() {
    final sugarText = sugarContentController.text.trim();
    final caloriesText = calorieContentController.text.trim();
    final quantityText = quantityController.text.trim();

    if (sugarText.isEmpty && caloriesText.isEmpty) {
      intakeSummaryLines.clear();
      return;
    }

    final sugarVal = double.tryParse(sugarText) ?? 0.0;
    final caloriesVal = double.tryParse(caloriesText) ?? 0.0;
    final quantity = int.tryParse(quantityText) ?? 1;

    if (sugarVal <= 0 && caloriesVal <= 0) {
      intakeSummaryLines.clear();
      return;
    }

    final List<String> lines = [];

    // Sugar calculation
    if (sugarVal > 0) {
      final sugarGrams = getSugarInGrams(); // Total grams per portion
      final totalSugar = sugarGrams * quantity;
      
      // Formatting numbers
      final sugarValStr = sugarVal % 1 == 0 ? sugarVal.toInt().toString() : sugarVal.toStringAsFixed(1);
      final sugarGramsStr = sugarGrams % 1 == 0 ? sugarGrams.toInt().toString() : sugarGrams.toStringAsFixed(1);
      final totalSugarStr = totalSugar % 1 == 0 ? totalSugar.toInt().toString() : totalSugar.toStringAsFixed(1);

      if (sugarUnit.value != 'gram') {
        // Example: 2 sdt (8g) x 2 = 16g Gula
        lines.add('$sugarValStr ${sugarUnit.value} ($sugarGramsStr g) × $quantity = $totalSugarStr g Gula');
      } else {
        // Example: 8g x 2 = 16g Gula
        lines.add('$sugarGramsStr g × $quantity = $totalSugarStr g Gula');
      }
    }

    // Calories calculation
    if (caloriesVal > 0) {
      final totalCalories = caloriesVal * quantity;
      final calValStr = caloriesVal % 1 == 0 ? caloriesVal.toInt().toString() : caloriesVal.toStringAsFixed(0);
      final totalCalStr = totalCalories % 1 == 0 ? totalCalories.toInt().toString() : totalCalories.toStringAsFixed(0);
      
      // Example: 200 kcal x 2 = 400 kcal
      lines.add('$calValStr kcal × $quantity = $totalCalStr kcal');
    }

    intakeSummaryLines.assignAll(lines);
  }

  /// Convert sugar from current unit to grams
  double getSugarInGrams() {
    final value = double.tryParse(sugarContentController.text) ?? 0.0;
    
    switch (sugarUnit.value) {
      case 'sdt': // 1 sendok teh = 4 gram
        return value * 4.0;
      case 'sdm': // 1 sendok makan = 12 gram
        return value * 12.0;
      default: // gram
        return value;
    }
  }

  /// Change sugar unit
  void changeSugarUnit(String unit) {
    sugarUnit.value = unit;
  }

  /// Change weight unit
  void changeWeightUnit(String unit) {
    weightUnit.value = unit;
  }

  /// Pick consumption date & time
  Future<void> pickDateTime(BuildContext context) async {
    // Pick date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: consumptionTime.value,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null) return;

    // Pick time
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(consumptionTime.value),
    );

    if (pickedTime == null) return;

    // Combine date and time
    consumptionTime.value = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  /// Get formatted date time string
  String get formattedDateTime {
    final now = DateTime.now();
    final dateTime = consumptionTime.value;

    // Check if today
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return 'Hari ini, ${DateFormat('HH:mm').format(dateTime)}';
    }

    // Check if yesterday
    final yesterday = now.subtract(const Duration(days: 1));
    if (dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day) {
      return 'Kemarin, ${DateFormat('HH:mm').format(dateTime)}';
    }

    // Other dates
    return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
  }

  /// Validate and save or update food
  Future<void> saveFood() async {
    if (isEditMode.value) {
      await updateFood();
    } else {
      await addFood();
    }
  }
  
  /// Add new food entry
  Future<void> addFood() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    // Extract values
    final name = nameController.text.trim();
    final sugarInGrams = getSugarInGrams();
    final calories = double.tryParse(calorieContentController.text) ?? 0.0;
    final weight = double.tryParse(weightController.text) ?? 0.0;
    final quantity = int.tryParse(quantityController.text) ?? 1;

    if (name.length < 2) {
      ElegantSnackbar.error(Get.context, 'Nama makanan minimal 2 karakter');
      return;
    }

    // Flexible Validation:
    // 1. Both empty -> Error
    // 2. Only one filled -> Confirm
    // 3. Both filled -> Save
    
    final hasSugar = sugarContentController.text.isNotEmpty && sugarInGrams > 0;
    final hasCalories = calorieContentController.text.isNotEmpty && calories > 0;

    if (!hasSugar && !hasCalories) {
      ElegantSnackbar.error(Get.context, 'Isi minimal satu: Kandungan gula atau kalori');
      return;
    }

    // Weight is optional, default to 0
    if (quantity < 1) {
      ElegantSnackbar.error(Get.context, 'Jumlah porsi tidak valid');
      return;
    }

    // Confirmation if only one is filled
    if (hasSugar && !hasCalories) {
      _showConfirmationDialog('Kamu cuma isi Gula, yakin Kalorinya 0?', () => _checkLimitsAndProceed(_performSave));
      return;
    }
    
    if (!hasSugar && hasCalories) {
      _showConfirmationDialog('Kamu cuma isi Kalori, yakin Gulanya 0?', () => _checkLimitsAndProceed(_performSave));
      return;
    }

    // Both filled or confirmed, proceed to target evaluation and save
    _checkLimitsAndProceed(_performSave);
  }

  void _showConfirmationDialog(String message, VoidCallback onConfirmAction) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1), // Soft Teal bg
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  size: 48,
                  color: Color(0xFF009688), // Teal
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Konfirmasi Kandungan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3E50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Text(
                        'Cek Lagi',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        onConfirmAction();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF80CBC4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Yakin',
                        style: TextStyle(
                          color: Colors.white,
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
    );
  }

  Future<void> _performSave() async {
    isLoading.value = true;
    
    // Extract values
    final name = nameController.text.trim();
    final sugarInGrams = getSugarInGrams();
    final calories = double.tryParse(calorieContentController.text) ?? 0.0;
    final weight = double.tryParse(weightController.text) ?? 0.0;
    final quantity = int.tryParse(quantityController.text) ?? 1;

    try {
      final response = await _apiClient.post(
        ApiEndpoints.addFood,
        data: {
          'name': name,
          'sugarContent': sugarInGrams, // Always send in grams
          'calorieContent': calories,
          'weight': weight,
          'weightUnit': weightUnit.value,
          'quantity': quantity,
          'consumptionTime': consumptionTime.value.toIso8601String(),
          'isScanned': isFromScan.value,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        Get.back(); // Close add food screen
        
        // Extract message from backend and show snackbar
        final message = response.data['message'] ?? 'Mantap! Makanan udah kesimpan';
        ElegantSnackbar.success(Get.context, message);

        // Refresh dashboard if it exists
        try {
          if (Get.isRegistered<DashboardController>()) {
            Get.find<DashboardController>().fetchDashboardData();
          }
        } catch (e) {}

        // Refresh History if it exists (User request: redirect & refresh history)
        // Refresh history if exists
        try {
          if (Get.isRegistered<HistoryController>()) {
            Get.find<HistoryController>().fetchHistory();
          }
        } catch (e) {}
        
        // Simpan timestamp & refresh notif
        await StorageService().setLastFoodInputTime(DateTime.now());
        await NotificationService().refreshSystemNotifications();
      }
    } on NetworkException catch (e) {
      ErrorSnackbar.show(Get.context!, e.message);
    } catch (e) {
      print('❌ Add Food Error: $e');
      ElegantSnackbar.error(Get.context, 'Waduh, ada error nih. Coba lagi ya');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Update existing food entry
  Future<void> updateFood() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    
    if (foodId == null) {
      ElegantSnackbar.error(Get.context, 'ID makanan tidak ditemukan');
      return;
    }

    // Extract values
    final name = nameController.text.trim();
    final sugarInGrams = getSugarInGrams();
    final calories = double.tryParse(calorieContentController.text) ?? 0.0;
    final weight = double.tryParse(weightController.text) ?? 0.0;
    final quantity = int.tryParse(quantityController.text) ?? 1;

    if (name.length < 2) {
      ElegantSnackbar.error(Get.context, 'Nama makanan minimal 2 karakter');
      return;
    }

    // Flexible Validation (Same as addFood)
    final hasSugar = sugarContentController.text.isNotEmpty && sugarInGrams > 0;
    final hasCalories = calorieContentController.text.isNotEmpty && calories > 0;

    if (!hasSugar && !hasCalories) {
      ElegantSnackbar.error(Get.context, 'Isi minimal satu: Kandungan gula atau kalori');
      return;
    }

    // Weight is optional, default to 0
    if (quantity < 1) {
      ElegantSnackbar.error(Get.context, 'Jumlah porsi tidak valid');
      return;
    }

    // Confirmation if only one is filled
    if (hasSugar && !hasCalories) {
      _showConfirmationDialog('Kamu cuma isi Gula, yakin Kalorinya 0?', () => _checkLimitsAndProceed(_performUpdate));
      return;
    }
    
    if (!hasSugar && hasCalories) {
      _showConfirmationDialog('Kamu cuma isi Kalori, yakin Gulanya 0?', () => _checkLimitsAndProceed(_performUpdate));
      return;
    }

    _checkLimitsAndProceed(_performUpdate);
  }

  Future<void> _performUpdate() async {
    isLoading.value = true;

    // Extract values
    final name = nameController.text.trim();
    final sugarInGrams = getSugarInGrams();
    final calories = double.tryParse(calorieContentController.text) ?? 0.0;
    final weight = double.tryParse(weightController.text) ?? 0.0;
    final quantity = int.tryParse(quantityController.text) ?? 1;

    try {
      final response = await _apiClient.put(
        '/food/$foodId',
        data: {
          'name': name,
          'sugarContent': sugarInGrams,
          'calorieContent': calories,
          'weight': weight,
          'weightUnit': weightUnit.value,
          'quantity': quantity,
          'consumptionTime': consumptionTime.value.toIso8601String(),
          'isScanned': isFromScan.value,
        },
      );

      if (response.statusCode == 200) {
        Get.back(); // Close edit screen
        
        // Extract message from backend and show snackbar
        final message = response.data['message'] ?? 'Oke, catatan konsumsi berhasil diupdate';
        ElegantSnackbar.success(Get.context, message);

        // Refresh dashboard if it exists
        try {
          if (Get.isRegistered<DashboardController>()) {
            Get.find<DashboardController>().fetchDashboardData();
          }
        } catch (e) {}

        // Refresh History if it exists (User request: redirect & refresh history)
        // Refresh history if exists
        try {
          if (Get.isRegistered<HistoryController>()) {
            Get.find<HistoryController>().fetchHistory();
          }
        } catch (e) {}
        
        // Simpan timestamp & refresh notif
        await StorageService().setLastFoodInputTime(DateTime.now());
        await NotificationService().refreshSystemNotifications();
      }
    } on NetworkException catch (e) {
      ErrorSnackbar.show(Get.context!, e.message);
    } catch (e) {
      print('❌ Update Food Error: $e');
      ElegantSnackbar.error(Get.context, 'Waduh, ada error nih. Coba lagi ya');
    } finally {
      isLoading.value = false;
    }
  }

  /// Target limit checker
  Future<void> _checkLimitsAndProceed(VoidCallback performAction) async {
    // Get current stats
    DashboardStatsModel? stats;
    try {
      if (Get.isRegistered<DashboardController>()) {
        stats = Get.find<DashboardController>().stats.value;
      }
    } catch (e) {
      print('Warning: DashboardController not found or stats error');
    }

    if (stats == null) {
      performAction();
      return;
    }

    final newSugar = getSugarInGrams();
    final newCalories = double.tryParse(calorieContentController.text) ?? 0.0;
    final quantity = int.tryParse(quantityController.text) ?? 1;

    final totalNewSugar = newSugar * quantity;
    final totalNewCalories = newCalories * quantity;

    double addedSugar = totalNewSugar;
    double addedCalories = totalNewCalories;

    if (isEditMode.value) {
       addedSugar -= _oldTotalSugar;
       addedCalories -= _oldTotalCalories;
    }

    final currentSugar = stats.sugar.consumed;
    final sugarGoal = stats.sugar.goal;
    
    final currentCalories = stats.calories.consumed;
    final caloriesGoal = stats.calories.goal;

    bool sugarExceeded = false;
    bool caloriesExceeded = false;

    // Check if goal is present to avoid dividing by 0 or false warnings
    if (sugarGoal > 0 && (currentSugar + addedSugar) >= sugarGoal && addedSugar > 0) {
      sugarExceeded = true;
    }

    if (caloriesGoal > 0 && (currentCalories + addedCalories) >= caloriesGoal && addedCalories > 0) {
      caloriesExceeded = true;
    }

    if (sugarExceeded || caloriesExceeded) {
      String message = '';
      
      // Hitung sisa sebelum tambahan ini masuk
      double remainSugar = sugarGoal - currentSugar;
      if (remainSugar < 0) remainSugar = 0;
      
      double remainCalories = caloriesGoal - currentCalories;
      if (remainCalories < 0) remainCalories = 0;

      if (sugarExceeded && caloriesExceeded) {
        message = 'WADUH! Sisa jatah gula harian kamu itu cuma tinggal ${remainSugar.toStringAsFixed(0)}g & kalori ${remainCalories.toStringAsFixed(0)} kcal.\n\n'
                  'Tapi kamu malah mau masukin makanan/minuman dengan gula ${addedSugar.toStringAsFixed(0)}g dan kalori ${addedCalories.toStringAsFixed(0)} kcal!\n\n'
                  'Serius nih tetep ngeyel? Sakit itu ga enak hey, atau minimal jangan nyusahin keluarga deh!';
      } else if (sugarExceeded) {
        message = 'HEI! Sisa jatah gula harianmu itu cuma tinggal ${remainSugar.toStringAsFixed(0)}g doang, '
                  'tapi kamu maksa masukin ${addedSugar.toStringAsFixed(0)}g lagi?!\n\n'
                  'Yakin mau tetep disimpan? Niat sehat ga sih?!';
      } else {
        message = 'STOP! Sisa kalori hari ini cuma sisa ${remainCalories.toStringAsFixed(0)} kcal lagi, '
                  'malah mau dijebol dengan nambahin ${addedCalories.toStringAsFixed(0)} kcal!\n\n'
                  'Mau nabung lemak sampai kapan? Yakin masih ngeyel mau ditambah?';
      }
      
      final proceed = await _showTargetWarningDialog(message);
      if (!proceed) return;
    }

    performAction();
  }

  /// Custom Warning Popup Dialog
  Future<bool> _showTargetWarningDialog(String messageStr) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF5350).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFEF5350),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Target Terlampaui!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF5350).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFEF5350).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Text(
                messageStr,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.back(result: false),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFFEF5350),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Ga jadi deh',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.back(result: true),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF80CBC4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Tambah aja',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return result ?? false;
  }

  /// AI Feature for Manual Input
  Future<void> pickImageForAi() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        aiImagePath.value = image.path;
      }
    } catch (e) {
      ElegantSnackbar.error(Get.context, 'Gagal memilih gambar: $e');
    }
  }

  Future<void> processManualWithGemini() async {
    final promptStr = aiPromptController.text.trim();
    if (promptStr.isEmpty && aiImagePath.value.isEmpty) {
      ElegantSnackbar.error(Get.context, 'Tulis deskripsi makanan atau upload foto dulu ya.');
      return;
    }

    // API Key already handled globally

    isLoading.value = true;
    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: ApiKeys.geminiApiKey,
      );

      final prompt = TextPart(
          'Anda adalah ahli gizi. Tugas Anda mengestimasi nama makanan, kandungan kalori, dan kandungan gula dari cerita user atau foto yang diberikan.\n\n'
          'Cerita User: "$promptStr"\n\n'
          'Aturan wajib:\n'
          '1. Kembalikan HANYA JSON murni tanpa Markdown.\n'
          '2. Berikan estimasi Karbohidrat Gula (Sugar) dalam gram dan Energi Total / Kalori (Calories) dalam kkal.\n'
          '3. Tentukan nama makanannya secara singkat dan padat (misal "Nasi Padang Ayam").\n'
          '4. Jika tidak bisa ditebak sama sekali, kembalikan {"is_valid": false}.\n'
          '5. Jika bisa ditebak, kembalikan {"is_valid": true, "name": "Nama Makanan", "sugar": ..., "calories": ...}.\n'
          'Format Keluaran Sukses: {"is_valid": true, "name": "Nasi Padang Ayam", "sugar": 15.0, "calories": 650.0}');

      List<Part> parts = [prompt];

      if (aiImagePath.value.isNotEmpty) {
        final imageBytes = await File(aiImagePath.value).readAsBytes();
        parts.add(DataPart('image/jpeg', imageBytes));
      }

      final response = await model.generateContent([
        Content.multi(parts)
      ]);

      if (response.text != null && response.text!.isNotEmpty) {
        String cleanJson = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
        Map<String, dynamic> data = json.decode(cleanJson);
        
        if (data['is_valid'] == false) {
           ElegantSnackbar.error(Get.context, 'AI kebingungan tebak makanan dari ceritamu. Coba lebih spesifik.');
           return;
        }

        if (data['name'] != null) nameController.text = data['name'].toString();
        if (data['sugar'] != null) {
          sugarContentController.text = (data['sugar'] as num).toDouble().toStringAsFixed(1);
          sugarUnit.value = 'gram'; // Paksa ke gram
        }
        if (data['calories'] != null) {
          calorieContentController.text = (data['calories'] as num).toDouble().toStringAsFixed(0);
        }

        // Tampilkan summary & hasil tanpa menutup mode AI
        hasAiResult.value = true;
        _updateIntakeSummary();
        
        // Scroll ke bawah agar hasil terlihat
        Future.delayed(const Duration(milliseconds: 300), () {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
            );
          }
        });
      } else {
        ElegantSnackbar.error(Get.context, 'Gagal terhubung ke AI. Coba lagi.');
      }
    } catch (e) {
      print('❌ Gemini Manual Error: $e');
      ElegantSnackbar.error(Get.context, 'Error dari AI: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
