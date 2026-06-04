import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:scansek/app/data/models/food_model.dart';
import 'package:scansek/app/data/models/water_model.dart';
import 'package:scansek/app/data/providers/api/api_client.dart';
import 'package:scansek/app/data/providers/api/api_endpoints.dart';
import 'package:scansek/app/data/providers/api/network_exception.dart';
import 'package:scansek/app/widgets/snackbars/snackbar_designs.dart';
import '../../../widgets/states/error_state.dart';

class HistoryController extends GetxController with GetSingleTickerProviderStateMixin {
  final ApiClient _apiClient = Get.find<ApiClient>();

  // Tab Controller (4 tabs now: Food, Water, Sugar, Calories)
  late TabController tabController;
  late ScrollController dateScrollController;

  // Observable states
  final RxInt currentTab = 0.obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxBool showSearch = false.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  // Data lists
  final RxList<FoodModel> foodList = <FoodModel>[].obs;
  final RxList<WaterModel> waterList = <WaterModel>[].obs;
  final RxList<FoodModel> sugarList = <FoodModel>[].obs; // Food items with sugar
  final RxList<FoodModel> calorieList = <FoodModel>[].obs; // Food items with calories

  // Filtered lists
  List<FoodModel> get filteredFoodList {
    if (searchQuery.value.isEmpty) return foodList;
    return foodList.where((food) {
      return food.name.toLowerCase().contains(searchQuery.value.toLowerCase());
    }).toList();
  }

  List<WaterModel> get filteredWaterList => waterList;
  
  List<FoodModel> get filteredSugarList {
    if (searchQuery.value.isEmpty) return sugarList;
    return sugarList.where((food) {
      return food.name.toLowerCase().contains(searchQuery.value.toLowerCase());
    }).toList();
  }
  
