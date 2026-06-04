import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:scansek/app/core/theme/app_colors.dart';
import 'package:scansek/app/core/theme/app_text_styles.dart';
import '../controllers/graphs_controller.dart';

class GraphsView extends GetView<GraphsController> {
  const GraphsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Softer background
      appBar: AppBar(
        title: const Text(
          'Analisis & Grafik',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF80CBC4),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        return Column(
          children: [
            const SizedBox(height: 16),
            // Date Navigator (Floating Card)
            _buildDateNavigator(context),

            const SizedBox(height: 16),
            // Tab Buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(
                  controller.tabTitles.length,
                  (index) => _buildTabButton(index),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    if (controller.currentTab.value == 4)
                       _buildOverallChart()
                    else
                       _buildDetailedView(controller.currentTab.value),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildDateNavigator(BuildContext context) {
    final start = controller.startDate.value;
    final end = controller.endDate.value;
    final formatter = DateFormat('d MMM yyyy');
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1), // Very light teal
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.date_range_rounded, color: Color(0xFF26A69A), size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rentang Tanggal',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  Text(
                    '${formatter.format(start)} - ${formatter.format(end)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          IconButton(
            onPressed: () => controller.selectDateRange(context),
            icon: const Icon(Icons.edit_calendar_rounded, color: AppColors.textHint),
            tooltip: 'Ubah Tanggal',
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index) {
    return Obx(() {
      final isActive = controller.currentTab.value == index;
      final color = controller.getCategoryColor(index);
      
      return GestureDetector(
        onTap: () => controller.changeTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: isActive ? LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ) : null,
            color: isActive ? null : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isActive ? [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Text(
            controller.tabTitles[index],
            style: AppTextStyles.bodyMedium.copyWith(
              color: isActive ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDetailedView(int tabIndex) {
    String title = '';
    List<double> data = [];
    String unit = '';
    
    // Get colors
    Color color = controller.getCategoryColor(tabIndex);

    switch (tabIndex) {
      case 0: // Sugar
        title = 'Konsumsi Gula';
        data = controller.sugarData;
        unit = 'g';
        break;
      case 1: // Calories
        title = 'Asupan Kalori';
        data = controller.caloriesData;
        unit = 'kcal';
        break;
      case 2: // Water
        title = 'Asupan Air';
        data = controller.waterData;
        unit = 'ml';
        break;
      case 3: // Activity
        title = 'Kalori Terbakar';
        data = controller.burnData;
        unit = 'kcal';
        break;
    }
    
    // Safety check
    if (data.isEmpty) return _buildEmptyState();

    final status = controller.getStatus(tabIndex);
    // Use DAILY goal for the chart line and label, so it matches the daily data points
    final goal = controller.getDailyGoal(tabIndex);

    // 1. Determine the relevant high point (User Logic: Target vs Peak Data)
    double peakData = data.reduce((curr, next) => curr > next ? curr : next);
    double effectiveMax = (peakData > goal) ? peakData : goal;

    // 2. Calculate nice interval
    double interval = _calculateNiceInterval(effectiveMax);
    
    // 3. Determine the top grid line (The highest Label user wants to see)
    // Snap effectiveMax to the nearest upper multiple of interval
    double topGridLine = ((effectiveMax / interval).ceil() * interval).toDouble();
    if (topGridLine == 0) topGridLine = interval;
    
    // 4. Viewport Max Y (Physical Chart Limit)
    // Add 50% of interval as headroom.
    // We will disable TOP clipping so the dot can "breathe", but we still need space.
    double viewportMaxY = topGridLine + (interval * 0.5);

    return Column(
      children: [
        // Main Chart Canvas (Reduced padding, wider)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8), // Minimal margin
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
               BoxShadow(
                 color: Colors.black.withOpacity(0.04),
                 blurRadius: 16,
                 offset: const Offset(0, 4),
               ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                    Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(title, style: AppTextStyles.h4.copyWith(color: Colors.black87)),
                         const SizedBox(height: 4),
                         Text('Target: ${goal.toInt()} $unit', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                       ],
                    ),
                    // Status Chip with statusColor (indicator for Good/Bad)
                    _buildStatusChip(status['status'], status['statusColor'] as Color),
                 ],
               ),
               const SizedBox(height: 32),
               SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    // Increase spacing to 80.0 per point to prevent cramping and "dipping" curves
                    width: data.length * 80.0 < (Get.width - 48) ? (Get.width - 48) : data.length * 80.0,
                    height: 320, // Taller chart
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: interval,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.grey.withOpacity(0.1),
                            strokeWidth: 1,
                          ),
                        ),
                        // Disable clipping entirely so dots aren't cut off at edges
                        clipData: const FlClipData.none(),
                        titlesData: FlTitlesData(
                           leftTitles: AxisTitles(
                             sideTitles: SideTitles(
                               showTitles: true,
                               reservedSize: 45, 
                               interval: interval,
                               getTitlesWidget: (value, meta) {
                                  // Only show labels up to topGridLine. 
                                  if (value > topGridLine) return const SizedBox.shrink();
                                  
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                                  );
                               },
                             ),
                           ),
                           topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                           rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                           bottomTitles: AxisTitles(
                             sideTitles: SideTitles(
                               showTitles: true,
                               interval: 1,
                               getTitlesWidget: (value, meta) {
                                  // Ensure we only show labels for integer indices (prevent duplicates like 13/2, 13/2)
                                  if (value % 1 != 0) return const SizedBox.shrink();
                                  
                                  final index = value.toInt();
                                  if (index >= 0 && index < controller.dateLabels.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Text(
                                        controller.dateLabels[index],
                                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                                      ),
                                    );
                                  }
                                  return const Text('');
                               },
                             ),
                           ),
                        ),
                        borderData: FlBorderData(show: false),
                        minY: 0,
                        maxY: viewportMaxY, // Includes buffer
                        // Add horizontal buffer to prevent dots from being cut off at edges
                        minX: -0.2,
                        maxX: (data.length - 1) + 0.2,
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i])),
                            // User requested "trading style" (sharp corners) to avoid dipping
                            isCurved: false, 
                            gradient: LinearGradient(
                              colors: [color, color.withOpacity(0.5)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                radius: 5,
                                color: Colors.white,
                                strokeWidth: 3,
                                strokeColor: color,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [color.withOpacity(0.25), color.withOpacity(0.0)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            HorizontalLine(
                              y: goal,
                              color: const Color(0xFFFF5252), // Red for Limit
                              strokeWidth: 1.5,
                              dashArray: [6, 4],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
               ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
                // Insight Card: Elegant & Simple (No full background color)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Simple colored bar accent
                        Container(
                          width: 4,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Text content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Insight',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.textHint,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Icon(
                                    Icons.tips_and_updates_outlined, // Outlined version is lighter
                                    color: color.withOpacity(0.8),
                                    size: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                status['message'],
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.normal, // More elegant, less heavy
                                  height: 1.5,
                                ),
                              ),
                              if (status['impact'] != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: (status['statusColor'] as Color).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: (status['statusColor'] as Color).withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.info_outline_rounded, size: 18, color: status['statusColor']),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          status['impact'] as String,
                                          style: AppTextStyles.caption.copyWith(
                                            color: Colors.black87,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Stats Row: Minimalist Elegant Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildCleanStatCard(
                        'Rata-rata', 
                        '${(status['average'] as double).toStringAsFixed(0)}',
                        unit,
                        Icons.analytics_outlined, // Outlined icon
                        color, 
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCleanStatCard(
                        'Total', 
                        '${controller.getTotal(data).toStringAsFixed(0)}',
                        unit,
                        Icons.functions_rounded,
                        color, 
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Combined Radar Chart Implementation
  Widget _buildOverallChart() {
    return Obx(() {
      final sugarNorm = controller.getNormalizedData(0);
      final calNorm = controller.getNormalizedData(1);
      final waterNorm = controller.getNormalizedData(2);
      final activityNorm = controller.getNormalizedData(3);
      
      int count = sugarNorm.length;
      if (count == 0) return _buildEmptyState();

      final titles = ['Kalori', 'Aktivitas', 'Air', 'Gula'];
      List<RadarDataSet> dataSets = [
        // 100% (Merah - Peringatan batas luar)
        RadarDataSet(
          fillColor: Colors.transparent,
          borderColor: const Color(0xFFFF5252).withOpacity(0.35), // Opacity dikurangi lagi
          borderWidth: 2.5,
          entryRadius: 0,
          dataEntries: [RadarEntry(value: 100), RadarEntry(value: 100), RadarEntry(value: 100), RadarEntry(value: 100)],
        ),
        // 75% (Oren Cerah - Hati-hati)
        RadarDataSet(
          fillColor: Colors.transparent,
          borderColor: Colors.orange.shade400.withOpacity(0.35), // Opacity dikurangi lagi
          borderWidth: 2.5,
          entryRadius: 0,
          dataEntries: [RadarEntry(value: 75), RadarEntry(value: 75), RadarEntry(value: 75), RadarEntry(value: 75)],
        ),
        // 50% (Hijau - Aman/Ideal)
        RadarDataSet(
          fillColor: Colors.transparent,
          borderColor: Colors.lightGreen.shade400.withOpacity(0.35), // Opacity dikurangi lagi
          borderWidth: 2.5,
          entryRadius: 0,
          dataEntries: [RadarEntry(value: 50), RadarEntry(value: 50), RadarEntry(value: 50), RadarEntry(value: 50)],
        ),
        // 25% (Abu-abu pucat - Paling dalam / kurang data)
        RadarDataSet(
          fillColor: Colors.transparent,
          borderColor: Colors.grey.shade400.withOpacity(0.25), // Opacity dikurangi lagi
          borderWidth: 2.5,
          entryRadius: 0,
          dataEntries: [RadarEntry(value: 25), RadarEntry(value: 25), RadarEntry(value: 25), RadarEntry(value: 25)],
        ),
      ];

      final List<Color> dayColors = [
        Colors.purple[400]!,
        Colors.blue[400]!,
        Colors.cyan[400]!,
        Colors.teal[400]!,
        Colors.green[400]!,
        Colors.orange[400]!,
        Colors.pink[400]!,
      ];

      for (int i = 0; i < count; i++) {
        double s = i < sugarNorm.length ? sugarNorm[i] : 0;
        double c = i < calNorm.length ? calNorm[i] : 0;
        double w = i < waterNorm.length ? waterNorm[i] : 0;
        double a = i < activityNorm.length ? activityNorm[i] : 0;

        bool isSelected = controller.selectedRadarDayIndex.value == i;
        bool hasSelected = controller.selectedRadarDayIndex.value != -1;

        Color baseColor = dayColors[i % dayColors.length];
        // Jika ada hari yang dipilih, sembunyikan (0.0) hari lain agar tidak overlap/dobel.
        // Jika tidak ada yang dipilih, tampilkan semua (0.6).
        double opacity = hasSelected ? (isSelected ? 1.0 : 0.0) : 0.6; 
        double borderWidth = isSelected ? 4.0 : 2.5;
        Color fillColor = isSelected ? baseColor.withOpacity(0.35) : Colors.transparent;

        dataSets.add(
          RadarDataSet(
            fillColor: fillColor,
            borderColor: opacity > 0.0 ? baseColor.withOpacity(opacity) : Colors.transparent, // Hilangkan border jika 0
            entryRadius: isSelected ? 5.0 : (opacity > 0.0 ? 3.5 : 0.0), // Hilangkan titik jika disembunyikan
            dataEntries: [
              RadarEntry(value: c), // 0: Kalori (Top)
              RadarEntry(value: a), // 1: Aktivitas (Right)
              RadarEntry(value: w), // 2: Air (Bottom)
              RadarEntry(value: s), // 3: Gula (Left)
            ],
            borderWidth: borderWidth,
          ),
        );
      }

      // Insight Logic
      final insightData = controller.selectedRadarDayIndex.value != -1 
          ? controller.getDailyCombinedStatus(controller.selectedRadarDayIndex.value)
          : controller.getCombinedStatus();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(0.04),
               blurRadius: 16,
               offset: const Offset(0, 4),
             ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text('Keseimbangan Mingguan', style: AppTextStyles.h4),
                       const SizedBox(height: 4),
                       Text('Pilih tanggal untuk melihat detail target & grafik', style: AppTextStyles.caption.copyWith(color: AppColors.textHint)),
                     ],
                   ),
                 ),
               ],
             ),
             const SizedBox(height: 16),

             // Date List (Horizontal Scroll)
             SizedBox(
               height: 40,
               child: ListView.separated(
                 scrollDirection: Axis.horizontal,
                 itemCount: count,
                 separatorBuilder: (context, index) => const SizedBox(width: 8),
                 itemBuilder: (context, index) {
                   bool isSelected = controller.selectedRadarDayIndex.value == index;
                   Color dayColor = dayColors[index % dayColors.length];
                   return GestureDetector(
                     onTap: () {
                       if (isSelected) {
                         controller.selectedRadarDayIndex.value = -1;
                       } else {
                         controller.selectedRadarDayIndex.value = index;
                       }
                     },
                     child: AnimatedContainer(
                       duration: const Duration(milliseconds: 200),
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                       decoration: BoxDecoration(
                         color: isSelected ? dayColor : Colors.grey.shade50,
                         borderRadius: BorderRadius.circular(20),
                         border: Border.all(
                           color: isSelected ? dayColor : Colors.grey.shade200,
                         ),
                       ),
                       alignment: Alignment.center,
                       child: Text(
                         controller.dateLabels[index],
                         style: TextStyle(
                           color: isSelected ? Colors.white : Colors.black87,
                           fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                           fontSize: 12,
                         ),
                       ),
                     ),
                   );
                 },
               ),
             ),
             const SizedBox(height: 32),
             
             // Radar Chart
             SizedBox(
               height: 300,
               width: double.infinity,
               child: RadarChart(
                 RadarChartData(
                   dataSets: dataSets,
                   radarShape: RadarShape.polygon,
                   radarTouchData: RadarTouchData(
                     touchSpotThreshold: 40, // Area sentuh dibesarkan biar gampang diklik
                     touchCallback: (FlTouchEvent event, RadarTouchResponse? response) {
                       // Pakai FlTapUpEvent supaya nggak ketrigger pas user lagi geser/scroll (FlPanEvent)
                       if (event is FlTapUpEvent) {
                         if (response != null && response.touchedSpot != null) {
                           int touchedIndex = response.touchedSpot!.touchedDataSetIndex;
                           // Index 0-3 adalah garis grid buatan, jadi abaikan
                           if (touchedIndex >= 4) {
                             controller.selectedRadarDayIndex.value = touchedIndex - 4;
                           }
                           // Kita buang logika reset (-1) pas ngeklik area kosong/grid
                           // Biar state nggak hilang gara-gara user gak sengaja kesentuh pas scroll
                         }
                       }
                     },
                   ),
                   getTitle: (index, angle) {
                     return RadarChartTitle(
                       text: titles[index],
                       angle: 0, // Keep horizontal for readability
                     );
                   },
                   titleTextStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                   titlePositionPercentageOffset: 0.15,
                   tickCount: 4,
                   ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 10),
                   tickBorderData: const BorderSide(color: Color(0xFFE0E0E0), width: 2.5), // Garis sumbu abu terang solid biar gak bikin kotor warna grid
                   gridBorderData: const BorderSide(color: Colors.transparent, width: 0), // Grid native dimatikan (diganti dataset custom)
                   radarBorderData: const BorderSide(color: Colors.transparent, width: 0), 
                 ),
                 swapAnimationDuration: const Duration(milliseconds: 300),
               ),
             ),
             const SizedBox(height: 24),
           
           if (controller.selectedRadarDayIndex.value != -1) ...[
             _buildDailyMetricsGrid(controller.selectedRadarDayIndex.value),
             const SizedBox(height: 16),
           ],

           // Combined Insight Card
             Container(
               width: double.infinity,
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(20), // Sudut lebih membulat (elegan)
                 border: Border.all(
                   color: (insightData['statusColor'] as Color).withOpacity(0.3),
                   width: 1.5,
                 ),
                 boxShadow: [
                   BoxShadow(
                     color: (insightData['statusColor'] as Color).withOpacity(0.12),
                     blurRadius: 16,
                     offset: const Offset(0, 6),
                   ),
                 ],
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Row(
                         children: [
                           Icon(
                             Icons.insights_rounded,
                             color: insightData['statusColor'] as Color,
                             size: 20,
                           ),
                           const SizedBox(width: 8),
                           Text(
                             controller.selectedRadarDayIndex.value != -1 
                                ? 'Insight Harian' 
                                : 'Analisis Mingguan',
                             style: AppTextStyles.bodyMedium.copyWith(
                               color: insightData['statusColor'] as Color,
                               fontWeight: FontWeight.bold,
                             ),
                           ),
                         ],
                       ),
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                         decoration: BoxDecoration(
                           color: (insightData['statusColor'] as Color).withOpacity(0.1),
                           borderRadius: BorderRadius.circular(12),
                         ),
                         child: Text(
                           insightData['status'],
                           style: TextStyle(
                             color: insightData['statusColor'] as Color,
                             fontSize: 12,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 12),
                   Text(
                     insightData['message'],
                     style: AppTextStyles.bodyMedium.copyWith(
                       color: Colors.black87,
                       height: 1.5,
                     ),
                   ),
                   if (insightData['impact'] != null) ...[
                     const SizedBox(height: 12),
                     Container(
                       padding: const EdgeInsets.all(14), // Sedikit diperbesar
                       decoration: BoxDecoration(
                         color: (insightData['statusColor'] as Color).withOpacity(0.05), // Background warna tipis
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: (insightData['statusColor'] as Color).withOpacity(0.15)),
                       ),
                       child: Row(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Icon(Icons.info_outline_rounded, size: 18, color: insightData['statusColor'] as Color),
                           const SizedBox(width: 8),
                           Expanded(
                             child: Text(
                               insightData['impact'] as String,
                               style: AppTextStyles.caption.copyWith(
                                 color: Colors.black87,
                                 height: 1.4,
                               ),
                             ),
                           ),
                         ],
                       ),
                     ),
                   ],
                 ],
               ),
             ),
          ],
        ),
      );
    });
  }

  Widget _buildDailyMetricsGrid(int dayIndex) {
    final sugar = controller.sugarData.isNotEmpty && dayIndex < controller.sugarData.length ? controller.sugarData[dayIndex] : 0.0;
    final cal = controller.caloriesData.isNotEmpty && dayIndex < controller.caloriesData.length ? controller.caloriesData[dayIndex] : 0.0;
    final water = controller.waterData.isNotEmpty && dayIndex < controller.waterData.length ? controller.waterData[dayIndex] : 0.0;
    final burn = controller.burnData.isNotEmpty && dayIndex < controller.burnData.length ? controller.burnData[dayIndex] : 0.0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.5,
      children: [
        _buildMetricItem('Kalori', cal, controller.dailyCalorieGoal.value, 'kcal', Colors.orange),
        _buildMetricItem('Aktivitas', burn, controller.dailyBurnGoal.value, 'kcal', Colors.green),
        _buildMetricItem('Air', water, controller.dailyWaterGoal.value.toDouble(), 'ml', Colors.blue),
        _buildMetricItem('Gula', sugar, controller.dailySugarGoal.value, 'g', Colors.red),
      ],
    );
  }

  Widget _buildMetricItem(String title, double value, double target, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  ' / ${target.toStringAsFixed(0)} $unit', 
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildLineBar(List<double> data, Color color) {
    return LineChartBarData(
      spots: List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i])),
      // User requested "trading style" (sharp corners)
      isCurved: false,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true, // Enable dots to match detailed view
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 4, // Slightly smaller than detailed view (5) to avoid clutter
          color: Colors.white,
          strokeWidth: 2,
          strokeColor: color,
        ),
      ),
      belowBarData: BarAreaData(show: false), // Keep fill off for combined to reduce noise
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
  
  // Clean Stat Card (No opacity background, just text and Icon) or Simple Box?
  // "Simple Clean design (Solid color opacity + text bold)"
  // Elegant Minimalist Stat Card
  Widget _buildCleanStatCard(String label, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20), // More padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), // Very subtle shadow
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.1), // Very subtle colored border (optional)
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08), // Light circle bg
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              // Optional: Trend arrow or something could go here
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTextStyles.h2.copyWith(
                  fontWeight: FontWeight.bold, // Bold simple number
                  color: Colors.black87,
                  fontSize: 28, // Larger font
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textHint,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
     return Center(
       child: Column(
         children: [
           const SizedBox(height: 48),
           Icon(Icons.bar_chart, size: 64, color: AppColors.textHint),
           const SizedBox(height: 16),
           Text("Belum ada data untuk ditampilkan", style: TextStyle(color: AppColors.textSecondary)),
         ],
       ),
     );
  }

  /// Calculates a nice round number interval for the Y-axis
  double _calculateNiceInterval(double maxDataValue) {
    if (maxDataValue <= 0) return 10;
    
    // Target about 4-6 grid lines
    double roughInterval = maxDataValue / 5;
    
    // Snap to nice round numbers
    if (roughInterval <= 10) return 10;
    if (roughInterval <= 20) return 20;
    if (roughInterval <= 25) return 25;
    if (roughInterval <= 50) return 50;
    if (roughInterval <= 100) return 100;
    
    // For larger numbers, snap to nearest 100 or 500
    double magnitude = 10;
    while (roughInterval >= 100) {
      roughInterval /= 10;
      magnitude *= 10;
    }
    
    // Now roughInterval is between 10 and 100
    if (roughInterval <= 20) return 2.5 * magnitude; // 250, 2500
    if (roughInterval <= 50) return 5.0 * magnitude; // 500, 5000
    return 10.0 * magnitude; // 1000, 10000
  }
}
