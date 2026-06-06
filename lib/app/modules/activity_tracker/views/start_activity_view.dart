import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:scansek/app/modules/activity_tracker/controllers/activity_tracker_controller.dart';

class StartActivityView extends GetView<ActivityTrackerController> {
  const StartActivityView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen Map
          Obx(() {
            final position = controller.currentLocation.value;
            final lat = position?.latitude ?? -6.200000;
            final lng = position?.longitude ?? 106.816666;
            
            return controller.isTracking.value && !controller.isCurrentActivityGpsRequired
              ? Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2C3E50), Color(0xFF000000)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935).withOpacity(0.2),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE53935).withOpacity(0.5),
                                blurRadius: 40,
                                spreadRadius: 10,
                              )
                            ]
                          ),
                          child: const Icon(Icons.whatshot, size: 80, color: Color(0xFFE53935)),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          controller.formattedDuration,
                          style: const TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : FlutterMap(
              mapController: controller.flutterMapController,
              options: MapOptions(
                initialCenter: LatLng(lat, lng),
                initialZoom: 17.5,
                minZoom: 5.0,
                maxZoom: 22.0,
              ),
              children: [
                // OpenStreetMap tiles (Static)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.scansek.app',
                  maxZoom: 22,
                  maxNativeZoom: 19,
                  tileProvider: CachedTileProvider(),
                ),
                
                // Route polyline
                if (controller.isTracking.value && controller.routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: controller.routePoints
                            .map((p) => LatLng(p.lat, p.lng))
                            .toList(),
                        color: const Color(0xFF81C784), // Soft green
                        strokeWidth: 5.0,
                      ),
                    ],
                  ),
                
                // Current location marker (ALWAYS SHOW)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(lat, lng),
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF81C784), // Theme Green
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF81C784).withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),

          // Top UI Elements (Back & Map Style)
          // Top UI Elements (Back Button)
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


          // Location Button - Follows bottom sheet with gravity
          Obx(() {
            if (controller.isTracking.value && !controller.isCurrentActivityGpsRequired) {
              return const SizedBox.shrink();
            }
            // Use controller's sheet size for dynamic positioning
            final screenHeight = MediaQuery.of(context).size.height;
            final sheetSize = controller.sheetSize.value;
            final sheetHeight = screenHeight * sheetSize;
            final buttonBottom = sheetHeight + 8; // 8px gap above card
            
            Color btnBgColor = Colors.white;

            Widget locationBtn = Container(
              decoration: BoxDecoration(
                color: btnBgColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: IconButton(
                iconSize: 28,
                icon: const Icon(
                  Icons.my_location, 
                  color: Color(0xFF81C784)
                ),
                onPressed: () {
                  final position = controller.currentLocation.value;
                  if (position != null) {
                    // Smooth animated camera movement (no teleport!)
                    final latTween = Tween<double>(
                      begin: controller.flutterMapController.camera.center.latitude,
                      end: position.latitude,
                    );
                    final lngTween = Tween<double>(
                      begin: controller.flutterMapController.camera.center.longitude,
                      end: position.longitude,
                    );
                    final zoomTween = Tween<double>(
                      begin: controller.flutterMapController.camera.zoom,
                      end: 17.5,
                    );

                    final controller2 = AnimationController(
                      duration: const Duration(milliseconds: 800),
                      vsync: Navigator.of(context),
                    );

                    final animation = CurvedAnimation(
                      parent: controller2,
                      curve: Curves.easeInOut,
                    );

                    animation.addListener(() {
                      controller.flutterMapController.move(
                        LatLng(
                          latTween.evaluate(animation),
                          lngTween.evaluate(animation),
                        ),
                        zoomTween.evaluate(animation),
                      );
                    });
                    controller2.forward().then((_) => controller2.dispose());
                  }
                },
              ),
            );

            // No blur needed

            return Positioned(
              bottom: buttonBottom,
              right: 20,
              child: locationBtn,
            );
          }),

          // Draggable Bottom Sheet
          Obx(() => DraggableScrollableSheet(
            controller: controller.draggableScrollableController,
            initialChildSize: controller.isTracking.value ? 0.15 : 0.28,
            minChildSize: 0.15,
            maxChildSize: 0.32,
            builder: (context, scrollController) {
              return NotificationListener<DraggableScrollableNotification>(
                onNotification: (notification) {
                  // Update sheet size untuk button position
                  controller.sheetSize.value = notification.extent;
                  return true;
                },
                child: Obx(() {
                  Color cardColor = Colors.white;
                  Color textColor = Colors.black87;
                  Color secondaryTextColor = Colors.grey[600]!;
                  Color dividerColor = Colors.black12;
                  Color handleColor = Colors.grey[300]!;

                  Widget sheetContent = Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: handleColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Activity Type (only when tracking)
                    if (controller.isTracking.value)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              controller.currentActivityIcon,
                              color: controller.currentActivityColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              controller.activityTypes.firstWhere((e) => e['value'] == controller.activityType.value, orElse: () => controller.activityTypes.first)['label'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: controller.currentActivityColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Stats Column (New Layout)
                    Obx(() => Column(
                      children: [
                        // Top Row: Calories + Pace/Speed side by side
                        Row(
                          children: [
                            // Calories (left side)
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFEBEE),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.whatshot,
                                      color: Color(0xFFFF5722),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${controller.caloriesBurned.value.toStringAsFixed(0)} kcal',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Terbakar',
                                          style: TextStyle(
                                            fontSize: 12,
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
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3E5F5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.speed_rounded,
                                      color: Color(0xFFCE93D8),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          controller.activityType.value == 'cycling'
                                            ? '${controller.formattedSpeed} km/h'
                                            : '${controller.formattedPace} min/km',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          controller.activityType.value == 'cycling'
                                            ? 'Kecepatan'
                                            : 'Pace',
                                          style: TextStyle(
                                            fontSize: 12,
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
                        // Bottom Row stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatCard(
                              Icons.timer,
                              controller.formattedDuration,
                              'Waktu',
                              textColor,
                              secondaryTextColor,
                              const Color(0xFF90CAF9),
                            ),
                            _buildDistanceStatCard(
                              '${controller.distance.value.toStringAsFixed(2)} KM',
                              'Jarak',
                              textColor,
                              secondaryTextColor,
                            ),
                            if (controller.activityType.value != 'cycling')
                              _buildStatCard(
                                Icons.directions_walk,
                                controller.steps.value.toString(),
                                'Langkah',
                                textColor,
                                secondaryTextColor,
                                const Color(0xFF81C784),
                              ),
                            if (controller.activityType.value == 'cycling')
                              _buildStatCard(
                                Icons.speed_rounded,
                                '${controller.formattedSpeed}',
                                'km/h',
                                textColor,
                                secondaryTextColor,
                                const Color(0xFFCE93D8),
                              ),
                          ],
                        ),
                      ],
                    )),
                    
                    const SizedBox(height: 24),
                    
                    // Start/Stop & Pause Buttons
                    Obx(() {
                      if (!controller.isTracking.value) {
                        return SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => _showActivityTypeDialog(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF81C784), // Soft green
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide.none,
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'START TRACKING',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        );
                      } else {
                        return Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () => controller.togglePause(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: controller.isPaused.value
                                            ? const Color(0xFF81C784) // Green when paused (press to resume)
                                            : const Color(0xFFFFB74D), // Orange when running (press to pause)
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide.none,
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    controller.isPaused.value ? 'LANJUT' : 'JEDA',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () => controller.stopTracking(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF9A9A), // Soft red
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide.none,
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'BERHENTI',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    }),
                  ],
                ));
                
                return sheetContent;
              }),
            );
            },
          )),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color textColor, Color secondaryTextColor, [Color color = Colors.black54]) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: secondaryTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceStatCard(String value, String label, Color textColor, Color secondaryTextColor) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: secondaryTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showActivityTypeDialog() {
    Color bgColor = Colors.white;
    Color textColor = Colors.black87;
    Color subTextColor = Colors.grey[600]!;
    Color handleColor = Colors.grey[300]!;

    Widget sheetContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: handleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Pilih Aktivitas',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pilih olahraga yang sesuai dengan targetmu hari ini.',
              style: TextStyle(
                fontSize: 14,
                color: subTextColor,
              ),
            ),
            const SizedBox(height: 24),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.activityTypes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final activity = controller.activityTypes[index];
                final value = activity['value'] as String;
                
                IconData icon = Icons.directions_run;
                Color color = const Color(0xFF81C784);
                String desc = '';
                
                if (value == 'walking') {
                  icon = Icons.directions_walk;
                  color = const Color(0xFF81C784); // Soft Green
                  desc = 'Santai tapi pasti, cocok untuk pemulihan.';
                } else if (value == 'jogging') {
                  icon = Icons.directions_run;
                  color = const Color(0xFFFFB74D); // Soft Orange
                  desc = 'Kecepatan sedang untuk melatih daya tahan.';
                } else if (value == 'running') {
                  icon = Icons.directions_run;
                  color = const Color(0xFFEF9A9A); // Soft Red/Pink
                  desc = 'Cocok untuk kamu yang lagi turunin berat badan.';
                } else if (value == 'cycling') {
                  icon = Icons.directions_bike;
                  color = const Color(0xFF90CAF9); // Soft Blue
                  desc = 'Bakar kalori asik sambil nikmati udara segar.';
                }
                
                return _buildActivityOption(
                  label: activity['label'],
                  value: value,
                  icon: icon,
                  color: color,
                  description: desc,
                  textColor: textColor,
                  subTextColor: subTextColor,
                  bgColor: bgColor,
                );
              },
            ),
          ],
        ),
      );



    Get.bottomSheet(
      sheetContent,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Important for frosted glass
    );
  }

  Widget _buildActivityOption({
    required String label, 
    required String value, 
    required IconData icon, 
    required Color color, 
    required String description,
    required Color textColor,
    required Color subTextColor,
    required Color bgColor,
  }) {
    return InkWell(
      onTap: () {
        controller.setActivityType(value);
        Get.back(); // Close dialog
        controller.startTracking(); // Start tracking
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor == const Color(0xFF1E1E1E) || bgColor == Colors.white.withOpacity(0.15) 
                 ? color.withOpacity(0.15) 
                 : color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1, // Tipis dan kalem
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
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
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: subTextColor,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: subTextColor),
          ],
        ),
      ),
    );
  }


}

// Custom Tile Provider untuk Caching Map Data (Biar hemat kuota & bisa offline)
class CachedTileProvider extends TileProvider {
  CachedTileProvider();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return CachedNetworkImageProvider(
      getTileUrl(coordinates, options),
    );
  }
}