  List<FoodModel> get filteredCalorieList {
    if (searchQuery.value.isEmpty) return calorieList;
    return calorieList.where((food) {
      return food.name.toLowerCase().contains(searchQuery.value.toLowerCase());
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    
    // Check if initial tab was specified
    final args = Get.arguments;
    int initialTab = 0;
    if (args != null && args is Map && args.containsKey('initialTab')) {
      initialTab = args['initialTab'] as int;
    }
    
    // Initialize tab controller
    tabController = TabController(length: 4, vsync: this, initialIndex: initialTab);
    tabController.addListener(() {
      currentTab.value = tabController.index;
    });
    currentTab.value = initialTab;
    
    // Initialize scroll controller
    dateScrollController = ScrollController();
    
    // Fetch history data
    fetchHistory().then((_) {
      // Use SchedulerBinding for better timing after full frame render
      SchedulerBinding.instance.addPostFrameCallback((_) {
        // Try scrolling with retry
        _scrollToSelectedDateWithRetry();
      });
    });
  }

  @override
  void onReady() {
    super.onReady();
    // Auto-refresh when screen is shown (e.g., coming back from other screens)
    fetchHistory();
  }

  @override
  void onClose() {
    tabController.dispose();
    dateScrollController.dispose();
    super.onClose();
  }

  /// Fetch history data
  Future<void> fetchHistory() async {
    isLoading.value = true;

    try {
      // Format date for API (YYYY-MM-DD)
      final dateStr = '${selectedDate.value.year}-${selectedDate.value.month.toString().padLeft(2, '0')}-${selectedDate.value.day.toString().padLeft(2, '0')}';

      // Fetch food history - use startDate and endDate for single day filtering
      final foodResponse = await _apiClient.get(
        '${ApiEndpoints.foodHistory}?startDate=$dateStr&endDate=$dateStr',
      );

      // Fetch water history - use startDate and endDate for single day filtering
      final waterResponse = await _apiClient.get(
        '${ApiEndpoints.waterHistory}?startDate=$dateStr&endDate=$dateStr',
      );

      if (foodResponse.statusCode == 200) {
        final responseData = foodResponse.data;
        List foodData;
        
        // Handle API response format: {data: {items: [...], pagination: {...}}}
        if (responseData is Map && responseData.containsKey('data')) {
          final dataObj = responseData['data'];
          if (dataObj is Map && dataObj.containsKey('items')) {
            foodData = dataObj['items'] as List;
          } else if (dataObj is List) {
            foodData = dataObj;
          } else {
            foodData = [];
          }
        } else if (responseData is List) {
          foodData = responseData;
        } else {
          foodData = [];
        }
        
        final allFoods = foodData.map((json) => FoodModel.fromJson(json)).toList();
        
        foodList.value = allFoods;
        // Sugar list: foods with sugar > 0
        sugarList.value = allFoods.where((food) => food.totalSugar > 0).toList();
        // Calorie list: foods with calories > 0
        calorieList.value = allFoods.where((food) => food.totalCalories > 0).toList();
      }

      if (waterResponse.statusCode == 200) {
        final responseData = waterResponse.data;
        List waterData;
        
        // Handle API response  format: {data: {items: [...], pagination: {...}}}
        if (responseData is Map && responseData.containsKey('data')) {
          final dataObj = responseData['data'];
          if (dataObj is Map && dataObj.containsKey('items')) {
            waterData = dataObj['items'] as List;
          } else if (dataObj is List) {
            waterData = dataObj;
          } else {
            waterData = [];
          }
        } else if (responseData is List) {
          waterData = responseData;
        } else {
          waterData = [];
        }
        
        waterList.value = waterData.map((json) => WaterModel.fromJson(json)).toList();
      }
    } on NetworkException catch (e) {
      if (foodList.isEmpty && waterList.isEmpty) {
         ErrorSnackbar.show(Get.context!, e.message);
      }
      print('History fetch network error: ${e.message}');
    } catch (e) {
      // Silent fail - just log error, don't show snackbar if we have cached data
      print('History fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Change selected date
  void changeDate(DateTime date) {
    selectedDate.value = date;
    fetchHistory();
    _scrollToSelectedDate();
  }

  /// Scroll with retry mechanism
  void _scrollToSelectedDateWithRetry({int attempt = 0, int maxAttempts = 5}) {
    if (attempt >= maxAttempts) {
      print('❌ Failed to scroll after $maxAttempts attempts');
      return;
    }
    
    if (!dateScrollController.hasClients) {
      print('⚠️ Retry $attempt: ScrollController not ready, retrying...');
      Future.delayed(Duration(milliseconds: 100 * (attempt + 1)), () {
        _scrollToSelectedDateWithRetry(attempt: attempt + 1, maxAttempts: maxAttempts);
      });
      return;
    }
    
    _scrollToSelectedDate();
  }

  /// Scroll to selected date in horizontal calendar
  void _scrollToSelectedDate() {
    // Check if scroll controller is attached and has clients
    if (!dateScrollController.hasClients) {
      print('⚠️ ScrollController not ready yet');
      return;
    }
    
    // Calculate index based on the 30-day window (15 days past, today, 14 days future)
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final selectedDateOnly = DateTime(selectedDate.value.year, selectedDate.value.month, selectedDate.value.day);
    final diffDays = todayDate.difference(selectedDateOnly).inDays;
    
    // Index 15 corresponds to today (today.subtract(15 - 15) == today)
    int selectedIndex = 15 - diffDays;
    
    // Fallback bounds
    if (selectedIndex < 0) selectedIndex = 0;
    if (selectedIndex > 29) selectedIndex = 29;
    
    // Each date item width
    final itemWidth = 63.0; // 55 width + 8 margin
    final screenWidth = Get.width;
    
    // Position of selected item from the start
    final itemPosition = selectedIndex * itemWidth;
    
    // Calculate offset to center the item
    // We want the item center to be at screen center
    final targetOffset = itemPosition - (screenWidth / 2) + (itemWidth / 2);
    
    // Clamp to valid scroll range
    final maxScroll = dateScrollController.position.maxScrollExtent;
    final minScroll = dateScrollController.position.minScrollExtent;
    final finalOffset = targetOffset.clamp(minScroll, maxScroll);
    
    print('📍 Date: ${selectedDate.value.day}, Index: $selectedIndex');
    print('📍 Item pos: $itemPosition, Screen: $screenWidth, Target offset: $targetOffset, Final: $finalOffset');
    
    // Use jumpTo for instant positioning
    try {
      dateScrollController.jumpTo(finalOffset);
      print('✅ Scrolled successfully to $finalOffset');
    } catch (e) {
      print('❌ Scroll failed: $e');
    }
  }

  /// Search food by name
  void searchFood(String query) {
    searchQuery.value = query;
  }

  /// Delete food
  Future<void> deleteFood(String foodId) async {
    try {
      final response = await _apiClient.delete('/food/$foodId');

      if (response.statusCode == 200) {
        final message = response.data['message'] ?? 'Makanan berhasil dihapus';
        ElegantSnackbar.success(Get.context!, message);
        foodList.removeWhere((food) => food.id == foodId);
      }
    } on NetworkException catch (e) {
      ErrorSnackbar.show(Get.context!, e.message);
    } catch (e) {
      ElegantSnackbar.error(Get.context!, 'Waduh, ada error nih');
    }
  }

  /// Delete water
  Future<void> deleteWater(String waterId) async {
    try {
      final response = await _apiClient.delete('/water/$waterId');

      if (response.statusCode == 200) {
        final message = response.data['message'] ?? 'Air berhasil dihapus';
        ElegantSnackbar.success(Get.context!, message);
        waterList.removeWhere((water) => water.id == waterId);
      }
    } on NetworkException catch (e) {
      ErrorSnackbar.show(Get.context!, e.message);
    } catch (e) {
      ElegantSnackbar.error(Get.context!, 'Waduh, ada error nih');
    }
  }

  /// Navigate to add food
  void goToAddFood() {
    Get.toNamed('/add-food');
  }

  /// Navigate to edit food

  void goToEditFood(FoodModel food) {
    Get.toNamed('/add-food', arguments: {
      'isEditMode': true,
      'id': food.id,
      'name': food.name,
      'sugarContent': food.totalSugar / food.quantity, // Send per portion value
      'calorieContent': food.totalCalories / food.quantity, // Send per portion value
      'weight': food.weight,
      'weightUnit': food.weightUnit,
      'quantity': food.quantity,
      'consumptionTime': food.consumptionTime.toIso8601String(),
    });
  }

  /// Jump to specific tab (for navigation from dashboard)
  void jumpToTab(int index) {
    if (index >= 0 && index < 4) {
      tabController.index = index;
      currentTab.value = index;
    }
  }

  /// Toggle search bar
  void toggleSearch() {
    showSearch.value = !showSearch.value;
    if (!showSearch.value) {
      searchQuery.value = '';
    }
  }

  /// Get item count for current tab
  int get currentItemCount {
    switch (currentTab.value) {
      case 0: return foodList.length;
      case 1: return waterList.length;
      case 2: return sugarList.length;
      case 3: return calorieList.length;
      default: return 0;
    }
  }
}
