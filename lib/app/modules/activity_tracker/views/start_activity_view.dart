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
                // OpenStreetMap tiles (Dynamic based on selected style)
                Obx(() {
                  final style = controller.selectedMapStyle.value;
                  return TileLayer(
                    urlTemplate: style.tileUrl,
                    subdomains: style.subdomains,
                    userAgentPackageName: 'com.scansek.app',
                    maxZoom: 22,
                    maxNativeZoom: 19,
                    tileProvider: CachedTileProvider(),
                  );
                }),
                
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
                          border: Border.all(
                            color: controller.selectedMapStyle.value == MapStyle.satellite
                                ? Colors.transparent
                                : (controller.selectedMapStyle.value == MapStyle.dark
                                    ? const Color(0xFF1E1E1E)
                                    : Colors.white), 
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF81C784).withOpacity(
                                controller.selectedMapStyle.value == MapStyle.satellite ? 0.8 : 0.4
                              ),
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
          Obx(() {
            final mapStyle = controller.selectedMapStyle.value;
            Color btnBgColor;
            Color btnIconColor;
            
            if (mapStyle == MapStyle.dark) {
              btnBgColor = const Color(0xFF1E1E1E);
              btnIconColor = Colors.white;
            } else if (mapStyle == MapStyle.satellite) {
              btnBgColor = Colors.white.withOpacity(0.15);
              btnIconColor = Colors.white;
            } else {
              btnBgColor = Colors.white;
              btnIconColor = Colors.black87;
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
                // Floating Back Button (Top-left)
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

                // Map Style Switcher Button (Below back button) - Hide if GPS not required
                if (!(controller.isTracking.value && !controller.isCurrentActivityGpsRequired))
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
                          onPressed: () => _showMapStyleDialog(),
                        ),
                      ),
                      100,
                    ),
                  ),
              ],
            );
          }),


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
            
            final mapStyle = controller.selectedMapStyle.value;
            Color btnBgColor;
            
            if (mapStyle == MapStyle.dark) {
              btnBgColor = const Color(0xFF1E1E1E);
            } else if (mapStyle == MapStyle.satellite) {
              btnBgColor = Colors.white.withOpacity(0.15);
            } else {
              btnBgColor = Colors.white;
            }

            Widget locationBtn = Container(
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
                iconSize: 28,
                icon: Icon(
                  Icons.my_location, 
                  color: mapStyle == MapStyle.satellite ? Colors.white : const Color(0xFF81C784)
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

            if (mapStyle == MapStyle.satellite) {
              locationBtn = ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: locationBtn,
                ),
              );
            }

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
                  final mapStyle = controller.selectedMapStyle.value;
                  Color cardColor;
                  Color textColor;
                  Color secondaryTextColor;
                  Color dividerColor;
                  Color handleColor;
                  
                  if (mapStyle == MapStyle.dark) {
                    cardColor = const Color(0xFF1E1E1E);
                    textColor = Colors.white;
                    secondaryTextColor = Colors.grey[400]!;
                    dividerColor = Colors.white24;
                    handleColor = Colors.grey[700]!;
                  } else if (mapStyle == MapStyle.satellite) {
                    cardColor = Colors.white.withOpacity(0.15); // Frosted clear glass
                    textColor = Colors.white;
                    secondaryTextColor = Colors.white70;
                    dividerColor = Colors.white24;
                    handleColor = Colors.white54;
                  } else {
                    cardColor = Colors.white;
                    textColor = Colors.black87;
                    secondaryTextColor = Colors.grey[600]!;
                    dividerColor = Colors.black12;
                    handleColor = Colors.grey[300]!;
                  }

                  Widget sheetContent = Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [
                          if (mapStyle != MapStyle.satellite)
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
                                      color: mapStyle == MapStyle.light ? const Color(0xFFFFEBEE) : const Color(0xFFFFEBEE).withOpacity(0.15),
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
                                      color: mapStyle == MapStyle.light ? const Color(0xFFF3E5F5) : const Color(0xFFF3E5F5).withOpacity(0.15),
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
                              backgroundColor: mapStyle == MapStyle.satellite 
                                  ? Colors.white.withOpacity(0.25) 
                                  : const Color(0xFF81C784), // Soft green
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: mapStyle == MapStyle.satellite 
                                    ? const BorderSide(color: Colors.white, width: 1.5)
                                    : BorderSide.none,
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
                                    backgroundColor: mapStyle == MapStyle.satellite
                                        ? Colors.white.withOpacity(0.25)
                                        : (controller.isPaused.value
                                            ? const Color(0xFF81C784) // Green when paused (press to resume)
                                            : const Color(0xFFFFB74D)), // Orange when running (press to pause)
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: mapStyle == MapStyle.satellite 
                                          ? const BorderSide(color: Colors.white, width: 1.5)
                                          : BorderSide.none,
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
                                    backgroundColor: mapStyle == MapStyle.satellite
                                        ? Colors.white.withOpacity(0.25)
                                        : const Color(0xFFEF9A9A), // Soft red
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: mapStyle == MapStyle.satellite 
                                          ? const BorderSide(color: Colors.white, width: 1.5)
                                          : BorderSide.none,
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
                
                if (mapStyle == MapStyle.satellite) {
                  return ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: sheetContent,
                    ),
                  );
                }
                
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
    final mapStyle = controller.selectedMapStyle.value;
    Color bgColor = Colors.white;
    Color textColor = Colors.black87;
    Color subTextColor = Colors.grey[600]!;
    Color handleColor = Colors.grey[300]!;

    if (mapStyle == MapStyle.dark) {
      bgColor = const Color(0xFF1E1E1E);
      textColor = Colors.white;
      subTextColor = Colors.grey[400]!;
      handleColor = Colors.grey[700]!;
    } else if (mapStyle == MapStyle.satellite) {
      bgColor = Colors.white.withOpacity(0.15); // Frosted clear glass
      textColor = Colors.white;
      subTextColor = Colors.white70;
      handleColor = Colors.white54;
    }

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

    if (mapStyle == MapStyle.satellite) {
      sheetContent = ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: sheetContent,
        ),
      );
    }

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

  void _showMapStyleDialog() {
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
                MapStyle.light,
                'Terang (Modern)',
                'Tampilan bersih estetik, cocok untuk siang hari',
                const Color(0xFF81C784),
                textColor,
              ),
              
              const SizedBox(height: 12),
              
              // Dark Map Option
              _buildMapStyleOption(
                MapStyle.dark,
                'Gelap (Aesthetic)',
                'Tampilan elegan ala mode gelap, cocok untuk malam hari',
                const Color(0xFF90CAF9),
                textColor,
              ),
              
              const SizedBox(height: 12),
              
              // Satellite Map Option
              _buildMapStyleOption(
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

  Widget _buildMapStyleOption(MapStyle style, String label, String description, Color color, Color textColor) {
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
