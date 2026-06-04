import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:scansek/app/core/theme/app_colors.dart';
import 'package:scansek/app/core/theme/app_text_styles.dart';
import 'package:scansek/app/modules/activity_tracker/controllers/activity_tracker_controller.dart';
import 'package:intl/intl.dart';

class ActivityDetailView extends StatelessWidget {
  final Map<String, dynamic> activity;

  const ActivityDetailView({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ActivityTrackerController>();
    final typeStr = activity['type']?.toString() ?? 'walking';
    final activityTypeData = controller.activityTypes.firstWhere((e) => e['value'] == typeStr, orElse: () => controller.activityTypes.first);
    final displayType = activityTypeData['label'];
    
    final duration = (activity['duration'] as num?)?.toDouble() ?? 0.0;
    final distance = (activity['distance'] as num?)?.toDouble() ?? 0.0;
    final steps = (activity['steps'] as num?)?.toInt() ?? 0;
    final calories = (activity['caloriesBurned'] as num?)?.toDouble() ?? 0.0;
    final pace = (activity['pace'] as num?)?.toDouble() ?? 0.0;
    final speed = (activity['speed'] as num?)?.toDouble() ?? 0.0;
    
    // Format pace as m:ss
    String formattedPace = '0:00';
    if (pace > 0) {
      final totalSeconds = (pace * 60).round();
      final mins = totalSeconds ~/ 60;
      final secs = totalSeconds % 60;
      formattedPace = '$mins:${secs.toString().padLeft(2, '0')}';
    }

    // Parse route points
    final routeData = activity['route'] as List<dynamic>? ?? [];
    List<LatLng> routePoints = [];
    for (var point in routeData) {
      if (point is Map<String, dynamic> && point['lat'] != null && point['lng'] != null) {
        routePoints.add(LatLng(
          (point['lat'] as num).toDouble(),
          (point['lng'] as num).toDouble(),
        ));
      }
    }

    // Determine center and bounds
    LatLng initialCenter = const LatLng(-6.200000, 106.816666);
    if (routePoints.isNotEmpty) {
      initialCenter = routePoints.first;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // MAP
          FlutterMap(
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 16.0,
            ),
            children: [
              Obx(() => TileLayer(
                urlTemplate: controller.selectedMapStyle.value.tileUrl,
                userAgentPackageName: 'com.scansek.app',
              )),
              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: const Color(0xFFFF5722), // Orange Polyline
                      strokeWidth: 6.0,
                      strokeJoin: StrokeJoin.round,
                      strokeCap: StrokeCap.round,
                    ),
                  ],
                ),
              if (routePoints.isNotEmpty)
                Obx(() {
                  final mapStyle = controller.selectedMapStyle.value;
                  Color markerBg;
                  
                  if (mapStyle == MapStyle.dark) {
                    markerBg = const Color(0xFF1E1E1E);
                  } else if (mapStyle == MapStyle.satellite) {
                    markerBg = Colors.white.withOpacity(0.15);
                  } else {
                    markerBg = Colors.white;
                  }
                  
                  Widget buildMarkerContainer(Widget icon) {
                    Widget container = Container(
                      decoration: BoxDecoration(
                        color: markerBg,
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (mapStyle != MapStyle.satellite)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: icon,
                    );
                    
                    if (mapStyle == MapStyle.satellite) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: container,
                        ),
                      );
                    }
                    return container;
                  }

                  return MarkerLayer(
                    markers: [
                      // Start marker — activity-specific icon
                      Marker(
                        point: routePoints.first,
                        width: 44,
                        height: 44,
                        child: buildMarkerContainer(
                          Icon(
                            typeStr == 'cycling'
                              ? Icons.directions_bike
                              : typeStr == 'walking'
                                ? Icons.directions_walk
                                : Icons.directions_run,
                            color: mapStyle == MapStyle.satellite ? Colors.white : const Color(0xFF4CAF50),
                            size: 26,
                          ),
                        ),
                      ),
                      // End marker — checkered flag
                      if (routePoints.length > 1)
                        Marker(
                          point: routePoints.last,
                          width: 44,
                          height: 44,
                          child: buildMarkerContainer(
                            Icon(
                              Icons.flag_rounded,
                              color: mapStyle == MapStyle.satellite ? Colors.white : const Color(0xFFE53935),
                              size: 26,
                            ),
                          ),
                        ),
                    ],
                  );
                }),
            ],
          ),

          // Top UI Elements (Back, Title, Map Style)
          Obx(() {
            final mapStyle = controller.selectedMapStyle.value;
            Color btnBgColor;
            Color btnIconColor;
            Color titleColor;
            
            if (mapStyle == MapStyle.dark) {
              btnBgColor = const Color(0xFF1E1E1E);
              btnIconColor = Colors.white;
              titleColor = Colors.white;
            } else if (mapStyle == MapStyle.satellite) {
              btnBgColor = Colors.white.withOpacity(0.15);
              btnIconColor = Colors.white;
              titleColor = Colors.white;
            } else {
              btnBgColor = Colors.white;
              btnIconColor = Colors.black87;
              titleColor = Colors.black;
            }

            Widget buildFrosted(Widget child, double radius) {
              if (mapStyle == MapStyle.satellite) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(radius),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: child,
                  ),
                );
              }
              return child;
            }

            return Stack(
              children: [
                // Title (Centered)
                Positioned(
                  top: 50,
                  left: 0,
                  right: 0,
                  child: Align(
                    alignment: Alignment.center,
                    child: buildFrosted(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: btnBgColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            if (mapStyle != MapStyle.satellite)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                              ),
                          ],
                        ),
                        child: Text(
                          'Detail $displayType',
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      20,
                    ),
                  ),
                ),
                // Back Button
                Positioned(
                  top: 50,
                  left: 20,
                  child: buildFrosted(
                    Container(
                      decoration: BoxDecoration(
                        color: btnBgColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (mapStyle != MapStyle.satellite)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                            ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: btnIconColor),
                        onPressed: () => Get.back(),
                      ),
                    ),
                    100,
                  ),
                ),
                // Map Style Switcher Button
                Positioned(
                  top: 110,
                  left: 20,
                  child: buildFrosted(
                    Container(
                      decoration: BoxDecoration(
                        color: btnBgColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (mapStyle != MapStyle.satellite)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 12,
                            ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          controller.selectedMapStyle.value.icon,
                          color: mapStyle == MapStyle.satellite ? Colors.white : const Color(0xFF81C784),
                        ),
                        onPressed: () => _showMapStyleDialog(controller),
                      ),
                    ),
                    100,
                  ),
                ),
              ],
            );
          }),

          // OVERLAY STATS
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Obx(() {
              final mapStyle = controller.selectedMapStyle.value;
              Color cardColor;
              Color textColor;
              Color secondaryTextColor;
              Color dividerColor;
              
              if (mapStyle == MapStyle.dark) {
                cardColor = const Color(0xFF1E1E1E);
                textColor = Colors.white;
                secondaryTextColor = Colors.grey[400]!;
                dividerColor = Colors.white24;
              } else if (mapStyle == MapStyle.satellite) {
                cardColor = Colors.white.withOpacity(0.15); // Transparan bening (Kaca)
                textColor = Colors.white;
                secondaryTextColor = Colors.white70;
                dividerColor = Colors.white24;
              } else {
                cardColor = Colors.white;
                textColor = Colors.black87;
                secondaryTextColor = Colors.grey[600]!;
                dividerColor = Colors.black12;
              }

              Widget cardContent = Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    if (mapStyle != MapStyle.satellite)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Row: Calories + Pace/Speed
                    Row(
                      children: [
                        // Calories (left side)
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: mapStyle == MapStyle.light ? const Color(0xFFFFEBEE) : const Color(0xFFFFEBEE).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.whatshot,
                                  color: Color(0xFFFF5722),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${calories.toStringAsFixed(0)} kcal',
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Terbakar',
                                      style: AppTextStyles.caption.copyWith(
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Vertical divider
                        Container(
                          height: 40,
                          width: 1,
                          color: dividerColor,
                        ),
                        // Pace or Speed (right side)
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: mapStyle == MapStyle.light ? const Color(0xFFF3E5F5) : const Color(0xFFF3E5F5).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.speed_rounded,
                                  color: Color(0xFFCE93D8),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      typeStr == 'cycling'
                                        ? '${speed.toStringAsFixed(1)} km/h'
                                        : '$formattedPace min/km',
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      typeStr == 'cycling' ? 'Kecepatan' : 'Pace',
                                      style: AppTextStyles.caption.copyWith(
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: dividerColor, height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          Icons.timer,
                          '${duration.toStringAsFixed(0)} Min',
                          'Waktu',
                          textColor,
                          secondaryTextColor,
                          const Color(0xFF90CAF9), // Biru
                        ),
                        _buildDistanceStatItem(
                          '${distance.toStringAsFixed(2)} KM',
                          'Jarak',
                          textColor,
                          secondaryTextColor,
                          const Color(0xFFEF9A9A), // Merah Muda
                        ),
                        if (typeStr != 'cycling')
                          _buildStatItem(
                            Icons.directions_walk,
                            '$steps',
                            'Langkah',
                            textColor,
                            secondaryTextColor,
                            const Color(0xFF81C784), // Hijau
                          ),
                      ],
                    ),
                    // Waktu Mulai & Selesai
                    if (activity['startTime'] != null && activity['endTime'] != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: dividerColor, height: 1),
                      ),
                      Builder(builder: (context) {
                        DateTime? start;
                        DateTime? end;
                        try {
                          var startTs = activity['startTime'].toString();
                          if (!startTs.endsWith('Z')) startTs += 'Z';
                          var endTs = activity['endTime'].toString();
                          if (!endTs.endsWith('Z')) endTs += 'Z';
                          start = DateTime.parse(startTs).toLocal();
                          end = DateTime.parse(endTs).toLocal();
                        } catch (_) {}
                        if (start == null || end == null) return const SizedBox.shrink();
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Icon(Icons.play_circle_filled, color: Color(0xFF43A047), size: 22),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('HH:mm').format(start),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  'Mulai',
                                  style: AppTextStyles.caption.copyWith(
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Icon(Icons.stop_circle, color: Color(0xFFE53935), size: 22),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('HH:mm').format(end),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  'Selesai',
                                  style: AppTextStyles.caption.copyWith(
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }),
                    ],
                  ],
                ),
              );

              if (mapStyle == MapStyle.satellite) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: cardContent,
                  ),
                );
              }
              
              return cardContent;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color textColor, Color secondaryTextColor, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceStatItem(String value, String label, Color textColor, Color secondaryTextColor, Color color) {
    return Column(
      children: [
        Image.asset(
          'assets/images/card/distance.png',
          width: 24,
          height: 24,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: secondaryTextColor,
          ),
        ),
      ],
    );
  }

  void _showMapStyleDialog(ActivityTrackerController controller) {
    final mapStyle = controller.selectedMapStyle.value;
    Color bgColor = Colors.white;
    Color textColor = Colors.black87;

    if (mapStyle == MapStyle.dark) {
      bgColor = const Color(0xFF1E1E1E);
      textColor = Colors.white;
    } else if (mapStyle == MapStyle.satellite) {
      bgColor = Colors.white.withOpacity(0.15); // Frosted clear glass
      textColor = Colors.white;
    }

    Widget dialogContent = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih Gaya Peta',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 24),
              
              // Light Map Option
              _buildMapStyleOption(
                controller,
                MapStyle.light,
                'Terang (Modern)',
                'Tampilan bersih estetik, cocok untuk siang hari',
                const Color(0xFF81C784),
                textColor,
              ),
              
              const SizedBox(height: 12),
              
              // Dark Map Option
              _buildMapStyleOption(
                controller,
                MapStyle.dark,
                'Gelap (Aesthetic)',
                'Tampilan elegan ala mode gelap, cocok untuk malam hari',
                const Color(0xFF90CAF9),
                textColor,
              ),
              
              const SizedBox(height: 12),
              
              // Satellite Map Option
              _buildMapStyleOption(
                controller,
                MapStyle.satellite,
                'Satelit (Nyata)',
                'Tampilan asli dari satelit dengan label jalan raya',
                const Color(0xFFFFB74D),
                textColor,
              ),
            ],
          ),
      );

    if (mapStyle == MapStyle.satellite) {
      dialogContent = ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: dialogContent,
        ),
      );
    }

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: dialogContent,
      ),
    );
  }

  Widget _buildMapStyleOption(ActivityTrackerController controller, MapStyle style, String label, String description, Color color, Color textColor) {
    return Obx(() {
      final isSelected = controller.selectedMapStyle.value == style;
      return InkWell(
        onTap: () {
          controller.selectedMapStyle.value = style;
          Get.back(); // Close dialog
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.2),
              width: isSelected ? 2.5 : 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? color : textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: color, size: 24),
            ],
          ),
        ),
      );
    });
  }
}
