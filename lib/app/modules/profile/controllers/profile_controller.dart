import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scansek/app/widgets/states/error_state.dart';
import '../../../../app/data/providers/api/api_client.dart';
import '../../../../app/data/providers/api/api_endpoints.dart';
import '../../../../app/data/providers/api/network_exception.dart';
import 'package:scansek/app/data/models/user_model.dart';
import 'package:scansek/app/routes/app_pages.dart';
import 'package:scansek/app/data/providers/local/storage_service.dart';
import 'package:scansek/app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:scansek/app/widgets/snackbars/snackbar_designs.dart';
import 'package:scansek/app/core/utils/bmi_helper.dart';
import 'package:scansek/app/services/notification_service.dart';

class ProfileController extends GetxController {
  final _apiClient = ApiClient();
  late final StorageService _storage;
  
  // Observable user data
  final userName = ''.obs;
  final userEmail = ''.obs;
  final weight = Rx<double?>(null);
  final height = Rx<double?>(null);
  final bmi = Rx<double?>(null);
  final dateOfBirth = Rx<String?>(null);
  final gender = ''.obs;
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final isLoading = false.obs;
  final RxBool shouldShowUpdateMetricsBanner = false.obs;
  final RxBool isFastingMode = false.obs;



  @override
  void onInit() {
    super.onInit();
    _initStorage();
  }

  Future<void> _initStorage() async {
    try {
      _storage = StorageService();
      await _storage.init();
      await fetchUserProfile();
    } catch (e) {
      print('Error initializing storage: $e');
      // Use default values if storage init fails
      userName.value = 'User';
      userEmail.value = 'user@example.com';
    }
  }

