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
              TileLayer(
                urlTemplate: 'https://mt1.google.com/vt/lyrs=m&hl=in&x={x}&y={y}&z={z}',
                userAgentPackageName: 'com.scansek.app',
              ),
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
                Builder(builder: (context) {
                  Widget buildMarkerContainer(Widget icon) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: icon,
                    );
                  }

                  return MarkerLayer(
                    markers: [
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
                            color: const Color(0xFF4CAF50),
                            size: 26,
                          ),
                        ),
                      ),
                      if (routePoints.length > 1)
                        Marker(
                          point: routePoints.last,
                          width: 44,
                          height: 44,
                          child: buildMarkerContainer(
                            Icon(
                              Icons.flag_rounded,
                              color: const Color(0xFFE53935),
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
          // Top UI Elements (Back, Title)
          Stack(
            children: [
              // Title (Centered)
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      'Detail $displayType',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              // Back Button
              Positioned(
                top: 50,
                left: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Get.back(),
                  ),
                ),
              ),
            ],
          ),

          // OVERLAY STATS
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
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
                                color: const Color(0xFFFFEBEE),
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
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Terbakar',
                                    style: AppTextStyles.caption.copyWith(
                                      color: Colors.grey[600]!,
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
                        color: Colors.black12,
                      ),
                      // Pace or Speed (right side)
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3E5F5),
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
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    typeStr == 'cycling' ? 'Kecepatan' : 'Pace',
                                    style: AppTextStyles.caption.copyWith(
                                      color: Colors.grey[600]!,
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
                    child: Divider(color: Colors.black12, height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        Icons.timer,
                        '${duration.toStringAsFixed(0)} Min',
                        'Waktu',
                        Colors.black87,
                        Colors.grey[600]!,
                        const Color(0xFF90CAF9), // Biru
                      ),
                      _buildDistanceStatItem(
                        '${distance.toStringAsFixed(2)} KM',
                        'Jarak',
                        Colors.black87,
                        Colors.grey[600]!,
                        const Color(0xFFEF9A9A), // Merah Muda
                      ),
                      if (typeStr != 'cycling')
                        _buildStatItem(
                          Icons.directions_walk,
                          '$steps',
                          'Langkah',
                          Colors.black87,
                          Colors.grey[600]!,
                          const Color(0xFF81C784), // Hijau
                        ),
                    ],
                  ),
                  // Waktu Mulai & Selesai
                  if (activity['startTime'] != null && activity['endTime'] != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Colors.black12, height: 1),
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
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Mulai',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.grey[600]!,
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
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Selesai',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.grey[600]!,
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
            ),
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


}
