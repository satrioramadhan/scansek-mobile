import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:scansek/app/core/theme/app_colors.dart';
import 'package:scansek/app/core/theme/app_text_styles.dart';
import 'package:scansek/app/widgets/loaders/shimmer_loader.dart';
import '../controllers/history_controller.dart';

class HistoryView extends GetView<HistoryController> {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false, // Keep FAB at bottom when keyboard shows
      body: Column(
        children: [
          // Compact Modern AppBar with rounded corners
          Obx(() {
            // Soft/pastel colors matching dashboard cards
            final categoryColors = [
              const Color(0xFF80CBC4), // Food - Soft Teal (lebih lembut)
              const Color(0xFF90CAF9), // Water - Soft Blue
              const Color(0xFFEF9A9A), // Sugar - Soft Red 
              const Color(0xFFFFCC80), // Calorie - Soft Orange
            ];
            final currentColor = categoryColors[controller.currentTab.value];
            
            return Container(
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    currentColor,
                    currentColor.withOpacity(0.85),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Top bar - Always visible (Title, Month+Year, Count, Search Icon)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Title + Month + Year
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Riwayat',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Month + Year in Indonesian
                              Obx(() {
                                const monthNames = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 
                                                    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
                                final monthName = monthNames[controller.selectedDate.value.month - 1];
                                final year = controller.selectedDate.value.year;
                                return Text(
                                  '$monthName $year',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              }),
                            ],
                          ),
                          const Spacer(),
                          
                          // Count badge
                          Obx(() => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${controller.currentItemCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )),
                          
                          const SizedBox(width: 12),
                          
                          // Search icon
                          Obx(() => controller.currentTab.value == 1 
                            ? const SizedBox(width: 48) // Placeholder to maintain layout
                            : IconButton(
                                onPressed: controller.toggleSearch,
                                icon: const Icon(Icons.search, color: Colors.white),
                                iconSize: 26,
                              )
                          ),
                        ],
                      ),
                    ),
                    
                    // Elastic Search Field (appears between month and calendar)
                    Obx(() {
                      if (!controller.showSearch.value || controller.currentTab.value == 1) return const SizedBox.shrink();
                      
                      // Get current category color for consistency
                      final categoryColors = [
                        const Color(0xFF80CBC4), // Food - Soft Teal
                        const Color(0xFF90CAF9), // Water - Soft Blue
                        const Color(0xFFEF9A9A), // Sugar - Soft Red
                        const Color(0xFFFFCC80), // Calorie - Soft Orange
                      ];
                      final currentColor = categoryColors[controller.currentTab.value];
                      
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: TextField(
                          autofocus: true,
                          onChanged: controller.searchFood,
                          autocorrect: false,
                          enableSuggestions: false,
                          style: const TextStyle(
                            color: Colors.white,
                            decorationThickness: 0,
                          ),
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            hintText: 'Cari...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                            prefixIcon: Icon(Icons.search, color: currentColor),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.close, color: currentColor),
                              onPressed: controller.toggleSearch,
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      );
                    }),
                    
                    // Circular Date picker
                    _buildCompactDatePicker(),
                    
                    const SizedBox(height: 12),
                    
                    // Floating category button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Row(
                        children: [
                          Obx(() {
                            final icons = [Icons.restaurant, Icons.water_drop, Icons.cookie_outlined, Icons.local_fire_department];
                            final labels = ['Makanan/Minuman', 'Air', 'Gula', 'Kalori'];
                            final currentIcon = icons[controller.currentTab.value];
                            final currentLabel = labels[controller.currentTab.value];
                            
                            return InkWell(
                              onTap: () => _showCategorySelector(context),
                              borderRadius: BorderRadius.circular(25),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(currentIcon, color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      currentLabel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const Spacer(),
                          Obx(() => _buildSummaryStats()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Content based on current tab (manual switching, no TabBarView)
          Expanded(
            child: Obx(() {
              switch (controller.currentTab.value) {
                case 0: return _buildFoodList();
                case 1: return _buildWaterList();
                case 2: return _buildSugarList();
                case 3: return _buildCalorieList();
                default: return _buildFoodList();
              }
            }),
          ),
        ],
      ),
      // No FAB in History - use main navbar FAB
    );
  }

  // Compact circular date picker with enhanced active design
  Widget _buildCompactDatePicker() {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        final selectedDate = controller.selectedDate.value;
        final today = DateTime.now();
        final dates = _getDateRange(selectedDate);

        return ListView.builder(
          controller: controller.dateScrollController,
          scrollDirection: Axis.horizontal,
          itemCount: dates.length,
          itemBuilder: (context, index) {
            final date = dates[index];
            final isSelected = _isSameDay(date, selectedDate);
            final isToday = _isSameDay(date, today);
            
            // Indonesian day names (short)
            const dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
            final dayName = dayNames[date.weekday - 1];

            return GestureDetector(
              onTap: () => controller.changeDate(date),
              child: Container(
                width: 55,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected 
                      ? Colors.white 
                      : Colors.white.withOpacity(0.2),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                  border: isToday && !isSelected
                      ? Border.all(color: Colors.white, width: 2.5)
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayName,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected 
                            ? (controller.currentTab.value == 0 
                                ? AppColors.primary 
                                : controller.currentTab.value == 1 
                                    ? const Color(0xFF2196F3)
                                    : controller.currentTab.value == 2
                                        ? Colors.pink
                                        : const Color(0xFFFF9800))
                            : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date.day.toString(),
                      style: TextStyle(
                        fontSize: isSelected ? 20 : 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected 
                            ? (controller.currentTab.value == 0 
                                ? AppColors.primary 
                                : controller.currentTab.value == 1 
                                    ? const Color(0xFF2196F3)
                                    : controller.currentTab.value == 2
                                        ? Colors.pink
                                        : const Color(0xFFFF9800))
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  // Category selector bottom sheet with dynamic colors
  void _showCategorySelector(BuildContext context) {
    // Get current category color
    final categoryColors = [
      const Color(0xFF80CBC4), // Food - Soft Teal
      const Color(0xFF90CAF9), // Water - Soft Blue
      const Color(0xFFEF9A9A), // Sugar - Soft Red
      const Color(0xFFFFCC80), // Calorie - Soft Orange
    ];
    final currentColor = categoryColors[controller.currentTab.value];
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih Kategori',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildCategoryOption(Icons.restaurant, 'Makanan/Minuman', 0, currentColor),
            _buildCategoryOption(Icons.water_drop, 'Air', 1, currentColor),
            _buildCategoryOption(Icons.cookie_outlined, 'Gula', 2, currentColor),
            _buildCategoryOption(Icons.local_fire_department, 'Kalori', 3, currentColor),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryOption(IconData icon, String label, int index, Color activeColor) {
    return Obx(() {
      final isSelected = controller.currentTab.value == index;
      return InkWell(
        onTap: () {
          controller.jumpToTab(index);
          Get.back();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.15) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: activeColor, width: 2) : null,
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? activeColor : AppColors.textSecondary),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? activeColor : AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Icon(Icons.check_circle, color: activeColor, size: 24),
            ],
          ),
        ),
      );
    });
  }

  // Original date picker (hidden, replaced by compact circular version)
  Widget _buildDatePicker() {
    return const SizedBox.shrink();
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: TextField(
        onChanged: controller.searchFood,
        decoration: InputDecoration(
          hintText: 'Cari makanan...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFoodList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return _buildShimmerList();
      }

      final foodList = controller.filteredFoodList;

      if (foodList.isEmpty) {
        return _buildEmptyState('Belum ada makanan dicatat');
      }

      return RefreshIndicator(
        onRefresh: controller.fetchHistory,
        color: AppColors.primary,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: foodList.length,
          itemBuilder: (context, index) {
            final food = foodList[index];
            return _buildFoodCard(food);
          },
        ),
      );
    });
  }

  Widget _buildWaterList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return _buildShimmerList();
      }

      final waterList = controller.filteredWaterList;

      if (waterList.isEmpty) {
        return _buildEmptyState('Belum ada air dicatat');
      }

      return RefreshIndicator(
        onRefresh: controller.fetchHistory,
        color: AppColors.primary,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: waterList.length,
          itemBuilder: (context, index) {
            final water = waterList[index];
            return _buildWaterCard(water);
          },
        ),
      );
    });
  }

  Widget _buildSugarList() {
    return Obx(() {
      if (controller.isLoading.value) return _buildShimmerList();
      
      final sugarList = controller.filteredSugarList;
      if (sugarList.isEmpty) {
        return _buildEmptyState('Belum ada makanan dengan gula dicatat');
      }

      return RefreshIndicator(
        onRefresh: controller.fetchHistory,
        color: AppColors.primary,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sugarList.length,
          itemBuilder: (context, index) {
            final food = sugarList[index];
            return _buildFoodCard(food);
          },
        ),
      );
    });
  }

  Widget _buildCalorieList() {
    return Obx(() {
      if (controller.isLoading.value) return _buildShimmerList();
      
      final calorieList = controller.filteredCalorieList;
      if (calorieList.isEmpty) {
        return _buildEmptyState('Belum ada makanan dengan kalori dicatat');
      }

      return RefreshIndicator(
        onRefresh: controller.fetchHistory,
        color: AppColors.primary,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: calorieList.length,
          itemBuilder: (context, index) {
            final food = calorieList[index];
            return _buildFoodCard(food);
          },
        ),
      );
    });
  }

  Widget _buildFoodCard(food) {
    final tab = controller.currentTab.value;
    final cardColor = _getCardColor();
    final isNutrientTab = tab == 2 || tab == 3;
    
    return GestureDetector(
      onTap: tab == 0 ? () => _showFoodDetail(food) : null, // Only tappable in Makanan tab
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2), // Smooth shadow
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: isNutrientTab ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                food.isScanned ? Icons.qr_code_scanner : Icons.restaurant,
                color: cardColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.name,
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(food.consumptionTime),
                    style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                  ),
                ],
              ),
            ),
            
            // Values & Menu
            Row(
              crossAxisAlignment: isNutrientTab ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: isNutrientTab ? 0 : 2, right: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (tab == 0) ...[
                        // Makanan tab - show both
                        Text(
                          '${food.totalSugar.toStringAsFixed(1)}g gula',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: cardColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${food.totalCalories.toStringAsFixed(0)} kcal',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ] else if (tab == 2) ...[
                        // Gula tab - only sugar
                        Text(
                          '${food.totalSugar.toStringAsFixed(1)}g',
                          style: AppTextStyles.bodyLarge.copyWith( // Smaller font
                            color: cardColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else if (tab == 3) ...[
                        // Kalori tab - only calories
                        Text(
                          '${food.totalCalories.toStringAsFixed(0)} kcal',
                          style: AppTextStyles.bodyLarge.copyWith( // Smaller font
                            color: cardColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // 3-dots Menu (Only for Food Tab)
                if (!isNutrientTab)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          controller.goToEditFood(food);
                        } else if (value == 'delete') {
                          final confirm = await _showDeleteDialog('Yakin ingin menghapus item ini?');
                          if (confirm) controller.deleteFood(food.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20, color: Color(0xFF80CBC4)), // Soft Teal
                              SizedBox(width: 12),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Color(0xFFEF9A9A)), // Soft Red
                              SizedBox(width: 12),
                              Text('Hapus'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterCard(water) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.water_drop, color: Colors.blue, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${water.amount}ml',
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(water.intakeTime),
                  style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                ),
              ],
            ),
          ),
          
          // 3-dots Menu for Water
          SizedBox(
            width: 24,
            height: 24,
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) async {
                if (value == 'delete') {
                  final confirm = await _showDeleteDialog('Yakin ingin menghapus item ini?');
                  if (confirm) controller.deleteWater(water.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Color(0xFFEF9A9A)), // Soft Red
                      SizedBox(width: 12),
                      Text('Hapus'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: ShimmerTrackerCard(),
      ),
    );
  }

  Future<bool> _showDeleteDialog(String message) async {
    return await Get.dialog<bool>(
          Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE), // Soft Red background
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFEF5350), // Red
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Title & Message
                  const Text(
                    'Hapus Item?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
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
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Get.back(result: false),
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
                              color: Colors.grey[700],
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
                            backgroundColor: const Color(0xFFEF5350),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Hapus',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
          transitionDuration: const Duration(milliseconds: 200),
        ) ??
        false;
  }

  List<DateTime> _getDateRange(DateTime center) {
    final today = DateTime.now();
    // Generate 30 hari berurutan (15 hari ke belakang, hari ini, 14 hari ke depan)
    // agar bisa digeser melewati batas bulan seperti di halaman Riwayat Aktivitas
    final dates = List.generate(30, (index) {
      return today.subtract(Duration(days: 15 - index));
    });
    
    return dates;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return _isSameDay(date, now);
  }

  /// Build summary stats for appbar (kalori, gula, air only)
  Widget _buildSummaryStats() {
    final tab = controller.currentTab.value;
    
    // Tab 0 (Makanan/Minuman) - no summary
    if (tab == 0) return const SizedBox.shrink();
    
    // Calculate totals based on current data
    double total = 0;
    String unit = '';
    String dayLabel = '';
    
    final now = DateTime.now();
    final isToday = _isSameDay(controller.selectedDate.value, now);
    
    if (isToday) {
      dayLabel = 'Hari ini';
    } else {
      const dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
      dayLabel = dayNames[controller.selectedDate.value.weekday - 1];
    }
    
    switch (tab) {
      case 1: // Air
        total = controller.waterList.fold(0, (sum, water) => sum + water.amount);
        unit = 'ml';
        break;
      case 2: // Gula
        total = controller.sugarList.fold(0, (sum, food) => sum + food.totalSugar);
        unit = 'g';
        break;
      case 3: // Kalori
        total = controller.calorieList.fold(0, (sum, food) => sum + food.totalCalories);
        unit = 'kcal';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
      ),
      child: Text(
        '$dayLabel: ${total.toStringAsFixed(total >= 100 ? 0 : 1)} $unit',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Get card color based on active tab
  Color _getCardColor() {
    final tab = controller.currentTab.value;
    switch (tab) {
      case 0: return const Color(0xFF80CBC4); // Teal for food
      case 1: return const Color(0xFF90CAF9); // Blue for water
      case 2: return const Color(0xFFEF9A9A); // Pink/Red for sugar
      case 3: return const Color(0xFFFFCC80); // Orange for calorie
      default: return AppColors.primary;
    }
  }

  /// Show food detail bottom sheet
  void _showFoodDetail(food) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getCardColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    food.isScanned ? Icons.qr_code_scanner : Icons.restaurant,
                    color: _getCardColor(),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        food.isScanned ? 'Dari Scanner' : 'Input Manual',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildDetailRow('Waktu Konsumsi', DateFormat('dd MMM yyyy, HH:mm').format(food.consumptionTime)),
            _buildDetailRow('Berat', '${food.weight} ${food.weightUnit}'),
            _buildDetailRow('Jumlah', '${food.quantity}x'),
            const Divider(height: 24),
            _buildDetailRow('Gula per unit', '${food.sugarContent.toStringAsFixed(1)}g'),
            _buildDetailRow('Total Gula', '${food.totalSugar.toStringAsFixed(1)}g', isHighlight: true),
            const SizedBox(height: 8),
            _buildDetailRow('Kalori per unit', '${food.calorieContent.toStringAsFixed(0)} kcal'),
            _buildDetailRow('Total Kalori', '${food.totalCalories.toStringAsFixed(0)} kcal', isHighlight: true),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getCardColor(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tutup', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isHighlight ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isHighlight ? _getCardColor() : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

