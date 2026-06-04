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

  /// Cek apakah user sedang dalam fase stabilisasi (4 minggu / 28 hari)
  bool get isStabilizationPhase {
    final updateTime = user.value?.bmiCategoryUpdatedAt;
    final previousCat = user.value?.previousBmiCategory;
    final currentCat = user.value?.bmi != null ? BMIHelper.getCategory(user.value!.bmi).name : null;
    
    if (updateTime != null && previousCat != null && currentCat != null && previousCat != currentCat) {
      final diff = DateTime.now().difference(updateTime).inDays;
      return diff < 28;
    }
    return false;
  }

  /// Menghitung sisa hari stabilisasi
  int get stabilizationDaysLeft {
    final updateTime = user.value?.bmiCategoryUpdatedAt;
    final previousCat = user.value?.previousBmiCategory;
    final currentCat = user.value?.bmi != null ? BMIHelper.getCategory(user.value!.bmi).name : null;
    
    if (updateTime != null && previousCat != null && currentCat != null && previousCat != currentCat) {
      final diff = DateTime.now().difference(updateTime).inDays;
      if (diff < 28) {
        return 28 - diff;
      }
    }
    return 0;
  }

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
    if (weightVal == null || weightVal < 30 || weightVal > 300) {
      return 'Berat badan harus 30-300 kg nih';
    }
    return null;
  }

  /// Validate Height
  String? validateHeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tinggi badan diisi ya';
    }
    final heightVal = double.tryParse(value);
    if (heightVal == null || heightVal < 100 || heightVal > 250) {
      return 'Tinggi badan harus 100-250 cm nih';
    }
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
      
      // Calculate new BMI category locally to detect changes
      final newBmi = weight / ((height / 100) * (height / 100));
      
      String getCategoryFromValue(double bmiVal) {
        if (bmiVal < 18.5) return 'Kurus';
        if (bmiVal < 25.0) return 'Normal';
        if (bmiVal < 27.0) return 'Gemuk (Overweight)';
        if (bmiVal < 30.0) return 'Obesitas Tingkat 1';
        return 'Obesitas Tingkat 2';
      }

      final currentCategory = getCategoryFromValue(bmi.value ?? 0);
      final newCategory = getCategoryFromValue(newBmi);

      String? updatedPreviousCategory = userModel?.previousBmiCategory;
      DateTime? updatedCategoryTime = userModel?.bmiCategoryUpdatedAt;

      bool goalsUpdated = false;
      Map<String, dynamic>? newGoals;
      
      // Simpan goals saat ini (custom goals user) biar nggak ke-reset sepihak sama backend
      final currentCustomGoals = userModel?.goals;

      bool stabilityPassed = false;

      if (currentCategory != newCategory && bmi.value != null && bmi.value! > 0) {
        int getSeverity(String cat) {
          if (cat == 'Normal') return 0;
          if (cat == 'Kurus' || cat == 'Gemuk (Overweight)') return 1;
          if (cat == 'Obesitas Tingkat 1') return 2;
          if (cat == 'Obesitas Tingkat 2') return 3;
          return 0;
        }
        
        bool isWorsening = getSeverity(newCategory) > getSeverity(currentCategory);
        
        if (isWorsening) {
          // BMI memburuk (makin jauh dari Normal), langsung update goals
          updatedPreviousCategory = newCategory;
          updatedCategoryTime = DateTime.now();
          
          final categoryClass = BMIHelper.getCategory(newBmi);
          newGoals = {
            'dailySugarGoal': categoryClass.defaultSugar,
            'dailyCalorieGoal': categoryClass.defaultCalories,
            'dailyWaterGoal': categoryClass.defaultWater,
            'dailyBurnGoal': categoryClass.defaultBurn,
          };
          try {
            await _apiClient.put(ApiEndpoints.updateGoals, data: newGoals);
            goalsUpdated = true;
          } catch (e) {
            print('❌ Failed to auto-update goals dynamically: $e');
          }
        } else {
          // BMI membaik (mendekati Normal), masuk fase stabilitas
          updatedPreviousCategory = currentCategory;
          updatedCategoryTime = DateTime.now();
        }
      } 
      // Jika kategori tidak berubah, cek apakah user sedang dalam masa stabilitas
      else if (currentCategory == newCategory && updatedCategoryTime != null && updatedPreviousCategory != null && updatedPreviousCategory != currentCategory) {
        final diff = DateTime.now().difference(updatedCategoryTime).inDays;
        if (diff >= 28) {
          // LULUS Fase stabilitas (sudah 28 hari konsisten di BMI baru)
          
          // Cek apakah target saat ini adalah custom target
          bool isCustomized = false;
          if (currentCustomGoals != null) {
            BMICategory? oldCat;
            for (var cat in BMIHelper.categories) {
              if (cat.name == updatedPreviousCategory) { oldCat = cat; break; }
            }
            if (oldCat != null) {
              if (currentCustomGoals.dailyCalorieGoal != oldCat.defaultCalories ||
                  currentCustomGoals.dailySugarGoal != oldCat.defaultSugar ||
                  currentCustomGoals.dailyWaterGoal != oldCat.defaultWater ||
                  currentCustomGoals.dailyBurnGoal != oldCat.defaultBurn) {
                isCustomized = true;
              }
            }
          }
          
          updatedPreviousCategory = newCategory; // Set sama agar stabilitas selesai
          updatedCategoryTime = DateTime.now();
          stabilityPassed = true;
          
          if (!isCustomized) {
            final categoryClass = BMIHelper.getCategory(newBmi);
            newGoals = {
              'dailySugarGoal': categoryClass.defaultSugar,
              'dailyCalorieGoal': categoryClass.defaultCalories,
              'dailyWaterGoal': categoryClass.defaultWater,
              'dailyBurnGoal': categoryClass.defaultBurn,
            };
            try {
              await _apiClient.put(ApiEndpoints.updateGoals, data: newGoals);
              goalsUpdated = true;
            } catch (e) {
              print('❌ Failed to auto-update goals dynamically: $e');
            }
          }
        }
      }

      final Map<String, dynamic> data = {
        'weight': weight,
        'height': height,
        'lastBodyMetricsUpdate': DateTime.now().toIso8601String(),
        if (updatedPreviousCategory != null) 'previousBmiCategory': updatedPreviousCategory,
        if (updatedCategoryTime != null) 'bmiCategoryUpdatedAt': updatedCategoryTime.toIso8601String(),
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
            previousBmiCategory: updatedPreviousCategory,
            bmiCategoryUpdatedAt: updatedCategoryTime,
          );
        }

        // Update SecureStorage
        final currentUserData = await _storage.getUserData() ?? {};
        currentUserData['weight'] = weight;
        currentUserData['height'] = height;
        currentUserData['lastBodyMetricsUpdate'] = DateTime.now().toIso8601String();
        if (updatedPreviousCategory != null) currentUserData['previousBmiCategory'] = updatedPreviousCategory;
        if (updatedCategoryTime != null) currentUserData['bmiCategoryUpdatedAt'] = updatedCategoryTime.toIso8601String();
        if (responseData['bmi'] != null) currentUserData['bmi'] = responseData['bmi'];
        
        if (goalsUpdated && newGoals != null) {
          currentUserData['goals'] = {
            'dailySugarGoal': newGoals['dailySugarGoal'],
            'dailyCalorieGoal': newGoals['dailyCalorieGoal'],
            'dailyWaterGoal': newGoals['dailyWaterGoal'],
            'dailyBurnGoal': newGoals['dailyBurnGoal'],
          };
          user.value = user.value?.copyWith(
             goals: GoalsModel(
                dailySugarGoal: (newGoals['dailySugarGoal'] as num).toDouble(),
                dailyCalorieGoal: (newGoals['dailyCalorieGoal'] as num).toDouble(),
                dailyWaterGoal: (newGoals['dailyWaterGoal'] as num).toDouble(),
                dailyBurnGoal: (newGoals['dailyBurnGoal'] as num).toDouble(),
             ),
          );
        }
        
        await _storage.saveUserData(currentUserData);
        
        // Setup Schedule For Local Notification Again here later
        // ...

        Get.back(); // Tutup bottom sheet
        await Future.delayed(const Duration(milliseconds: 300));
        
        if (currentCategory != newCategory && bmi.value != null && bmi.value! > 0) {
          // Kategori berubah! Tampilkan Popup Dialog
          Get.dialog(
            Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.swap_vert_rounded, color: Color(0xFF00897B), size: 36),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Kategori BMI Berubah!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        text: 'Status BMI kamu bergeser dari\n',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
                        children: [
                          TextSpan(text: currentCategory, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          const TextSpan(text: ' menjadi '),
                          TextSpan(text: newCategory, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                          const TextSpan(text: '.'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        goalsUpdated 
                          ? 'Target harianmu otomatis kita sesuaikan sama BMI $newCategory ya. Kita bantu atur targetnya pelan-pelan biar BMI kamu bisa balik normal lagi. Tetap semangat penuhi targetnya!' 
                          : 'Target harianmu belum berubah ke $newCategory soalnya kamu lagi masuk Fase Stabilitas (28 hari). Jadi target harian kamu masih sama pas BMI kamu $currentCategory. Kita kunci sementara biar berat badanmu ngga gampang naik-turun. Tetap semangat ya!',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Get.back(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00897B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Siap, Mengerti!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            barrierDismissible: false,
          );
        } else if (stabilityPassed) {
          // Tampilkan popup stabilitas lulus
          Get.dialog(
            Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_outline, color: Color(0xFF00897B), size: 36),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Selamat! Stabilitas Lulus',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      goalsUpdated 
                          ? 'Selamat! 🎉 Kamu hebat banget udah berhasil ngejaga kestabilan BMI selama 28 hari! Target harianmu sekarang resmi kita perbarui ngikutin anjuran BMI barumu. Pertahankan terus ya pencapaiannya!'
                          : 'Selamat! 🎉 Kestabilan BMI 28 hari berhasil tercapai, keren!\n\nKarena kamu punya target custom, target lamamu tetep kita pertahankan kok. Tapi kalau kamu mau ganti ke target anjuran BMI baru, kamu udah dapet lampu hijau nih buat ngaturnya di menu Target. Pertahankan terus ya!',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Get.back(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00897B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Mantap!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            barrierDismissible: false,
          );
        } else {
          // Kategori tidak berubah, tampilkan snackbar biasa
          ElegantSnackbar.success(
            Get.context!,
            'Mantap! Rajin-rajin cek BB dan TB ya biar targetmu selalu update dan pas sama kondisi badan.',
            duration: const Duration(seconds: 4),
          );
        }
        
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