  Future<void> fetchUserProfile() async {
    try {
      isLoading.value = true;
      
      final response = await _apiClient.get('/users/profile');
      
      if (response.statusCode == 200) {
        final data = response.data['data'];
        user.value = UserModel.fromJson(data);
        userName.value = user.value?.name ?? '';
        userEmail.value = user.value?.email ?? '';
        weight.value = data['weight']?.toDouble();
        height.value = data['height']?.toDouble();
        bmi.value = data['bmi']?.toDouble();
        bmi.value = data['bmi']?.toDouble();
        
        // Format date if it contains time
        String? dob = data['dateOfBirth'];
        if (dob != null && dob.contains('T')) {
          dob = dob.split('T')[0];
        }
        dateOfBirth.value = dob;
        
        gender.value = data['gender'] ?? '';
        
        // Evaluate update banner visibility
         if (user.value?.lastBodyMetricsUpdate != null) {
            final daysSince = DateTime.now().difference(user.value!.lastBodyMetricsUpdate!).inDays;
            shouldShowUpdateMetricsBanner.value = daysSince >= 7;
         } else if (user.value?.createdAt != null) {
            final daysSince = DateTime.now().difference(user.value!.createdAt!).inDays;
            shouldShowUpdateMetricsBanner.value = daysSince >= 7;
         } else {
            shouldShowUpdateMetricsBanner.value = false;
         }
         
         // Update Storage with latest user data so Dashboard reads it correctly
         await _storage.saveUserData(user.value!.toJson());
         
         // Update Fasting Mode
         isFastingMode.value = _storage.isFastingMode;
         
         // Sync Dashboard
         if (Get.isRegistered<DashboardController>()) {
           Get.find<DashboardController>().fetchDashboardData();
         }
      } else {
        print('Gagal memuat profil: ${response.statusCode}');
      }
    } on NetworkException catch (e) {
      if (user.value == null) {
        ErrorSnackbar.show(Get.context!, e.message);
      }
      print('Network error fetching profile: ${e.message}');
    } catch (e) {
      print('Error fetching profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Check if profile is complete
  bool isProfileComplete() {
    return weight.value != null && 
           height.value != null && 
           dateOfBirth.value != null;
  }

  // Form Key
  final formKey = GlobalKey<FormState>();

  /// Validate Name
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama lengkap diisi dulu dong';
    }
    if (value.length < 3) {
      return 'Nama minimal 3 karakter ya';
    }
    return null;
  }

  /// Validate Weight
  String? validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Berat badan diisi ya';
    }
    final weightVal = double.tryParse(value);
    if (weightVal == null) return 'Format angka tidak valid';
    if (weightVal < 30) return 'Berat badan minimal 30 kg';
    if (weightVal > 150) return 'Angka ini butuh pantauan dokter spesialis khusus';
    return null;
  }

  /// Validate Height
  String? validateHeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tinggi badan diisi ya';
    }
    final heightVal = double.tryParse(value);
    if (heightVal == null) return 'Format angka tidak valid';
    if (heightVal < 100) return 'Tinggi badan minimal 100 cm';
    if (heightVal > 210) return 'Angka ini butuh pantauan dokter spesialis khusus';
    return null;
  }

  /// Get BMI category
  String getBmiCategory() {
    if (bmi.value == null) return 'Unknown';
    return BMIHelper.getCategory(bmi.value!).name;
  }

  /// Get BMI color
  Color getBmiColor() {
    if (bmi.value == null) return Colors.grey;
    final catName = BMIHelper.getCategory(bmi.value!).name;
    
    if (catName.contains('Kurus')) return Colors.blue;
    if (catName.contains('Normal')) return Colors.green;
    if (catName.contains('Gemuk')) return Colors.orange;
    return Colors.red; // Obesitas 1 & 2
  }

  /// Update user name
  Future<void> updateUserName(String newName) async {
    try {
      isLoading.value = true;
      
      final response = await _apiClient.put('/users/profile', data: {
        'name': newName,
      });
      
      if (response.statusCode == 200) {
        userName.value = newName;
        // Update user model
        if (user.value != null) {
          user.value = user.value!.copyWith(name: newName);
        }
        
        // Update SecureStorage (user data) so dashboard can read updated name
        final currentUserData = await _storage.getUserData() ?? {};
        currentUserData['name'] = newName;
        await _storage.saveUserData(currentUserData);
        
        // Also save to SharedPreferences for backwards compatibility
        await _storage.saveString('user_name', newName);
        
        // Refresh dashboard data (including name) if controller exists
        if (Get.isRegistered<DashboardController>()) {
          Get.find<DashboardController>().refreshUserName();
        }
      }
    } on NetworkException catch (e) {
      ErrorSnackbar.show(Get.context!, e.message);
      print('Network error updating profile name: ${e.message}');
    } catch (e) {
      print('Error updating profile: $e');
      // Still update locally even if API fails
      userName.value = newName;
      final currentUserData = await _storage.getUserData() ?? {};
      currentUserData['name'] = newName;
      await _storage.saveUserData(currentUserData);
      await _storage.saveString('user_name', newName);
    } finally {
      isLoading.value = false;
    }
  }

  /// Update complete profile with all fields
  Future<void> updateProfile({
    String? name,
    double? weight,
    double? height,
    String? dateOfBirth,
    String? gender,
  }) async {
    try {
      isLoading.value = true;
      
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (weight != null) data['weight'] = weight;
      if (height != null) data['height'] = height;
      if (dateOfBirth != null) data['dateOfBirth'] = dateOfBirth;
      if (gender != null) data['gender'] = gender;
      
      final response = await _apiClient.put('/users/profile', data: data);
      
      if (response.statusCode == 200) {
        // Update local observables
        if (name != null) userName.value = name;
        if (weight != null) this.weight.value = weight;
        if (height != null) this.height.value = height;
        if (dateOfBirth != null) this.dateOfBirth.value = dateOfBirth;
        if (gender != null) this.gender.value = gender;
        
        // Update BMI from backend response
        final responseData = response.data['data'];
        if (responseData['bmi'] != null) {
          bmi.value = responseData['bmi'].toDouble();
        }
        
        // Update SecureStorage (user data) so dashboard can read updated name
        final currentUserData = await _storage.getUserData() ?? {};
        if (name != null) currentUserData['name'] = name;
        if (weight != null) currentUserData['weight'] = weight;
        if (height != null) currentUserData['height'] = height;
        if (dateOfBirth != null) currentUserData['dateOfBirth'] = dateOfBirth;
        if (gender != null) currentUserData['gender'] = gender;
        if (responseData['bmi'] != null) currentUserData['bmi'] = responseData['bmi'];
        await _storage.saveUserData(currentUserData);
        
        // Also save to SharedPreferences for backwards compatibility
        if (name != null) await _storage.saveString('user_name', name);

        // Refresh dashboard data (including name) if controller exists
        if (Get.isRegistered<DashboardController>()) {
          Get.find<DashboardController>().refreshUserName();
        }
      }
    } on NetworkException catch (e) {
      ErrorSnackbar.show(Get.context!, e.message);
      rethrow;
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update Body Metrics specifically with 7-Day Lock & 4-Week Cooldown Tracking
  Future<void> updateBodyMetrics({required double weight, required double height}) async {
    final userModel = user.value;
    
    // Anti-Bypass Lock: Check if < 7 days
    if (userModel?.lastBodyMetricsUpdate != null) {
      final daysSinceLastUpdate = DateTime.now().difference(userModel!.lastBodyMetricsUpdate!).inDays;
      if (daysSinceLastUpdate < 7) {
        Get.back(); // Tutup bottom sheet
        await Future.delayed(const Duration(milliseconds: 300));
        ElegantSnackbar.warning(
          Get.context!, // Pass explicit context
          'Kamu baru bisa update BB & TB lagi dalam ${7 - daysSinceLastUpdate} hari ke depan.',
        );
        return;
      }
    }

    try {
      isLoading.value = true;
      
      final Map<String, dynamic> data = {
        'weight': weight,
        'height': height,
        'lastBodyMetricsUpdate': DateTime.now().toIso8601String(),
      };
      
      final response = await _apiClient.put('/users/profile', data: data);
      
      if (response.statusCode == 200) {
        // Update local observables
        this.weight.value = weight;
        this.height.value = height;
        
        final responseData = response.data['data'];
        if (responseData['bmi'] != null) {
          bmi.value = responseData['bmi'].toDouble();
        }
        
        // Update user model cache
        if (userModel != null) {
          user.value = userModel.copyWith(
            weight: weight,
            height: height,
            bmi: bmi.value,
            lastBodyMetricsUpdate: DateTime.now(),
          );
        }

        // Update SecureStorage
        final currentUserData = await _storage.getUserData() ?? {};
        currentUserData['weight'] = weight;
        currentUserData['height'] = height;
        currentUserData['lastBodyMetricsUpdate'] = DateTime.now().toIso8601String();
        if (responseData['bmi'] != null) currentUserData['bmi'] = responseData['bmi'];
        
        await _storage.saveUserData(currentUserData);
        
        Get.back(); // Tutup bottom sheet
        await Future.delayed(const Duration(milliseconds: 300));
        
        ElegantSnackbar.success(
          Get.context!,
          'Mantap! Rajin-rajin cek BB dan TB ya.',
          duration: const Duration(seconds: 4),
        );
        
        // Hide local profile banner immediately
        shouldShowUpdateMetricsBanner.value = false;
        
        // Refresh dashboard so banner hides
        if (Get.isRegistered<DashboardController>()) {
          Get.find<DashboardController>().fetchDashboardData();
        }
      }
    } on NetworkException catch (e) {
      ErrorSnackbar.show(Get.context!, e.message);
    } catch (e) {
      print('Error updating body metrics: $e');
      ErrorSnackbar.show(Get.context!, 'Terjadi kesalahan sistem: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void logout() {
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
                  color: Colors.red[50], // Soft red background
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 48,
                  color: Colors.red, // Red icon
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Konfirmasi Keluar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3E50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Yakin nih mau keluar dari akun kamu?',
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
                        'Batal',
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
                      onPressed: () async {
                        try {
                          // Clear all local notifications
                          await NotificationService().cancelAll();
                          
                          // Clear all storage (logout)
                          await _storage.clearAll();
                          
                          // Navigate to login
                          Get.back(); // Close dialog
                          Get.offAllNamed(Routes.LOGIN);
                        } catch (e) {
                          print('Error logout: $e');
                          // Still navigate even if error
                          Get.back();
                          Get.offAllNamed(Routes.LOGIN);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Keluar',
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
}
