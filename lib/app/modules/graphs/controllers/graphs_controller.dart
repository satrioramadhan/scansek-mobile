import 'package:get/get.dart';
import 'package:scansek/app/widgets/states/error_state.dart';
import 'package:scansek/app/data/providers/api/api_client.dart';
import 'package:scansek/app/data/providers/api/api_endpoints.dart';
import 'package:scansek/app/data/providers/api/network_exception.dart';
import 'package:flutter/material.dart';
import 'package:scansek/app/data/providers/local/storage_service.dart';
import 'package:scansek/app/widgets/snackbars/snackbar_designs.dart';

class GraphsController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();

  // --- Goals Variables ---
  final RxDouble dailySugarGoal = 50.0.obs;
  final RxDouble dailyCalorieGoal = 2000.0.obs;
  final RxInt dailyWaterGoal = 2000.obs;
  final RxDouble dailyBurnGoal = 400.0.obs; // Kalori terbakar target

  // --- Observable States ---
  final RxList<Map<String, dynamic>> weeklyData = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt currentTab = 0.obs; // 0: Sugar, 1: Calories, 2: Water, 3: Steps, 4: All
  final RxInt selectedRadarDayIndex = (-1).obs;

  // Date range
  final Rx<DateTime> startDate = DateTime.now().subtract(const Duration(days: 6)).obs;
  final Rx<DateTime> endDate = DateTime.now().obs;

  final List<String> tabTitles = [
    'Gula',
    'Kalori',
    'Air',
    'Aktivitas',
  ];

  @override
  void onInit() {
    super.onInit();
    _loadUserGoals();
    fetchStats();
  }

  /// Load goals from local storage
  Future<void> _loadUserGoals() async {
    try {
      final StorageService storage = Get.find<StorageService>();
      final userData = await storage.getUserData();
      
      if (userData != null && userData['goals'] != null) {
        final goals = userData['goals'];
        // Fix: Use correct keys from UserModel (dailySugarGoal, etc)
        dailySugarGoal.value = double.tryParse(goals['dailySugarGoal']?.toString() ?? goals['sugar']?.toString() ?? '50') ?? 50.0;
        dailyCalorieGoal.value = double.tryParse(goals['dailyCalorieGoal']?.toString() ?? goals['calories']?.toString() ?? '2000') ?? 2000.0;
        dailyWaterGoal.value = (double.tryParse(goals['dailyWaterGoal']?.toString() ?? goals['water']?.toString() ?? '2000') ?? 2000).toInt();
        dailyBurnGoal.value = double.tryParse(goals['dailyBurnGoal']?.toString() ?? goals['burn']?.toString() ?? '400') ?? 400.0;
      }
    } catch (e) {
      print('Error loading goals for graphs: $e');
    }
  }

  /// Fetch stats based on date range
  Future<void> fetchStats() async {
    isLoading.value = true;
    await _loadUserGoals(); // Reload goals to ensure accuracy if user changed them
    try {
      final start = startDate.value;
      final end = endDate.value;
      
      final startStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
      final endStr = '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';

      // Backend now supports custom range on verify/updated endpoint
      final response = await _apiClient.get(
        '${ApiEndpoints.getWeeklyStats}?startDate=$startStr&endDate=$endStr',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        
        if (data != null && data is List) {
          weeklyData.value = List<Map<String, dynamic>>.from(
            data.map((day) => Map<String, dynamic>.from(day)),
          );
        } else {
          weeklyData.value = [];
        }
      }
    } on NetworkException catch (e) {
      if (weeklyData.isEmpty) {
        ErrorSnackbar.show(Get.context!, e.message);
      }
      print('Network error fetching stats: ${e.message}');
    } catch (e) {
      print('Error fetching stats: $e');
      weeklyData.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  /// Select custom date range logic (Dialog Style - Compact & Sweet & Loop Validation)
  Future<void> selectDateRange(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime firstDate = DateTime(2024, 1, 1);
    
    // Track current selection for re-opening
    DateTimeRange? currentRange = DateTimeRange(start: startDate.value, end: endDate.value);
    bool isValid = false;

    // Loop to keep dialog "open" (re-open) if validation fails
    while (!isValid) {
      final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        firstDate: firstDate,
        lastDate: now,
        initialDateRange: currentRange, // Use persisted range
        helpText: 'Pilih Rentang', // Short & Simple
        saveText: 'SIMPAN',
        confirmText: 'SIMPAN',
        cancelText: 'BATAL',
        builder: (context, child) {
          return Center(
            child: ConstrainedBox(
              // Compact Size: Smaller height/width to look "Sweet & Floating"
              constraints: const BoxConstraints(maxWidth: 330, maxHeight: 500), 
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF009688), // Tosca
                    onPrimary: Colors.white,
                    surface: Color(0xFFFAFAFA), // Off-white
                    onSurface: Color(0xFF004D40), // Dark Teal text
                    secondary: Color(0xFF009688),
                    secondaryContainer: Color(0xFFE0F2F1), // Soft Tosca Range
                  ),
                  dialogTheme: DialogTheme(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24), // Sweet rounding
                    ),
                    elevation: 12,
                  ),
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF009688),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                  datePickerTheme: const DatePickerThemeData(
                    headerBackgroundColor: Color(0xFF009688),
                    headerForegroundColor: Colors.white,
                    headerHeadlineStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), // Compact Header
                    headerHelpStyle: TextStyle(fontSize: 12, color: Colors.white70),
                    dayStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    rangeSelectionBackgroundColor: Color(0xFFE0F2F1),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: child!,
                ),
              ),
            ),
          );
        },
      );

      if (picked == null) {
        // User cancelled explicitly
        break;
      }

      final difference = picked.end.difference(picked.start).inDays;
      
      // Min 4 days (diff >= 3), Max 7 days (diff <= 6)
      if (difference < 3 || difference > 6) {
        // INVALID: Show snackbar
        ElegantSnackbar.warning(
          context,
          'Pilih rentang antara 4 sampai 7 hari ya!',
        );
        // Update currentRange so re-open shows user's invalid selection (easier to fix)
        currentRange = picked;
        // Loop continues -> Re-opens dialog immediately
      } else {
        // VALID: Save and fetch
        startDate.value = picked.start;
        endDate.value = picked.end;
        isValid = true; // Break loop
        fetchStats();
      }
    }
  }

  /// Change current tab
  void changeTab(int index) {
    currentTab.value = index;
  }
  
  // --- Colors helper ---
  Color getCategoryColor(int index) {
    switch (index) {
      case 0: return const Color(0xFFEF9A9A); // Sugar (Red 200) - Lighter
      case 1: return const Color(0xFFFFCC80); // Calories (Orange 500) - Stronger
      case 2: return const Color(0xFF90CAF9); // Water (Blue 500) - Stronger
      case 3: return const Color(0xFF81C784); // Activity Green (Requested)
      default: return const Color(0xFF80CBC4);
    }
  }

  // --- Getters for Chart ---
  List<double> get sugarData => _getData('sugar');
  List<double> get caloriesData => _getData('calories');
  List<double> get waterData => _getData('water');
  List<double> get burnData => _getData('activities');

  List<double> _getData(String key) {
    if (weeklyData.isEmpty) return [];
    return weeklyData.map((d) => (d[key] ?? 0).toDouble()).toList().cast<double>();
  }

  List<String> get dateLabels {
    if (weeklyData.isEmpty) return [];
    return weeklyData.map((day) {
      final date = DateTime.parse(day['date']);
      return '${date.day}/${date.month}';
    }).toList();
  }
  
  // normalized date for Combined Chart (0-100%)
  List<double> getNormalizedData(int tabIndex) {
    List<double> rawData;
    double target;
    
    // Use the daily goal for normalization reference (approximate for graph scaling)
    // Or should we use the Total Goal?
    // Since the graph likely shows DAILY values (sugarData is list of dailies),
    // we should normalize against DAILY GOAL, not Period Goal.
    
    switch (tabIndex) {
      case 0: rawData = sugarData; target = dailySugarGoal.value; break;
      case 1: rawData = caloriesData; target = dailyCalorieGoal.value; break;
      case 2: rawData = waterData; target = dailyWaterGoal.value.toDouble(); break;
      case 3: rawData = burnData; target = dailyBurnGoal.value; break;
      default: return [];
    }
    
    return rawData.map((val) {
      double percent = target > 0 ? (val / target) * 100 : 0.0;
      // Batasi max visual grafik mentok di 100% agar pas dengan grid merah luar
      // (Biar garisnya nggak keluar/jebol dari jaring)
      if (percent > 100.0) percent = 100.0;
      return percent;
    }).toList();
  }
  
  // --- Goals Getter ---
  // Returns the PERIOD GOAL (Daily * Goal) for the current date range
  double getGoal(int tabIndex) {
    // Calculate days count
    int daysCount = endDate.value.difference(startDate.value).inDays + 1;
    if (daysCount < 1) daysCount = 1;

    switch (tabIndex) {
      case 0: return dailySugarGoal.value * daysCount; // Total Sugar for period
      case 1: return dailyCalorieGoal.value * daysCount; // Total Calories for period
      case 2: return dailyWaterGoal.value.toDouble() * daysCount; // Total Water for period
      case 3: return dailyBurnGoal.value * daysCount; // Total Burn for period
      default: return 100.0;
    }
  }

  // Returns the DAILY GOAL for the chart line
  double getDailyGoal(int tabIndex) {
    switch (tabIndex) {
      case 0: return dailySugarGoal.value;
      case 1: return dailyCalorieGoal.value;
      case 2: return dailyWaterGoal.value.toDouble();
      case 3: return dailyBurnGoal.value;
      default: return 100.0;
    }
  }

  // --- Analytics ---
  double getAverage(List<double> data) {
    // Filter out 0s for average calculation if we assume 0 means "no data logged that day"
    // But since it's a daily chart, 0 might mean 0 consumed. We'll use strict average.
    if (data.isEmpty) return 0;
    final total = data.reduce((a, b) => a + b);
    return total / data.length;
  }

  double getTotal(List<double> data) {
    if (data.isEmpty) return 0;
    return data.reduce((a, b) => a + b);
  }

  Map<String, dynamic> getStatus(int tabIndex) {
    List<double> currentData = [];
    
    // Load data based on tab
    switch (tabIndex) {
      case 0: currentData = sugarData; break;
      case 1: currentData = caloriesData; break;
      case 2: currentData = waterData; break;
      case 3: currentData = burnData; break;
    }
    
    if (currentData.isEmpty) {
      return {
        'status': 'Belum Ada Data',
        'statusColor': Colors.grey,
        'message': 'Belum ada data yang tercatat.',
        'average': 0.0,
        'total': 0.0,
        'impact': 'Catat harianmu yuk biar grafiknya muncul.',
      };
    }

    double averageValue = getAverage(currentData);
    double totalValue = getTotal(currentData);
    final dailyGoal = getDailyGoal(tabIndex);
    
    String status = 'Normal';
    Color statusColor = Colors.green;
    String message = '';
    String? impact;

    // Use averages instead of totals to prevent "Kurang" errors when user only logs 1 day in a 7 day period!
    switch (tabIndex) {
      case 0: // Sugar
        double whoLimit = 50.0;
        if (averageValue > whoLimit) {
          status = 'Berlebih';
          statusColor = Colors.red;
          message = 'Rata-rata konsumsi gulamu mencapai ${averageValue.toStringAsFixed(0)}g/hari. Ini melebihi batas aman targetmu (${dailyGoal.toStringAsFixed(0)}g) dan batas WHO (${whoLimit.toStringAsFixed(0)}g).';
          impact = 'Dampak: Gula berlebih yang tidak dibakar akan langsung diubah menjadi lemak visceral (lemak perut). Awas, penumpukan lemak bikin BMI cepat melesat ke arah Obesitas dan memicu DIABETES Tipe 2 yang mematikan!';
        } else if (averageValue > dailyGoal) {
           status = 'Waspada';
           statusColor = Colors.orange;
           message = 'Rata-rata konsumsi gulamu ${averageValue.toStringAsFixed(0)}g/hari. Sedikit melewati batas harianmu (${dailyGoal.toStringAsFixed(0)}g), walau masih di bawah batas WHO (${whoLimit.toStringAsFixed(0)}g).';
           impact = 'Tips: Coba kurangi sedikit lagi makanan manisnya. Jangan sampai resistensi insulin diam-diam merusak pankreasmu mulai dari sekarang.';
        } else if (averageValue < 2.0) {
           status = 'Sangat Rendah';
           statusColor = Colors.orange;
           message = 'Rata-rata konsumsi gulamu nyaris 0g lho. Mengurangi gula itu bagus, tapi pastikan kamu tetap makan karbohidrat kompleks ya.';
           impact = 'Tips: Gula tambahan memang jahat, tapi karbohidrat kompleks tetap butuh buat energi otot. Jangan sampai tubuhmu membakar otot gara-gara lemas, nanti bisa jadi Skinny Fat (kurus tapi berlemak) yang rawan gagal organ.';
        } else {
          status = 'Aman';
          statusColor = Colors.green;
          message = 'Bagus banget! Rata-rata konsumsi gulamu cuma ${averageValue.toStringAsFixed(0)}g/hari. Aman terkontrol di bawah target harian (${dailyGoal.toStringAsFixed(0)}g).';
        }
        break;
        
      case 1: // Calories
        double stdLimit = 2500.0;
        if (averageValue > stdLimit || averageValue > dailyGoal * 1.1) {
           status = 'Berlebih';
           statusColor = Colors.red;
           message = 'Rata-rata asupan kalorimu mencapai ${averageValue.toStringAsFixed(0)} kcal/hari. Ini lumayan di atas target harian kamu (${dailyGoal.toStringAsFixed(0)} kcal).';
           impact = 'Dampak: Surplus kalori yang terus-menerus akan ditimbun sebagai lemak tubuh. Jika dibiarkan, BMI kamu bergeser menjadi Obesitas yang memicu SERANGAN JANTUNG dan STROKE mendadak.';
        } else if (averageValue < dailyGoal * 0.4) {
           status = 'Sangat Kurang';
           statusColor = Colors.red;
           message = 'Rata-rata asupan kalorimu anjlok di ${averageValue.toStringAsFixed(0)} kcal/hari. Ini sangat defisit dari target wajarmu (${dailyGoal.toStringAsFixed(0)} kcal).';
           impact = 'Dampak: Hati-hati! Defisit kalori ekstrem bikin tubuh panik dan malah menyusutkan massa otot, BUKAN lemak. Memicu Skinny Fat berbahaya yang bikin imun hancur dan rentan infeksi parah!';
        } else if (averageValue < dailyGoal * 0.7) {
           status = 'Kurang';
           statusColor = Colors.orange;
           message = 'Rata-rata asupan kalorimu cuma ${averageValue.toStringAsFixed(0)} kcal/hari. Kelihatannya agak defisit dari target wajarmu (${dailyGoal.toStringAsFixed(0)} kcal).';
           impact = 'Tips: Kurang makan nggak bikin kurus sehat, malah bikin tubuh menggerogoti massa otot. Jaga keseimbangan gizi biar metabolisme nggak rusak.';
        } else {
           status = 'Ideal';
           statusColor = Colors.green;
           message = 'Mantap! Rata-rata asupan kalorimu ${averageValue.toStringAsFixed(0)} kcal/hari. Target ${dailyGoal.toStringAsFixed(0)} kcal terpenuhi dengan ideal.';
        }
        break;
        
      case 2: // Water
        double overhydrationLimit = 4000.0;
        if (averageValue < dailyGoal) { 
           status = 'Kurang';
           statusColor = Colors.red;
           message = 'Duh, rata-rata kamu cuma minum ${averageValue.toStringAsFixed(0)} ml/hari. Sayang banget belum mencapai targetmu (${dailyGoal.toStringAsFixed(0)} ml).';
           impact = 'Dampak: Dehidrasi kronis memperlambat metabolisme pembakaran lemak. Usaha jaga BMI idaman bakal batal total, ditambah risiko GAGAL GINJAL dan BATU GINJAL berdarah yang sangat menyakitkan!';
        } else if (averageValue > overhydrationLimit) {
           status = 'Berlebih Ekstrem';
           statusColor = Colors.orange;
           message = 'Wah, kamu minum banyak banget sampai rata-rata ${averageValue.toStringAsFixed(0)} ml/hari! Udah luar biasa banget hausnya wkwk.';
           impact = 'Dampak: Hati-hati hiponatremia (keracunan air). Bikin sel otak bengkak dan ginjal bocor mendadak karena kelebihan beban secara instan.';
        } else {
           status = 'Bagus';
           statusColor = Colors.green;
           message = 'Keren! Hidrasi tubuhmu sukses terpenuhi dengan baik dengan rata-rata ${averageValue.toStringAsFixed(0)} ml/hari.';
        }
        break;
        
      case 3: // Kalori Terbakar
        if (averageValue < dailyGoal * 0.5) { 
           status = 'Kurang Gerak';
           statusColor = Colors.red;
           message = 'Rata-rata kalori terbakarmu baru ${averageValue.toStringAsFixed(0)} kcal/hari. Masih jauh dari target (${dailyGoal.toStringAsFixed(0)} kcal). Lagi mager ya?';
           impact = 'Dampak: Kurang gerak menyebabkan penumpukan lemak visceral. Meskipun berat badanmu normal, kamu bisa mengalami Skinny Fat yang diam-diam menyumbat pembuluh darah jantung (PENYAKIT KARDIOVASKULAR MEMATIKAN)!';
        } else if (averageValue > dailyGoal * 1.5) {
           status = 'Sangat Aktif';
           statusColor = Colors.green;
           message = 'Luar biasa! Rata-rata kamu bakar ${averageValue.toStringAsFixed(0)} kcal/hari, melampaui jauh target (${dailyGoal.toStringAsFixed(0)} kcal).';
           impact = 'Dampak: Keren! Pembakaran kalori tinggi bikin massa otot naik dan membakar lemak sisa. Persentase BMI kamu jadi makin solid dan anti-penyakit.';
        } else if (averageValue < dailyGoal) {
           status = 'Lumayan';
           statusColor = Colors.orange;
           message = 'Rata-rata kamu sudah bakar ${averageValue.toStringAsFixed(0)} kcal/hari. Sedikit lagi nyampe target (${dailyGoal.toStringAsFixed(0)} kcal).';
        } else {
           status = 'Aktif';
           statusColor = Colors.green;
           message = 'Hebat! Pembakaran kalorimu konsisten rata-rata ${averageValue.toStringAsFixed(0)} kcal/hari, sejalan sama target aktivitasmu.';
        }
        break;
    }

    return {
      'status': status,
      'statusColor': statusColor,
      'message': message,
      'average': averageValue,
      'total': totalValue,
      'impact': impact,
    };
  }

  Map<String, dynamic> getDailyCombinedStatus(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= dateLabels.length) {
      return getCombinedStatus();
    }

    final dateLabel = dateLabels[dayIndex];
    final sugar = sugarData.isNotEmpty && dayIndex < sugarData.length ? sugarData[dayIndex] : 0.0;
    final cal = caloriesData.isNotEmpty && dayIndex < caloriesData.length ? caloriesData[dayIndex] : 0.0;
    final water = waterData.isNotEmpty && dayIndex < waterData.length ? waterData[dayIndex] : 0.0;
    final burn = burnData.isNotEmpty && dayIndex < burnData.length ? burnData[dayIndex] : 0.0;

    if (sugar == 0 && cal == 0 && water == 0 && burn == 0) {
      return {
        'status': 'Kosong',
        'statusColor': Colors.grey,
        'message': 'Belum ada data di tanggal $dateLabel.',
        'impact': 'Yukk, mulai catat konsumsinya, air minumnya dan aktivitasmu yaa. jangan malas!',
      };
    }

    final double sugarGoal = dailySugarGoal.value;
    final double calGoal = dailyCalorieGoal.value;
    final double waterGoal = dailyWaterGoal.value.toDouble();
    final double burnGoal = dailyBurnGoal.value;

    // Batas minimum sesuai pedoman kesehatan dasar (Kemenkes/WHO)
    final double minSugar = 15.0; // Minimal glukosa alami harian untuk otak
    final double minCal = 1200.0; // Batas minimal BMR (jangan diet terlalu ekstrem)
    final double minWater = 1500.0; // Minimal standar hidrasi harian untuk mencegah dehidrasi
    final double minBurn = 150.0; // Minimal aktivitas ringan-sedang per hari

    bool sugarOk = sugar >= minSugar && sugar <= sugarGoal;
    bool calOk = cal >= minCal && cal <= calGoal * 1.1; // Kasih toleransi lebih 10%
    bool waterOk = water >= minWater;
    bool burnOk = burn >= minBurn;

    List<String> good = [];
    List<String> bad = [];

    if (sugarOk) good.add('Gula'); else bad.add(sugar < minSugar ? 'Gula sangat kurang' : 'Gula berlebih');
    if (calOk) good.add('Kalori'); else bad.add(cal < minCal ? 'Kalori defisit ekstrem' : 'Kalori berlebih');
    if (waterOk) good.add('Air'); else bad.add('Kurang minum');
    if (burnOk) good.add('Aktivitas'); else bad.add('Kurang gerak');

    String message = 'Tanggal $dateLabel:\n';
    String status = '';
    Color statusColor = Colors.green;
    String impact = '';

    if (bad.isEmpty) {
      status = 'Sempurna';
      statusColor = Colors.green;
      message += 'Luar biasa! Gula, Kalori, Air, dan Aktivitasmu semua mencapai target dengan seimbang. KDA PUBG abiezz! Pertahankan terus!';
    } else if (good.isEmpty) {
      status = 'Perlu Perbaikan';
      statusColor = Colors.red;
      message += 'Aduh, sepertinya hari ini kacau banget. Semua metrikmu hancur dan belum mencapai target harian.';
      impact = 'Tips: Jangan main-main sama tubuh sendiri! Mulai dari perbanyak minum air, rem gula biar nggak kena Diabetes, dan gerak 15 menit biar nggak numpuk jadi Lemak Visceral jahat.';
    } else {
      status = 'Campur';
      statusColor = Colors.orange;
      message += '${good.join(' dan ')} kamu sudah baik dan terkontrol, tapi sayangnya ${bad.join(', ')}.';
      
      List<String> impacts = [];
      if (!waterOk) impacts.add('dehidrasi bikin darah mengental, memicu gagal ginjal mematikan');
      if (!burnOk) impacts.add('kurang gerak numpuk lemak visceral yang rawan bikin serangan jantung mendadak');
      if (sugar > sugarGoal) impacts.add('gula berlebih merusak pankreas, siap-siap vonis Diabetes Tipe 2 seumur hidup');
      if (sugar < minSugar) impacts.add('kurang glukosa alami bikin tubuh kanibal membakar massa otot sendiri (Skinny Fat parah)');
      if (cal > calGoal * 1.1) impacts.add('surplus kalori langsung memicu obesitas tingkat lanjut');
      if (cal < minCal) impacts.add('kalori ekstrem merusak tiroid, menghentikan laju metabolisme, dan imun hancur total');
      
      if (impacts.isNotEmpty) {
        impact = 'Ancaman Medis:\n• ${impacts.join('\n• ')}';
      }
    }

    return {
      'status': status,
      'statusColor': statusColor,
      'message': message,
      'impact': impact.isNotEmpty ? impact : null,
    };
  }

  Map<String, dynamic> getCombinedStatus() {
    if (caloriesData.isEmpty && burnData.isEmpty && sugarData.isEmpty) {
      return {
        'status': 'Belum Ada Data',
        'statusColor': Colors.grey,
        'message': 'Belum ada data yang tercatat di rentang waktu ini.',
        'impact': 'Mulai catat makanan dan aktivitasmu ya!',
      };
    }

    double avgCalories = getAverage(caloriesData);
    double avgBurn = getAverage(burnData);
    double avgSugar = getAverage(sugarData);
    double avgWater = getAverage(waterData);
    
    double calGoal = dailyCalorieGoal.value;
    double burnGoal = dailyBurnGoal.value;
    double sugarGoal = dailySugarGoal.value;
    double waterGoal = dailyWaterGoal.value.toDouble();

    // Rule 0: Everything is critically low (Not Logging or Extreme Fasting)
    if (avgCalories < 300 && avgWater < 500 && avgBurn < 50) {
      return {
        'status': 'Mulai Catat Yuk!',
        'statusColor': Colors.blue,
        'message': 'Grafikmu nyaris 0 semua nih. Kamu lagi puasa ekstrem atau lupa nyatet di aplikasi?',
        'impact': 'Tips: Sempatkan waktu 1 menit sehari buat update data makanan manual dan hasil scan, biar ScanSek bisa ngasih insight yang akurat buat kamu.',
      };
    }

    // Minimum based on WHO / Ministry of Health guidelines
    final double minSugar = 15.0; // Minimal glukosa alami harian
    final double minCal = 1200.0; // Batas minimal BMR
    final double minWater = 1500.0; // Minimal hidrasi harian
    final double minBurn = 150.0; // Minimal aktivitas fisik ringan

    // Evaluate individual metrics
    List<String> berlebih = [];
    List<String> kurang = []; 
    List<String> ideal = []; 

    // Sugar
    if (avgSugar > sugarGoal) berlebih.add('Gula');
    else if (avgSugar < minSugar) kurang.add('Gula (Ekstrem)');
    else ideal.add('Gula');

    // Calories
    if (avgCalories > calGoal * 1.1) berlebih.add('Kalori');
    else if (avgCalories < minCal) kurang.add('Kalori (Defisit ekstrem)');
    else ideal.add('Kalori');

    // Water
    if (avgWater > 4000.0) berlebih.add('Air (Overhidrasi)');
    else if (avgWater < minWater) kurang.add('Air Minum (Risiko Dehidrasi)');
    else ideal.add('Air Minum');

    // Burn
    if (avgBurn > burnGoal * 1.5) berlebih.add('Aktivitas (Sangat Aktif)');
    else if (avgBurn < minBurn) kurang.add('Aktivitas (Sangat Kurang/Mager)');
    else ideal.add('Aktivitas');

    String status = 'Seimbang';
    Color statusColor = Colors.green;
    String message = '';
    String impact = '';

    if (ideal.length == 4) {
      status = 'Pola Hidup Sempurna';
      statusColor = Colors.green;
      message = 'Luar biasa! Semua target harianmu (Kalori, Gula, Air, Aktivitas) tercapai dengan sangat seimbang. Pertahankan pola hidup idaman ini!';
      impact = 'Keseimbangan nutrisi dan aktivitas bikin rasio otot dan lemak tubuh berada di BMI paling stabil. Tubuh jadi proporsional dan kebal penyakit kronis!';
    } else if (kurang.length >= 3) {
      status = 'Gizi Buruk Tereselubung';
      statusColor = Colors.orange;
      message = 'Grafikmu memang kelihatan seimbang, tapi itu seimbang karena sangat KEKURANGAN target. Kamu defisit parah di bagian: ${kurang.join(", ")}.';
      impact = 'Bahaya: Hati-hati, orang underweight pun bisa kena penyakit kronis kalau tubuh terpaksa membakar otot demi bertahan hidup. Skinny Fat mengintaimu!';
    } else if (berlebih.length >= 3) {
      status = 'Jalan Tol Menuju Obesitas';
      statusColor = Colors.red;
      message = 'Grafikmu menembus batas kewajaran! Kamu memakan racun terlalu banyak di bagian: ${berlebih.join(", ")}. Wah, lagi ngancurin badan sendiri ya?';
      impact = 'Ancaman Keras: Kalau pola ngawur ini diterusin, bersiaplah menghadapi lonjakan BMI ekstrem, Diabetes Tipe 2, dan antrean panjang masuk IGD akibat Stroke / Jantung!';
    } else {
      // Mixed scenario
      status = 'Perlu Penyesuaian';
      if (berlebih.isNotEmpty) {
        statusColor = Colors.orange; 
      } else {
        statusColor = Colors.blue;
      }
      
      message = 'Keseluruhan targetmu hampir bagus, hanya saja perhatikan hal ini ya:\n';
      
      if (berlebih.isNotEmpty) {
        message += '• Yang melebihi batas target harian: ${berlebih.join(", ")}.\n';
      }
      if (kurang.isNotEmpty) {
        message += '• Yang masih kurang dari target harian: ${kurang.join(", ")}.\n';
      }
      if (ideal.isNotEmpty) {
        message += 'Sisanya (${ideal.join(", ")}) udah terkontrol dengan baik!';
      }
      
      impact = 'Fokus benerin yang kurang atau lebih, biar minggu depan grafiknya bisa Sempurna!';
    }

    return {
      'status': status,
      'statusColor': statusColor,
      'message': message,
      'impact': impact,
    };
  }
}
