import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scansek/app/data/providers/api/api_client.dart';
import 'package:scansek/app/data/providers/api/api_endpoints.dart';
import 'package:scansek/app/data/providers/api/network_exception.dart';
import 'package:scansek/app/data/providers/local/storage_service.dart';
import 'package:scansek/app/core/utils/bmi_helper.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../../widgets/states/error_state.dart';
import '../../../widgets/snackbars/snackbar_designs.dart';

class GoalsController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();
  final StorageService _storage = Get.find<StorageService>();

  // Form key for validation
  final formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController sugarController = TextEditingController();
  final TextEditingController caloriesController = TextEditingController();
  final TextEditingController waterController = TextEditingController();
  final TextEditingController burnController = TextEditingController();

  // Observable states
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;

  // WHO recommendations
  static const double whoSugarLimit = 50.0; // grams
  static const double whoCalorieLimit = 2000.0; // kcal

  @override
  void onInit() {
    super.onInit();
    _loadCurrentGoals();
  }

  @override
  void onClose() {
    sugarController.dispose();
    caloriesController.dispose();
    waterController.dispose();
    burnController.dispose();
    super.onClose();
  }

  /// Load current goals from user data
  Future<void> _loadCurrentGoals() async {
    isLoading.value = true;

    try {
      final userData = await _storage.getUserData();
      
      if (userData != null && userData['goals'] != null) {
        final goals = userData['goals'];
        sugarController.text = _formatValue(goals['dailySugarGoal'] ?? goals['sugar'] ?? whoSugarLimit);
        caloriesController.text = _formatValue(goals['dailyCalorieGoal'] ?? goals['calories'] ?? whoCalorieLimit);
        waterController.text = _formatValue(goals['dailyWaterGoal'] ?? goals['water'] ?? 2000);
        burnController.text = _formatValue(goals['dailyBurnGoal'] ?? goals['burn'] ?? 0);
      } else {
        // Set defaults
        sugarController.text = _formatValue(whoSugarLimit);
        caloriesController.text = _formatValue(whoCalorieLimit);
        waterController.text = '2000';
        burnController.text = '400';
      }
    } catch (e) {
      print('Error loading goals: $e');
      // Set defaults on error
      sugarController.text = whoSugarLimit.toString();
      caloriesController.text = whoCalorieLimit.toString();
      waterController.text = '2000';
      burnController.text = '400';
    } finally {
      isLoading.value = false;
    }
  }

  /// Validate and save goals
  Future<void> saveGoals() async {
    // Use form validation
    if (!formKey.currentState!.validate()) {
      // Show snackbar when validation fails
      ElegantSnackbar.error(
        Get.context,
        'Yang bener kalo isi target! ada yang salah tuh',
      );
      return;
    }

    // Parse values - guaranteed to work since form validated
    // Use double.parse().toInt() to handle "2000.0" strings safely
    final sugar = double.parse(sugarController.text.trim());
    final calories = double.parse(caloriesController.text.trim());
    final water = double.tryParse(waterController.text.trim())?.toInt() ?? 0;
    final burn = double.tryParse(burnController.text.trim()) ?? 0.0;

    // Fetch user data for BMI & Stabilization tracking
    final userData = await _storage.getUserData();
    double userWeight = 0;
    double userHeight = 0;
    String? previousBmiCategoryName;
    DateTime? bmiCategoryUpdatedAt;

    if (userData != null) {
      userWeight = double.tryParse(userData['weight']?.toString() ?? '0') ?? 0;
      userHeight = double.tryParse(userData['height']?.toString() ?? '0') ?? 0;
      previousBmiCategoryName = userData['previousBmiCategory'];
      if (userData['bmiCategoryUpdatedAt'] != null) {
        bmiCategoryUpdatedAt = DateTime.tryParse(userData['bmiCategoryUpdatedAt'].toString());
      }
    }
    
    BMICategory? bmiCategory;
    if (userWeight > 0 && userHeight > 0) {
      final bmi = BMIHelper.hitungBMI(userWeight, userHeight);
      bmiCategory = BMIHelper.getCategory(bmi);
    }

    // Check limits (minimums & maximums)
    List<Map<String, dynamic>> warningList = [];
    
    // Evaluate 4-Week Cooldown logic
    bool isCooldownActive = false;
    BMICategory? previousCategoryParams;
    int cooldownDaysLeft = 0;

    if (bmiCategoryUpdatedAt != null && previousBmiCategoryName != null && bmiCategory != null && previousBmiCategoryName != bmiCategory.name) {
       final diffDays = DateTime.now().difference(bmiCategoryUpdatedAt).inDays;
       if (diffDays < 28) {
           try {
             final prevParams = BMIHelper.categories.firstWhere((c) => c.name == previousBmiCategoryName);
             
             int getSeverity(String cat) {
               if (cat == 'Normal') return 0;
               if (cat == 'Kurus' || cat == 'Gemuk (Overweight)') return 1;
               if (cat == 'Obesitas Tingkat 1') return 2;
               if (cat == 'Obesitas Tingkat 2') return 3;
               return 0;
             }
             
             int prevSeverity = getSeverity(prevParams.name);
             int currSeverity = getSeverity(bmiCategory.name);
             
             // Cooldown berlaku jika tingkat keparahan (severity) berkurang / membaik
             // Contoh: Obesitas 1 (2) -> Normal (0). Kurus (1) -> Normal (0).
             if (prevSeverity > currSeverity) {
                 isCooldownActive = true;
                 cooldownDaysLeft = 28 - diffDays;
                 previousCategoryParams = prevParams;
             }
           } catch (e) {
             // fallback
           }
       }
    }

    // --- Calories ---
    if (calories < 1200) {
       warningList.add({'text': 'Target kalori $calories kcal kerendahan nih. Tubuhmu tetep butuh energi dasar buat metabolisme harian, jangan sampai kurang gizi ya.'});
    } else if (calories > 3500) {
       warningList.add({'text': 'Target kalori $calories kcal agak tinggi nih. Pastiin kamu imbangin sama olahraga rutin ya, biar nggak numpuk jadi lemak.'});
    } else if (isCooldownActive && previousCategoryParams != null && previousCategoryParams.name.contains('Obesitas') && calories > previousCategoryParams.defaultCalories) {
       warningList.add({'text': 'Target kalori masuk selama fase stabilisasi maksimal ${previousCategoryParams.defaultCalories} kcal. Soalnya lambung dan metabolismemu belum stabil, kalori berlebih bakal langsung ditumpuk jadi lemak lagi (rebound).'});
    } else if (isCooldownActive && previousCategoryParams != null && previousCategoryParams.name.contains('Kurus') && calories < previousCategoryParams.defaultCalories) {
       warningList.add({'text': 'Target kalori masuk selama fase stabilisasi minimal ${previousCategoryParams.defaultCalories} kcal. Biarpun kamu udah Normal, tubuhmu masih butuh asupan surplus buat ngunci berat badan ideal ini biar nggak gampang anjlok lagi.'});
    } else if (!isCooldownActive && bmiCategory != null && (bmiCategory.name.contains('Obesitas') || bmiCategory.name.contains('Gemuk')) && calories > bmiCategory.defaultCalories) {
       warningList.add({'text': 'Peringatan BMI: Kalori $calories kcal buat kategori ${bmiCategory.name} agak berisiko bikin berat badan stuck atau naik lho. Yakin nih?'});
    } else if (!isCooldownActive && bmiCategory != null && bmiCategory.name.contains('Kurus') && calories < bmiCategory.defaultCalories) {
       warningList.add({'text': 'Untuk kategori BMI ${bmiCategory.name}, meningkatkan asupan kalori ke ${bmiCategory.defaultCalories} kcal dapat membantu mendukung peningkatan berat badan secara sehat.'});
    }

    // --- Sugar ---
    if (sugar < 10) {
      warningList.add({'text': 'Target gula $sugar g cukup rendah. Pastikan asupan nutrisi seimbang untuk mendukung kebutuhan energi otak dan aktivitas harian.'});
    } else if (sugar > 50) {
      warningList.add({'text': 'Target gula $sugar gram udah lewat batas saran WHO lho. Coba dikurangin pelan-pelan ya, biar gula darahmu lebih aman.'});
    } else if (isCooldownActive && previousCategoryParams != null && sugar > previousCategoryParams.defaultSugar) {
      warningList.add({'text': 'Selama fase stabilisasi, disaranin target gulanya maksimal ${previousCategoryParams.defaultSugar}g aja. Jaga asupan gula penting banget biar tubuhmu gampang adaptasi sama berat badan baru.'});
    } else if (!isCooldownActive && bmiCategory != null && (bmiCategory.name.contains('Obesitas') || bmiCategory.name.contains('Gemuk')) && sugar > bmiCategory.defaultSugar) {
       warningList.add({'text': 'Walaupun target gula $sugar gram masih dalam batas aman, untuk kategori ${bmiCategory.name}, ngurangin gula lebih jauh bisa cepetin progres kesehatanmu lho.'});
    }

    // --- Water ---
    if (water < 1500) {
       warningList.add({'text': 'Target air ${(water/1000).toStringAsFixed(1)} L masih kurang buat hidrasi harian. Perbanyak minum ya biar ginjal sehat dan metabolisme makin lancar.'});
    } else if (water > 5000) {
       warningList.add({'text': 'Target air ${(water/1000).toStringAsFixed(1)} L itu kebanyakan banget. Minum terlalu banyak malah bikin cairan tubuh nggak seimbang (hiponatremia) lho.'});
    } else if (isCooldownActive && previousCategoryParams != null && water < previousCategoryParams.defaultWater) {
       warningList.add({'text': 'Di fase stabilisasi ini, usahain minum air minimal ${previousCategoryParams.defaultWater} ml ya. Ini ngebantu banget ngebuang sisa racun dan lancarin metabolisme.'});
    } else if (!isCooldownActive && bmiCategory != null && (bmiCategory.name.contains('Obesitas') || bmiCategory.name.contains('Gemuk')) && water < bmiCategory.defaultWater) {
       warningList.add({'text': 'Hidrasi yang cukup (minimal ${bmiCategory.defaultWater} ml) sangat membantu dalam mendukung metabolisme tubuh pada kategori ${bmiCategory.name}.'});
    }

    // --- Burn Calories ---
    if (burn < 100) {
       warningList.add({'text': 'Target bakar $burn Kkal kayaknya agak kerendahan. Coba tambah gerak dikit lagi ya, biar badanmu makin bugar.'});
    } else if (burn > 2000) {
       warningList.add({'text': 'Target bakar $burn Kkal per hari lumayan ekstrem nih. Inget buat selalu jaga asupan nutrisi dan istirahat yang cukup biar nggak drop.'});
    } else if (isCooldownActive && previousCategoryParams != null && !previousCategoryParams.name.contains('Kurus') && burn < previousCategoryParams.defaultBurn) {
       warningList.add({'text': 'Biar otot tetap kencang dan stabil, cobain deh bakar minimal ${previousCategoryParams.defaultBurn} Kkal sehari selama fase ini.'});
    } else if (isCooldownActive && previousCategoryParams != null && previousCategoryParams.name.contains('Kurus') && burn > previousCategoryParams.defaultBurn) {
       warningList.add({'text': 'Selama fase stabilisasi, disarankan menjaga intensitas aktivitas tidak melebihi ${previousCategoryParams.defaultBurn} Kkal agar berat badan tetap terjaga stabil.'});
    } else if (!isCooldownActive && bmiCategory != null && burn < bmiCategory.defaultBurn) {
       warningList.add({'text': 'Peringatan BMI: Buat kategori ${bmiCategory.name}, bakar $burn Kkal itu masih kurang loh. Sistem nyaranin minimal ${bmiCategory.defaultBurn} Kkal biar hasilnya maksimal. Ayo semangat gerak!'});
    } else if (!isCooldownActive && bmiCategory != null && bmiCategory.name.contains('Obesitas') && burn >= 800) {
       warningList.add({'text': 'Peringatan BMI: Kategori ${bmiCategory.name} bahaya lho kalo maksain bakar $burn Kkal per hari. Sendi lutut dan jantung bisa kaget. Mulai dari yang ringan dulu aja ya!'});
    } else if (!isCooldownActive && bmiCategory != null && bmiCategory.name.contains('Kurus') && burn > bmiCategory.defaultBurn) {
       warningList.add({'text': 'Peringatan BMI: Kategori ${bmiCategory.name} jangan terlalu banyak bakar kalori dulu. Bakar $burn Kkal bisa bikin tubuhmu makin defisit dan susah naik berat badan. Disarankan maksimal ${bmiCategory.defaultBurn} Kkal aja buat sekarang.'});
    }

    bool proceed = true;

    if (warningList.isNotEmpty) {
      // Build combined message text for the old logic to parse (hack for existing parser)
      String warningsString = 'Ada beberapa catatan nih buat targetmu:\n\n';
      for (var w in warningList) {
        warningsString += '• ${w['text']}\n';
      }
      
      String? customFooter;
      String? cooldownIntroMessage;
      
      if (isCooldownActive && previousCategoryParams != null) {
        String userName = userData?['name'] ?? userData?['fullName'] ?? userData?['email']?.split('@')[0] ?? 'Sobat ScanSek';
        customFooter = 'Sabar ya, setelah fase selesai kamu bisa kok ikut target ke BMI ${bmiCategory?.name ?? "Normal"}. Intinya ScanSek cuma ingetin kamu dan awasin kamu biar tetep sehat. Semangat yaa!!';
        cooldownIntroMessage = 'Hai $userName, kamu memang udah ada di BMI ${bmiCategory?.name ?? "Normal"}, tapi kamu masih dalam fase stabilitas. Jadi target kamu selama $cooldownDaysLeft hari ke depan masih di target BMI ${previousCategoryParams.name} :';
      }
      
      proceed = await _showWHOWarningDialog(
        'Review Target Keseimbangan',
        warningsString,
        customFooter: customFooter,
        isCooldown: isCooldownActive,
        cooldownIntroMessage: cooldownIntroMessage,
      );
      if (!proceed) return;
    }

    // Save to backend
    await _saveGoalsToBackend(sugar, calories, water, burn);
  }

  /// Show WHO warning dialog with beautiful card design (Carousel)
  Future<bool> _showWHOWarningDialog(String title, String message, {String? customFooter, bool isCooldown = false, String? cooldownIntroMessage}) async {
    // Parse the message to extract warnings
    final lines = message.split('\n');
    List<Map<String, dynamic>> warnings = [];
    String footerText = customFooter ?? 'Intinya sistem ScanSek cuma ngingetin biar proporsional. Yakin nih mau pasang target segini?';
    bool inWarnings = false;
    
    for (var line in lines) {
      if (line.trim().startsWith('•')) {
        inWarnings = true;
        final text = line.trim().substring(1).trim();
        
        IconData icon;
        Color color;
        String slideTitle;
        final lowerText = text.toLowerCase();
        if (lowerText.contains('gula') || lowerText.contains('sugar')) {
          icon = Icons.cookie_outlined;
          color = const Color(0xFFEF5350);
          slideTitle = 'Target Gula';
        } else if ((lowerText.contains('kalori') || lowerText.contains('kcal') || lowerText.contains('kkal')) && !lowerText.contains('bakar') && !lowerText.contains('burn')) {
          icon = Icons.local_fire_department;
          color = const Color(0xFFFF9800);
          slideTitle = 'Target Kalori Masuk';
        } else if (lowerText.contains('bakar') || lowerText.contains('burn')) {
          icon = Icons.whatshot;
          color = const Color(0xFFE53935);
          slideTitle = 'Target Kalori Terbakar';
        } else if (lowerText.contains('air') || lowerText.contains('minum') || lowerText.contains('hidrasi') || lowerText.contains('water') || lowerText.contains('ml')) {
          icon = Icons.water_drop;
          color = const Color(0xFF42A5F5);
          slideTitle = 'Target Air';
        } else {
          icon = Icons.warning_amber_rounded;
          color = const Color(0xFFFF9800);
          slideTitle = 'Peringatan';
        }
        
        warnings.add({'text': text, 'icon': icon, 'color': color, 'title': slideTitle});
      }
    }
    
    final RxInt currentIndex = 0.obs;
    final PageController pageController = PageController();

    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            // Header (Centered Column)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFFF9800),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tolong Baca Dulu yaa',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (isCooldown && cooldownIntroMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  cooldownIntroMessage,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.5,
                    color: Color(0xFF334155),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // Carousel
            SizedBox(
              height: 200, // Fixed height for carousel items
              width: double.maxFinite,
              child: PageView.builder(
                controller: pageController,
                onPageChanged: (index) {
                  currentIndex.value = index;
                },
                itemCount: warnings.length,
                itemBuilder: (context, index) {
                  final warning = warnings[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: warning['color'].withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: warning['color'].withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              warning['icon'],
                              color: warning['color'],
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                warning['title'],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: warning['color'],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              warning['text'],
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Dots Indicator
            if (warnings.length > 1)
              Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(warnings.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: currentIndex.value == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: currentIndex.value == index 
                          ? warnings[index]['color'] 
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              )),
            
            const SizedBox(height: 24),
            
            // Footer message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                footerText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
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
                      backgroundColor: const Color(0xFFEF5350), // Match error snackbar red
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Gajadi deh',
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
                      backgroundColor: const Color(0xFF80CBC4), // Match success snackbar teal
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isCooldown ? 'Ngeyel ganti' : 'Simpan aja',
                      style: const TextStyle(
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

  /// Save goals to backend
  Future<void> _saveGoalsToBackend(
    double sugar,
    double calories,
    int water,
    double burn,
  ) async {
    isSaving.value = true;

    try {
      final response = await _apiClient.put(
        ApiEndpoints.updateGoals,
        data: {
          'dailySugarGoal': sugar,
          'dailyCalorieGoal': calories,
          'dailyWaterGoal': water,
          'dailyBurnGoal': burn,
        },
      );

      if (response.statusCode == 200) {
        // Update local storage
        final userData = await _storage.getUserData() ?? {};
        userData['goals'] = {
          'sugar': sugar,
          'calories': calories,
          'water': water,
          'burn': burn,
        };
        await _storage.saveUserData(userData);

        // Create success message
        final message = response.data['message'] ?? 'Mantap! Target udah kesimpan';
        ElegantSnackbar.success(Get.context, message);

        // Refresh Dashboard Data if controller is alive
        if (Get.isRegistered<DashboardController>()) {
          final dashboardController = Get.find<DashboardController>();
          dashboardController.fetchDashboardData();
        }

        // Go back to dashboard
        Get.back();
      }
    } on NetworkException catch (e) {
      ElegantSnackbar.error(Get.context, e.message);
    } catch (e) {
      ElegantSnackbar.error(Get.context, 'Waduh, ada error nih. Coba lagi ya');
    } finally {
      isSaving.value = false;
    }
  }
  /// Helper to format values (remove .0 if integer)
  String _formatValue(dynamic value) {
    if (value == null) return '0';
    if (value is int) return value.toString();
    if (value is double) {
      if (value % 1 == 0) {
        return value.toInt().toString();
      }
      return value.toString();
    }
    // Try parsing string
    if (value is String) {
      if (value.contains('.')) {
        double? d = double.tryParse(value);
        if (d != null && d % 1 == 0) return d.toInt().toString();
      }
    }
    return value.toString();
  }
}
