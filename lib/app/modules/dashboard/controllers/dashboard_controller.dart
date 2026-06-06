import 'package:get/get.dart';
import 'dart:convert';
import 'package:scansek/app/core/utils/helpers.dart';
import 'package:scansek/app/core/utils/bmi_helper.dart';
import 'package:scansek/app/data/models/dashboard_stats_model.dart';
import 'package:scansek/app/data/models/food_model.dart';
import 'package:scansek/app/data/models/water_model.dart';
import 'package:scansek/app/data/providers/api/api_client.dart';
import 'package:scansek/app/data/providers/api/api_endpoints.dart';
import 'package:scansek/app/data/providers/api/network_exception.dart';
import 'package:scansek/app/data/providers/local/storage_service.dart';
import 'package:scansek/app/widgets/states/error_state.dart';
import 'package:scansek/app/widgets/snackbars/snackbar_designs.dart';
import 'package:flutter/material.dart';
import 'package:scansek/app/services/notification_service.dart';

class DashboardController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();
  final StorageService _storage = Get.find<StorageService>();
  
  // Cache key
  static const String _dashboardCacheKey = 'dashboard_stats_cache';
  
  // Track if dialog has been shown this session
  // static bool hasShownDialogThisSession = false; // DEPRECATED: We now use _storage.hasShownBMIDialog to persist across sessions but clear on logout

  // Observable states
  final Rx<DashboardStatsModel?> stats = Rx<DashboardStatsModel?>(null);
  final Rx<FoodModel?> lastFood = Rx<FoodModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString userName = ''.obs;
  final RxBool shouldShowUpdateMetricsBanner = false.obs;
  final RxBool isFastingMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserName();
    _loadStatsFromCache(); // Load cache first for instant UI
    fetchDashboardData();
  }

  @override
  void onReady() {
    super.onReady();
    _requestNotificationPermissions(); // Ask for permissions safely after UI is rendered
  }

  Future<void> _requestNotificationPermissions() async {
    final notificationService = NotificationService();
    await notificationService.requestPermissions();
  }

  /// Refresh user name (called when returning to dashboard)
  Future<void> refreshUserName() async {
    await _loadUserName();
  }

  /// Load user name and metrics check from storage
  Future<void> _loadUserName() async {
    final user = await _storage.getUserData();
    if (user != null) {
      // Try different possible name fields
      userName.value = user['name'] ?? user['fullName'] ?? user['email']?.split('@')[0] ?? 'User';
      
      // Check for weekly body metrics update requirement
      final lastUpdateStr = user['lastBodyMetricsUpdate'] ?? user['createdAt'];
      if (lastUpdateStr != null) {
        final lastUpdate = DateTime.tryParse(lastUpdateStr.toString());
        if (lastUpdate != null) {
          final daysSince = DateTime.now().difference(lastUpdate).inDays;
          shouldShowUpdateMetricsBanner.value = daysSince >= 7;
        } else {
          shouldShowUpdateMetricsBanner.value = false;
        }
      } else {
        shouldShowUpdateMetricsBanner.value = false; // Don't force banner if date is missing
      }
      
      // Load fasting mode state
      isFastingMode.value = _storage.isFastingMode;
      
      // Schedule and setup notifications (always do this to ensure alarms are active)
      await NotificationService().refreshSystemNotifications();
      
      print('User loaded: ${userName.value}, needs update: ${shouldShowUpdateMetricsBanner.value}');
    } else {
      userName.value = 'User';
    }
  }

  /// Get greeting based on time
  String get greeting => Helpers.getGreeting();

  /// Fetch dashboard statistics
  Future<void> fetchDashboardData() async {
    isLoading.value = true;
    try {
      // Silently fetch latest profile to sync lastBodyMetricsUpdate and other user fields
      try {
        final profileResponse = await _apiClient.get('/users/profile');
        if (profileResponse.statusCode == 200) {
          await _storage.saveUserData(profileResponse.data['data']);
        }
      } catch (e) {
        print('Silently fetching profile failed: $e');
      }
      
      await _loadUserName(); // Ensure name is up to date after fetching profile
      isFastingMode.value = _storage.isFastingMode;

      final response = await _apiClient.get(ApiEndpoints.dashboardStats);

      if (response.statusCode == 200) {
        final data = response.data['data'];
        
        // API returns { data: { today: {...}, last7Days: {...} } }
        // We only parse 'today' stats for dashboard cards
        if (data != null && data['today'] != null) {
          final todayData = data['today'];
          
          // OVERRIDE GOAL FROM STORAGE TO ENSURE SYNC (Moved up to prevent 0 flash)
          final user = await _storage.getUserData();
          int currentStepGoal = 0;
          int currentWaterGoal = 0;
          int currentSugarGoal = 0;
          int currentCalorieGoal = 0;
          
          if (user != null && user['goals'] != null) {
             currentStepGoal = (double.tryParse(user['goals']['steps'].toString()) ?? 0).toInt();
             currentWaterGoal = (double.tryParse(user['goals']['water'].toString()) ?? 0).toInt();
             currentSugarGoal = (double.tryParse(user['goals']['sugar'].toString()) ?? 0).toInt();
             currentCalorieGoal = (double.tryParse(user['goals']['calories'].toString()) ?? 0).toInt();
          }

          // Transform API format to DashboardStatsModel format
          // Note: Backend doesn't send 'burned' in calories, it's in activities.caloriesBurned
          final caloriesData = Map<String, dynamic>.from(todayData['calories'] ?? {});
          final Map<String, dynamic> activitiesData = Map<String, dynamic>.from(todayData['activities'] ?? {});
          final sugarData = Map<String, dynamic>.from(todayData['sugar'] ?? {});
          final waterData = Map<String, dynamic>.from(todayData['water'] ?? {});
          
          // INJECT GOALS directly into API data map before parsing
          if (currentStepGoal > 0) { // Keep old logic fallbacks if needed, but we now rely on burn
             activitiesData['goalSteps'] = currentStepGoal;
          }
          final userBurnGoal = (user?['goals']?['burn'] ?? 0).toDouble();
          if (userBurnGoal > 0) {
             activitiesData['goalBurn'] = userBurnGoal;
          }
          
          if (currentWaterGoal > 0) {
             waterData['goal'] = currentWaterGoal;
          }
          if (currentSugarGoal > 0) {
             sugarData['goal'] = currentSugarGoal;
          }
          if (currentCalorieGoal > 0) {
             caloriesData['goal'] = currentCalorieGoal;
          }
          
          // Add burned calories from activities to calories object
          caloriesData['burned'] = activitiesData['caloriesBurned'] ?? 0;
          
          print("🌟 DEBUG DASHBOARD WATER DATA: \$waterData");

          
          final transformedData = {
            'date': DateTime.now().toIso8601String(),
            'calories': caloriesData,
            'sugar': sugarData,
            'water': waterData,
            'activity': activitiesData,
          };
          
          // DEBUG: Print activities data
          stats.value = DashboardStatsModel.fromJson(transformedData);
          
          // Fetch last food separately
          await _fetchTodayFoodStats();
          
          // Fetch last water
          await _fetchLastWater();
          
          // Fetch today's activities for steps data
          await fetchTodayActivities();
          
          // Save valid data to cache
          if (stats.value != null) {
            _saveStatsToCache(stats.value!);
          }
          
          // Save valid data to cache
          if (stats.value != null) {
            _saveStatsToCache(stats.value!);
          }
        } else {
          print('Dashboard data is null or missing today field');
          stats.value = null;
          lastFood.value = null;
        }
      }
    } on NetworkException catch (e) {
      ErrorSnackbar.show(Get.context!, e.message);
    } catch (e) {
      ElegantSnackbar.error(Get.context, 'Waduh, gagal muat data nih');
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch the latest food using history endpoint
  Future<void> _fetchTodayFoodStats() async {
    try {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final response = await _apiClient.get(
        '/food/history?startDate=$dateStr&endDate=$dateStr',
      );
      
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && data['items'] != null && data['items'] is List) {
          final items = data['items'] as List;
          if (items.isNotEmpty) {
            // Get the most recent food
            final foodItems = items.map((json) => FoodModel.fromJson(json)).toList();
            foodItems.sort((a, b) => b.consumptionTime.compareTo(a.consumptionTime));
            lastFood.value = foodItems.first;
          } else {
            lastFood.value = null;
          }
        }
      }
    } catch (e) {
      print('Failed to fetch food history: $e');
      lastFood.value = null;
    }
  }

  /// Add Last Water Logic
  final Rx<WaterModel?> lastWater = Rx<WaterModel?>(null);

  Future<void> _fetchLastWater() async {
    try {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      // Fetch water history for today
      final response = await _apiClient.get(
        '${ApiEndpoints.waterHistory}?startDate=$dateStr&endDate=$dateStr',
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        List waterData = [];

        if (responseData is Map && responseData.containsKey('data')) {
           final dataObj = responseData['data'];
           if (dataObj is Map && dataObj.containsKey('items')) {
             waterData = dataObj['items'] as List;
           } else if (dataObj is List) {
             waterData = dataObj;
           }
        }

        if (waterData.isNotEmpty) {
          final waterItems = waterData.map((json) => WaterModel.fromJson(json)).toList();
          // Sort by intakeTime descending to get latest
          waterItems.sort((a, b) => b.intakeTime.compareTo(a.intakeTime));
          lastWater.value = waterItems.first;
        } else {
          lastWater.value = null;
        }
      }
    } catch (e) {
      print('Failed to fetch water history: $e');
      lastWater.value = null;
    }
  }

  /// Fetch today's activities to get steps breakdown
  Future<void> fetchTodayActivities() async {
    try {
      // Use activity history endpoint with today's date
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final response = await _apiClient.get(
        '/activity/history?startDate=$dateStr&endDate=$dateStr',
      );
      
      if (response.statusCode == 200 && response.data['data'] != null) {
        final data = response.data['data'];
        
        // Parse activities items to get steps and breakdown
        if (data['items'] != null && (data['items'] as List).isNotEmpty) {
          int totalSteps = 0;
          int walkingSteps = 0;
          int joggingSteps = 0;
          
          for (var item in data['items']) {
            final steps = (item['steps'] ?? 0) as int;
            final type = (item['type'] ?? '').toString().toLowerCase();
            
            totalSteps += steps;
            
            if (type == 'walking') {
              walkingSteps += steps;
            } else if (type == 'jogging') {
              joggingSteps += steps;
            }
          }
          
          // Update stats with actual steps data INCLUDING walking/jogging breakdown
          if (stats.value != null) {
            final updatedActivity = ActivityStatsModel(
              duration: stats.value!.activity.duration,
              distance: stats.value!.activity.distance,
              caloriesBurned: stats.value!.activity.caloriesBurned,
              goalBurn: stats.value!.activity.goalBurn,
              steps: totalSteps,
              goalSteps: stats.value!.activity.goalSteps,
              walkingSteps: walkingSteps,
              joggingSteps: joggingSteps,
            );
            
            stats.value = DashboardStatsModel(
              date: stats.value!.date,
              calories: stats.value!.calories,
              sugar: stats.value!.sugar,
              water: stats.value!.water,
              activity: updatedActivity,
              lastFood: stats.value!.lastFood,
            );
            
            print('🏃 Steps updated: total=$totalSteps, walking=$walkingSteps, jogging=$joggingSteps');
          }
        }
      }
    } catch (e) {
      print('Error fetching today activities: $e');
    }
  }

  /// Quick add water
  Future<void> quickAddWater(int amount) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.addWater,
        data: {
          'amount': amount,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final message = response.data['message'] ?? 
                        'Air $amount ml berhasil ditambahkan!';
        SuccessSnackbar.show(Get.context!, message);

        // Refresh dashboard
        await fetchDashboardData();
        
        // Simpan timestamp & refresh notif
        await _storage.setLastWaterInputTime(DateTime.now());
        await NotificationService().refreshSystemNotifications();
      }
    } on NetworkException catch (e) {
      ErrorSnackbar.show(Get.context!, e.message);
    } catch (e) {
      ElegantSnackbar.error(Get.context, 'Waduh, ada error');
    }
  }

  /// Save stats to cache
  Future<void> _saveStatsToCache(DashboardStatsModel data) async {
    try {
      final jsonString = jsonEncode(data.toJson());
      await _storage.saveString(_dashboardCacheKey, jsonString);
    } catch (e) {
      print('Failed to save dashboard cache: $e');
    }
  }

  /// Load stats from cache
  Future<void> _loadStatsFromCache() async {
    try {
      final jsonString = _storage.getString(_dashboardCacheKey);
      if (jsonString != null) {
        final Map<String, dynamic> json = jsonDecode(jsonString);
        stats.value = DashboardStatsModel.fromJson(json);
        
        // OVERRIDE GOAL FROM STORAGE TO ENSURE SYNC (Even for cache)
        final user = await _storage.getUserData();
        int currentStepGoal = 0;
        int currentWaterGoal = 0;
        int currentSugarGoal = 0;
        int currentCalorieGoal = 0;
        
        if (user != null && user['goals'] != null) {
           currentStepGoal = (double.tryParse(user['goals']['steps'].toString()) ?? 0).toInt();
           currentWaterGoal = (double.tryParse(user['goals']['water'].toString()) ?? 0).toInt();
           currentSugarGoal = (double.tryParse(user['goals']['sugar'].toString()) ?? 0).toInt();
           currentCalorieGoal = (double.tryParse(user['goals']['calories'].toString()) ?? 0).toInt();
           final currentBurnGoal = (double.tryParse(user['goals']['burn']?.toString() ?? '0') ?? 0).toDouble();
           print('DEBUG DashboardController: Loaded goal from storage: $currentStepGoal');
        }
        
        if (stats.value != null && (currentStepGoal > 0 || currentWaterGoal > 0 || currentSugarGoal > 0 || currentCalorieGoal > 0)) {
           stats.value = DashboardStatsModel(
              date: stats.value!.date,
              calories: CalorieStatsModel(
                 consumed: stats.value!.calories.consumed,
                 burned: stats.value!.calories.burned,
                 goal: currentCalorieGoal > 0 ? currentCalorieGoal.toDouble() : stats.value!.calories.goal,
              ),
              sugar: SugarStatsModel(
                 consumed: stats.value!.sugar.consumed,
                 goal: currentSugarGoal > 0 ? currentSugarGoal.toDouble() : stats.value!.sugar.goal,
              ),
              water: WaterStatsModel(
                 consumed: stats.value!.water.consumed,
                 goal: currentWaterGoal > 0 ? currentWaterGoal.toDouble() : stats.value!.water.goal,
              ),
              activity: ActivityStatsModel(
                 duration: stats.value!.activity.duration,
                 distance: stats.value!.activity.distance,
                 caloriesBurned: stats.value!.activity.caloriesBurned,
                 goalBurn: (user != null && user['goals']?['burn'] != null) ? (user['goals']!['burn'] as num).toDouble() : stats.value!.activity.goalBurn, 
                 steps: stats.value!.activity.steps,
                 goalSteps: currentStepGoal > 0 ? currentStepGoal : stats.value!.activity.goalSteps, // Legacy check
                 walkingSteps: stats.value!.activity.walkingSteps,
                 joggingSteps: stats.value!.activity.joggingSteps,
              ),
              lastFood: stats.value!.lastFood,
           );
        }
        print('✅ Dashboard loaded from cache');
      }
    } catch (e) {
      print('Failed to load dashboard cache: $e');
    }
  }


}
