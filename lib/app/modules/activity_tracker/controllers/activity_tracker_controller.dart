import 'dart:ui';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:pedometer/pedometer.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:scansek/app/modules/activity_tracker/views/activity_detail_view.dart';
import 'package:scansek/app/data/models/route_point_model.dart';
import 'package:scansek/app/data/providers/api/api_client.dart';
import 'package:scansek/app/data/providers/api/api_endpoints.dart';
import 'package:scansek/app/data/providers/api/network_exception.dart';
import 'package:scansek/app/data/providers/local/storage_service.dart';
import 'package:scansek/app/widgets/states/error_state.dart';
import 'package:scansek/app/widgets/snackbars/snackbar_designs.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scansek/app/services/notification_service.dart';
import 'package:scansek/app/services/smartwatch_sync_service.dart';
import 'package:scansek/app/modules/activity_tracker/views/indoor_activity_detail_view.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

// Map Style Options
enum MapStyle {
  light,
  dark,
  satellite,
}

extension MapStyleExtension on MapStyle {
  String get name {
    switch (this) {
      case MapStyle.light:
        return 'Terang (Modern)';
      case MapStyle.dark:
        return 'Gelap (Aesthetic)';
      case MapStyle.satellite:
        return 'Satelit (Nyata)';
    }
  }
  
  String get tileUrl {
    switch (this) {
      case MapStyle.light:
        return 'https://mt1.google.com/vt/lyrs=m&hl=in&x={x}&y={y}&z={z}';
      case MapStyle.dark:
        // Night map style derived from Google Maps custom styling (Encoded)
        return 'https://mt1.google.com/vt/lyrs=m&hl=in&x={x}&y={y}&z={z}&apistyle=s.t%3A1%7Cs.e%3Ag%7Cp.c%3A%23ff242f3e%2Cs.t%3A2%7Cs.e%3Ag.f%7Cp.c%3A%23ff746855%2Cs.t%3A2%7Cs.e%3Al.t.f%7Cp.c%3A%23ffd59563%2Cs.t%3A3%7Cs.e%3Ag%7Cp.c%3A%23ff242f3e%2Cs.t%3A3%7Cs.e%3Al.t.f%7Cp.c%3A%23ff746855%2Cs.t%3A3%7Cs.e%3Al.t.s%7Cp.c%3A%23ff242f3e%2Cs.t%3A4%7Cs.e%3Ag%7Cp.c%3A%23ff242f3e%2Cs.t%3A5%7Cs.e%3Ag.f%7Cp.c%3A%23ff38414e%2Cs.t%3A5%7Cs.e%3Ag.s%7Cp.c%3A%23ff212a37%2Cs.t%3A5%7Cs.e%3Al.t.f%7Cp.c%3A%23ff9ca5b3%2Cs.t%3A5%7Cs.e%3Al.t.s%7Cp.c%3A%23ff1f2835%2Cs.t%3A6%7Cs.e%3Ag%7Cp.c%3A%23ff2c3646%2Cs.t%3A6%7Cs.e%3Al.t.f%7Cp.c%3A%23ff8a9097%2Cs.t%3A6%7Cs.e%3Al.t.s%7Cp.c%3A%23ff2c3646';
      case MapStyle.satellite:
        // Hybrid mode (Satellite + Labels/Roads)
        return 'https://mt1.google.com/vt/lyrs=y&hl=in&x={x}&y={y}&z={z}';
    }
  }
  
  List<String> get subdomains {
    return ['a', 'b', 'c', 'd'];
  }
  
  IconData get icon {
    switch (this) {
      case MapStyle.light:
        return Icons.wb_sunny;
      case MapStyle.dark:
        return Icons.nights_stay;
      case MapStyle.satellite:
        return Icons.satellite_alt;
    }
  }
}



class ActivityTrackerController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();

  // Observable states
  final RxBool isLoading = false.obs;
  final RxBool isTracking = false.obs;
  final RxBool isPaused = false.obs;
  
  // Date selection for history view
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxList<Map<String, dynamic>> activitiesForDate = <Map<String, dynamic>>[].obs;
  
  // Tooltip state for progress bar
  final Rx<int?> selectedLayer = Rx<int?>(null);
  
  // Consumed calories for historical dates (for UI donut chart)
  final RxDouble consumedCaloriesForDate = 0.0.obs;
  
  // Activity data for live tracking (Part 2)
  final Rx<String> activityType = 'walking'.obs;
  final RxDouble duration = 0.0.obs;
  final RxDouble distance = 0.0.obs;
  final RxDouble caloriesBurned = 0.0.obs;
  final RxInt steps = 0.obs;
  final RxDouble currentPace = 0.0.obs; // min/km (for walking/jogging/running)
  final RxDouble currentSpeed = 0.0.obs; // km/h (for cycling)
  final Rx<DateTime?> startTime = Rx<DateTime?>(null);
  final Rx<DateTime?> endTime = Rx<DateTime?>(null);
  
  // GPS tracking
  final Rx<Position?> currentLocation = Rx<Position?>(null);
  final RxList<RoutePoint> routePoints = <RoutePoint>[].obs;
  
  // Tracking subscriptions
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<StepCount>? _stepCountStream;
  Timer? _durationTimer;
  Timer? _notificationTimer; // Updates the ongoing notification every 3s
  
  int? _initialStepCount;
  final RxDouble userWeight = 70.0.obs; // Default 70kg, will be updated from profile
  final NotificationService _notificationService = NotificationService();

  
  // Calendar scroll controller
  final ScrollController calendarScrollController = ScrollController();
  
  // Map controller for live tracking (flutter_map)
  final MapController flutterMapController = MapController();
  
  // DraggableScrollableSheet controller for dynamic button positioning
  final DraggableScrollableController draggableScrollableController = DraggableScrollableController();
  
  // Smartwatch Sync state
  final RxBool isSyncingSmartwatch = false.obs;
  
  // Sheet size tracker untuk gravity button
  final RxDouble sheetSize = 0.28.obs; // Initial size
  
  // Map style selection
  final Rx<MapStyle> selectedMapStyle = MapStyle.light.obs;



  final List<Map<String, dynamic>> activityTypes = [
    {
      'value': 'walking',
      'label': 'Jalan',
      'met': 3.5,
      'isGpsRequired': true,
    },
    {
      'value': 'jogging',
      'label': 'Jogging',
      'met': 7.0,
      'isGpsRequired': true,
    },
    {
      'value': 'running',
      'label': 'Lari',
      'met': 8.0,
      'isGpsRequired': true,
    },
    {
      'value': 'cycling',
      'label': 'Sepeda',
      'met': 7.5,
      'isGpsRequired': true,
    },
  ];
  
  bool get isCurrentActivityGpsRequired {
    final activity = activityTypes.firstWhere((e) => e['value'] == activityType.value, orElse: () => activityTypes.first);
    return activity['isGpsRequired'] == true;
  }
  
  IconData get currentActivityIcon => getActivityIcon(activityType.value);

  Color get currentActivityColor => getActivityColor(activityType.value);

  /// Get icon for any activity type
  static IconData getActivityIcon(String type) {
    switch (type) {
      case 'walking': return Icons.directions_walk;
      case 'jogging': case 'running': return Icons.directions_run;
      case 'cycling': return Icons.directions_bike;
      case 'hiking': return Icons.terrain;
      case 'swimming': return Icons.pool;
      case 'yoga': return Icons.self_improvement;
      case 'pilates': return Icons.accessibility_new;
      case 'weightlifting': return Icons.fitness_center;
      case 'jump_rope': return Icons.sports;
      case 'rowing': return Icons.rowing;
      case 'elliptical': return Icons.fitness_center;
      case 'stair_climbing': return Icons.stairs;
      case 'calisthenics': return Icons.sports_gymnastics;
      case 'badminton': return Icons.sports_tennis;
      case 'basketball': return Icons.sports_basketball;
      case 'soccer': return Icons.sports_soccer;
      case 'table_tennis': return Icons.sports_tennis;
      case 'tennis': return Icons.sports_tennis;
      case 'martial_arts': return Icons.sports_martial_arts;
      case 'dancing': return Icons.music_note;
      case 'volleyball': return Icons.sports_volleyball;
      case 'treadmill': return Icons.directions_run;
      case 'daily_summary': return Icons.accessibility_new;
      case 'other': return Icons.watch;
      default: return Icons.watch;
    }
  }

  /// Get color for any activity type
  static Color getActivityColor(String type) {
    switch (type) {
      case 'walking': return const Color(0xFF81C784);
      case 'jogging': return const Color(0xFFFFB74D);
      case 'running': return const Color(0xFFEF9A9A);
      case 'cycling': return const Color(0xFF90CAF9);
      case 'hiking': return const Color(0xFFA5D6A7);
      case 'swimming': return const Color(0xFF80DEEA);
      case 'yoga': return const Color(0xFFCE93D8);
      case 'pilates': return const Color(0xFFB39DDB);
      case 'weightlifting': return const Color(0xFFFF8A65);
      case 'jump_rope': return const Color(0xFFFFF176);
      case 'rowing': return const Color(0xFF4FC3F7);
      case 'badminton': case 'tennis': case 'table_tennis': return const Color(0xFF4DD0E1);
      case 'basketball': return const Color(0xFFFFAB91);
      case 'soccer': return const Color(0xFFA5D6A7);
      case 'martial_arts': return const Color(0xFFEF9A9A);
      case 'dancing': return const Color(0xFFF48FB1);
      case 'volleyball': return const Color(0xFFFFCC80);
      case 'daily_summary': return Colors.blueGrey;
      default: return const Color(0xFF81C784);
    }
  }

  // Burn Goal
  final RxDouble dailyBurnGoal = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserGoal(); // Load goal from storage
    
    // Fetch activities for today on init
    fetchActivitiesForDate(selectedDate.value);
    
    // Fetch user profile to get real weight for calorie calculation
    fetchUserProfile();
    
    // Get current location for map
    getCurrentLocation();
    
    // Center calendar on today after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }
  
  Future<void> loadUserGoal() async {
    try {
      final StorageService storage = Get.find<StorageService>();
      final userData = await storage.getUserData();
      if (userData != null && userData['goals'] != null) {
        final goals = userData['goals'];
        final burnGoal = (double.tryParse(goals['burn']?.toString() ?? '400') ?? 400.0);
        dailyBurnGoal.value = burnGoal;
        print('✅ Activity burn goal loaded: $burnGoal');
      }
    } catch (e) {
      print('❌ Error loading burn goal: $e');
    }
  }

  @override
  void onClose() {
    _cleanup();
    calendarScrollController.dispose();
    super.onClose();
  }
  
  /// Scroll calendar to center on today
  void _scrollToToday() {
    if (calendarScrollController.hasClients) {
      // Each date item is 68px wide (60px + 8px margin)
      // Center position is 7 items in (today is at index 7 of 14-day range)
      final centerPosition = 7 * 68.0 - (Get.width / 2) + 34;
      calendarScrollController.animateTo(
        centerPosition.clamp(0.0, calendarScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Select date and fetch activities
  void selectDate(DateTime date) {
    selectedDate.value = date;
    fetchActivitiesForDate(date);
  }

  /// Fetch activities for selected date
  Future<void> fetchActivitiesForDate(DateTime date) async {
    isLoading.value = true;
    
    try {
      // Format date for API
      final startDate = DateFormat('yyyy-MM-dd').format(date);
      final endDate = startDate; // Same day
      
      final response = await _apiClient.get(
        ApiEndpoints.activityHistory,
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && data['items'] != null) {
          activitiesForDate.value = List<Map<String, dynamic>>.from(
            (data['items'] as List).map((item) => item as Map<String, dynamic>),
          );
        } else {
          activitiesForDate.clear();
        }
      }

      // Fetch consumed calories for the selected date
      try {
        final statsResponse = await _apiClient.get(
          ApiEndpoints.getWeeklyStats,
          queryParameters: {
            'startDate': startDate,
            'endDate': endDate,
          },
        );
        if (statsResponse.statusCode == 200) {
          final statsData = statsResponse.data['data'] as List?;
          if (statsData != null && statsData.isNotEmpty) {
             consumedCaloriesForDate.value = (statsData[0]['calories'] as num?)?.toDouble() ?? 0.0;
          } else {
             consumedCaloriesForDate.value = 0.0;
          }
        }
      } catch (e) {
        print('Error fetching stats for date: $e');
        consumedCaloriesForDate.value = 0.0;
      }
    } on NetworkException catch (e) {
      ErrorSnackbar.show(Get.context!, e.message);
      activitiesForDate.clear();
    } catch (e) {
      ElegantSnackbar.error(Get.context, 'Waduh, gagal narik data nih');
      activitiesForDate.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Show activity detail — outdoor goes to map view, indoor goes to indoor detail
  void showActivityDetail(Map<String, dynamic> activity) {
    final category = activity['category'] as String? ?? 'outdoor';
    
    if (category == 'daily_summary' || activity['type'] == 'daily_summary') {
      // Show informational dialog for daily summary dummy activity
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.accessibility_new, size: 40, color: Colors.blueGrey),
              ),
              const SizedBox(height: 16),
              const Text(
                'Gerak Aktif Lainnya',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Ini adalah akumulasi total kalori terbakar dan langkah kakimu hari ini yang terjadi di luar sesi olahraga terstruktur (misal: jalan ke warung, aktivitas rumah, dll).',
                style: TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.orange),
                      const SizedBox(height: 4),
                      Text('${activity['caloriesBurned'] ?? 0} kcal', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    children: [
                      const Icon(Icons.directions_walk, color: Colors.green),
                      const SizedBox(height: 4),
                      Text('${activity['steps'] ?? 0} lkh', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Tutup', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        )
      );
      return;
    }
    
    if (category == 'outdoor') {
      // Outdoor: has route/distance → go to map view
      Get.to(() => ActivityDetailView(activity: activity));
    } else {
      // Indoor → go to indoor detail view
      Get.to(() => IndoorActivityDetailView(activity: activity));
    }
  }  // ========================================
  // EDIT ACTIVITY
  // ========================================

  Future<void> editActivityType(Map<String, dynamic> activity, String newType) async {
    final activityId = activity['id'] ?? activity['_id'];
    if (activityId == null) return;

    try {
      // Optimistic update
      final index = activitiesForDate.indexWhere((a) => (a['id'] ?? a['_id']) == activityId);
      if (index != -1) {
        final updatedActivity = Map<String, dynamic>.from(activitiesForDate[index]);
        updatedActivity['type'] = newType;
        activitiesForDate[index] = updatedActivity;
      }

      // Backend update
      final response = await _apiClient.put(
        '${ApiEndpoints.editActivity}/$activityId',
        data: {'type': newType},
      );

      if (response.statusCode == 200) {
        if (Get.context != null) {
          ElegantSnackbar.success(Get.context!, 'Nama aktivitas berhasil diubah!');
        }
      }
    } catch (e) {
      print('Error editing activity type: $e');
      if (Get.context != null) {
        ElegantSnackbar.error(Get.context!, 'Gagal mengubah nama aktivitas');
      }
      // Revert if failed
      await fetchActivitiesForDate(selectedDate.value);
    }
  }

  // ========================================
  // LIVE TRACKING METHODS
  // ========================================
  
  String get formattedDuration {
    final totalSeconds = duration.value.toInt();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> startTracking() async {
    try {
      // Check location services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar(
          'GPS Tidak Aktif',
          'Aktifkan GPS untuk tracking aktivitas',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar(
            'Izin Ditolak',
            'Izinkan akses lokasi untuk tracking',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.dialog(
          AlertDialog(
            title: const Text('Izin Lokasi Diperlukan'),
            content: const Text('Buka pengaturan untuk mengaktifkan akses lokasi'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Geolocator.openAppSettings();
                  Get.back();
                },
                child: const Text('Buka Pengaturan'),
              ),
            ],
          ),
        );
        return;
      }

  final gpsRequired = isCurrentActivityGpsRequired;

    // Check and request Activity Recognition permission (for pedometer on Android 10+)
    if (gpsRequired) {
    final activityPermission = await Permission.activityRecognition.status;
    if (activityPermission.isDenied || activityPermission.isPermanentlyDenied) {
      final result = await Permission.activityRecognition.request();
      if (result.isDenied) {
        Get.snackbar(
          'Izin Aktivitas Diperlukan',
          'Izinkan akses aktivitas untuk menghitung langkah',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        // Continue anyway, GPS tracking will still work
      } else if (result.isPermanentlyDenied) {
        Get.dialog(
          AlertDialog(
            title: const Text('Izin Aktivitas Diperlukan'),
            content: const Text('Buka pengaturan untuk mengaktifkan akses aktivitas fisik (pedometer)'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Nanti'),
              ),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Get.back();
                },
                child: const Text('Buka Pengaturan'),
              ),
            ],
          ),
        );
        // Continue anyway, GPS tracking will still work
      }
    }
    } // End of if (gpsRequired)

      // Reset tracking state
      isTracking.value = true;
      sheetSize.value = 0.15; // Update sheet size for button position
      duration.value = 0.0;
      distance.value = 0.0;
      caloriesBurned.value = 0.0;
      steps.value = 0;
      routePoints.clear();
      startTime.value = DateTime.now();
      _initialStepCount = null;

      // Start duration timer
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!isPaused.value) {
          duration.value += 1.0;
          _updateCalories();
        }
      });

      // Start GPS tracking
      if (gpsRequired) {
        LocationSettings locationSettings;
        if (defaultTargetPlatform == TargetPlatform.android) {
          locationSettings = AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
            forceLocationManager: true,
            intervalDuration: const Duration(seconds: 3),
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationText: "Merekam rute aktivitas kamu di background",
              notificationTitle: "ScanSek - Aktivitas Berjalan",
              enableWakeLock: true,
            ),
          );
        } else {
          locationSettings = const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          );
        }

        _positionStream = Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position position) {
          if (!isPaused.value) {
            _handlePositionUpdate(position);
          }
        });

        // Start pedometer
        if (activityType.value != 'cycling') {
          try {
            _stepCountStream = Pedometer.stepCountStream.listen(
              (StepCount stepCount) {
                if (_initialStepCount == null) {
                  _initialStepCount = stepCount.steps;
                }
                if (!isPaused.value) {
                  steps.value = stepCount.steps - _initialStepCount!;
                  _updateCalories();
                }
              },
              onError: (error) {
                print('Pedometer error: $error');
              },
            );
          } catch (e) {
            print('Pedometer not available: $e');
          }
        }
      }

      final activityTypeData = activityTypes.firstWhere((e) => e['value'] == activityType.value, orElse: () => activityTypes.first);
      final displayType = activityTypeData['label'];
      
      // === BACKGROUND TRACKING ===
      // 1. Keep screen/CPU alive
      WakelockPlus.enable();
      
      // 2. Show persistent notification
      await _notificationService.showTrackingNotification(
        activityLabel: displayType,
        duration: formattedDuration,
        distance: distance.value.toStringAsFixed(2),
      );
      
      // 3. Update notification every 3 seconds
      _notificationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (isTracking.value) {
          _notificationService.showTrackingNotification(
            activityLabel: displayType,
            duration: formattedDuration,
            distance: distance.value.toStringAsFixed(2),
            isPaused: isPaused.value,
          );
        }
      });

      ElegantSnackbar.info(
        Get.context, 
        'Aktivitas $displayType sedang direkam'
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memulai tracking: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      isTracking.value = false;
    }
  }

  Future<void> stopTracking() async {
    try {
      if (!isTracking.value) return;

      // Stop tracking
      isTracking.value = false;
      isPaused.value = false;
      sheetSize.value = 0.28; // Reset sheet size for button position
      endTime.value = DateTime.now();
      _cleanup();

    final mapStyle = selectedMapStyle.value;
    Color bgColor = Colors.white;
    Color textColor = Colors.black87;
    Color subTextColor = Colors.black54;

    if (mapStyle == MapStyle.dark) {
      bgColor = const Color(0xFF1E1E1E);
      textColor = Colors.white;
      subTextColor = Colors.grey[400]!;
    } else if (mapStyle == MapStyle.satellite) {
      bgColor = Colors.white.withOpacity(0.15); // Frosted clear glass
      textColor = Colors.white;
      subTextColor = Colors.white70;
    }

    Widget dialogContent = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF81C784).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pause_circle_rounded,
                  size: 48,
                  color: Color(0xFF81C784),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Simpan Aktivitas?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 24),
              
              // Stats Layout (Sama persis dengan bottom sheet)
              Column(
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
                                    '${caloriesBurned.value.toStringAsFixed(0)} kcal',
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
                                      color: subTextColor,
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
                        color: mapStyle == MapStyle.light ? Colors.black12 : Colors.white24,
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
                                    activityType.value == 'cycling'
                                      ? '$formattedSpeed km/h'
                                      : '$formattedPace min/km',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    activityType.value == 'cycling'
                                      ? 'Kecepatan'
                                      : 'Pace',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: subTextColor,
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
                    child: Divider(color: mapStyle == MapStyle.light ? Colors.black12 : Colors.white24, height: 1),
                  ),
                  // Bottom Row stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSimpleStatCard(
                        Icons.timer,
                        formattedDuration,
                        'Waktu',
                        const Color(0xFF90CAF9),
                        textColor,
                        subTextColor,
                      ),
                      _buildSimpleStatCard(
                        Icons.straighten,
                        '${distance.value.toStringAsFixed(2)} KM',
                        'Jarak',
                        const Color(0xFFEF9A9A),
                        textColor,
                        subTextColor,
                      ),
                      if (activityType.value != 'cycling')
                        _buildSimpleStatCard(
                          Icons.directions_walk,
                          steps.value.toString(),
                          'Langkah',
                          const Color(0xFF81C784),
                          textColor,
                          subTextColor,
                        ),
                      if (activityType.value == 'cycling')
                        _buildSimpleStatCard(
                          Icons.speed_rounded,
                          formattedSpeed,
                          'km/h',
                          const Color(0xFFCE93D8),
                          textColor,
                          subTextColor,
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: subTextColor.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Buang',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: subTextColor,
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
                        backgroundColor: const Color(0xFF81C784),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Simpan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
    );

    if (mapStyle == MapStyle.satellite) {
      dialogContent = ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: dialogContent,
        ),
      );
    }

    final confirm = await Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: dialogContent,
      ),
    );

    if (confirm == true) {
      await _saveActivity();
    } else if (confirm == false) {
      ElegantSnackbar.info(
        Get.context, 
        'Aktivitas dibuang dan tidak disimpan.'
      );
    }

    // Reset state so next tracking starts fresh
    resetStats();

      // Navigate back
      Get.back();
    } catch (e) {
      ElegantSnackbar.error(
        Get.context,
        'Gagal memulai tracking: $e',
      );
    }
  }

  void resetStats() {
    duration.value = 0.0;
    distance.value = 0.0;
    caloriesBurned.value = 0.0;
    steps.value = 0;
    currentPace.value = 0.0;
    currentSpeed.value = 0.0;
    routePoints.clear();
    isPaused.value = false;
    isTracking.value = false;
  }

  void _handlePositionUpdate(Position position) {
    currentLocation.value = position;

    // Update map camera (flutter_map)
    if (isTracking.value) {
      try {
        flutterMapController.move(
          LatLng(position.latitude, position.longitude),
          17.5, // zoom level
        );
      } catch (e) {
        // Map controller might not be ready
      }
    }

    // Add to route points
    final routePoint = RoutePoint(
      lat: position.latitude,
      lng: position.longitude,
      timestamp: DateTime.now(),
    );
    routePoints.add(routePoint);

    // Calculate distance
    if (routePoints.length > 1) {
      final lastPoint = routePoints[routePoints.length - 2];
      final dist = _distanceBetween(
        lastPoint.lat,
        lastPoint.lng,
        routePoint.lat,
        routePoint.lng,
      );
      distance.value += dist;
    }
  }

  double _distanceBetween(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371; // Earth radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
            sin(dLng / 2) * sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  void _updateCalories() {
    // Update Pace & Speed first so we can use currentSpeed for ACSM equations
    _updatePaceAndSpeed();

    // Get baseline MET value based on activity type
    final activity = activityTypes.firstWhere((e) => e['value'] == activityType.value, orElse: () => activityTypes.first);
    double met = activity['met'] as double;
    
    // Calculate Dynamic MET using ACSM Equations for GPS activities
    if (currentSpeed.value > 0) {
      final speedKmh = currentSpeed.value;
      final speedMMin = speedKmh * 16.6667; // Convert km/h to m/min
      
      if (activityType.value == 'walking') {
        // ACSM Walking: VO2 = (0.1 * speed) + 3.5
        final vo2 = (0.1 * speedMMin) + 3.5;
        met = vo2 / 3.5;
      } else if (activityType.value == 'jogging' || activityType.value == 'running') {
        // ACSM Running: VO2 = (0.2 * speed) + 3.5
        final vo2 = (0.2 * speedMMin) + 3.5;
        met = vo2 / 3.5;
      } else if (activityType.value == 'cycling') {
        // Dynamic cycling MET based on Compendium speed zones
        if (speedKmh < 16.0) met = 4.0;
        else if (speedKmh <= 19.1) met = 6.8;
        else if (speedKmh <= 22.4) met = 8.0;
        else if (speedKmh <= 25.6) met = 10.0;
        else met = 12.0;
      }
    }

    // Calories = MET * 1.05 * weight(kg) * duration(hours)
    // Berdasarkan PDF: kcal/min = MET * 0.0175 * Berat. Jadi kcal/jam = MET * 0.0175 * 60 * Berat = MET * 1.05 * Berat
    final durationHours = duration.value / 3600;
    caloriesBurned.value = met * 1.05 * userWeight.value * durationHours;
  }

  void _updatePaceAndSpeed() {
    if (distance.value > 0.01) { // Minimum 10m to avoid division by zero
      // Pace = duration(minutes) / distance(km)
      final durationMinutes = duration.value / 60;
      currentPace.value = durationMinutes / distance.value;
      
      // Speed = distance(km) / duration(hours)
      final durationHours = duration.value / 3600;
      currentSpeed.value = distance.value / durationHours;
    } else {
      currentPace.value = 0.0;
      currentSpeed.value = 0.0;
    }
  }

  String get formattedPace {
    if (currentPace.value <= 0) return '0:00';
    final totalSeconds = (currentPace.value * 60).round();
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  String get formattedSpeed {
    return currentSpeed.value.toStringAsFixed(1);
  }

  void togglePause() {
    isPaused.value = !isPaused.value;
    
    // Update notification immediately to reflect pause/resume state
    if (isTracking.value) {
      final activityTypeData = activityTypes.firstWhere((e) => e['value'] == activityType.value, orElse: () => activityTypes.first);
      _notificationService.showTrackingNotification(
        activityLabel: activityTypeData['label'],
        duration: formattedDuration,
        distance: distance.value.toStringAsFixed(2),
        isPaused: isPaused.value,
      );
    }
  }

  Future<void> _saveActivity() async {
    try {
      // Prepare route data (max 500 points)
      final routeData = routePoints.length > 500
          ? routePoints.sublist(routePoints.length - 500)
          : routePoints;

      final payload = <String, dynamic>{
        'type': activityType.value,
        'duration': duration.value / 60, // Convert to minutes
        'distance': distance.value,
        'caloriesBurned': caloriesBurned.value,
        'steps': steps.value,
        'pace': currentPace.value,
        'speed': currentSpeed.value,
        'startTime': startTime.value?.toUtc().toIso8601String(),
        'endTime': endTime.value?.toUtc().toIso8601String(),
      };

      if (routeData.isNotEmpty) {
        payload['route'] = routeData.map((p) => p.toJson()).toList();
      }

      final response = await _apiClient.post(
        ApiEndpoints.addActivity,
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ElegantSnackbar.success(
          Get.context,
          'Aktivitas berhasil disimpan'
        );
        
        // Refresh activity history
        fetchActivitiesForDate(selectedDate.value);
        
        // Simpan timestamp & refresh notif
        await StorageService().setLastActivityInputTime(DateTime.now());
        await NotificationService().refreshSystemNotifications();
      }
    } on NetworkException catch (e) {
      ErrorSnackbar.show(Get.context!, e.message);
    } catch (e) {
      ElegantSnackbar.error(Get.context, 'Gagal menyimpan aktivitas nih');
    }
  }

  void _cleanup() {
    _positionStream?.cancel();
    _stepCountStream?.cancel();
    _durationTimer?.cancel();
    _notificationTimer?.cancel();
    _notificationTimer = null;
    
    // Cancel tracking notification & release wakelock
    _notificationService.cancelTrackingNotification();
    WakelockPlus.disable();
  }

  // Get current location for map (without starting tracking)
  Future<void> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permission denied forever');
        Get.dialog(
          AlertDialog(
            title: const Text('Izin Lokasi Diperlukan'),
            content: const Text('Fitur Map membutuhkan akses lokasi. Supaya bisa ngelacak rute, tolong izinkan akses GPS di pengaturan ya bro.'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Geolocator.openAppSettings();
                  Get.back();
                },
                child: const Text('Buka Pengaturan'),
              ),
            ],
          ),
        );
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      currentLocation.value = position;
      
      // Move map to current location
      flutterMapController.move(
        LatLng(position.latitude, position.longitude),
        17.5,
      );
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  // Fetch user profile to get real weight for calorie calculation
  Future<void> fetchUserProfile() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.getProfile);
      
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null && data['weight'] != null) {
          userWeight.value = (data['weight'] as num).toDouble();
          print('✅ User weight updated: ${userWeight.value} kg');
        }
      }
    } catch (e) {
      print('⚠️ Failed to fetch user profile, using default weight (70kg): $e');
      // Keep default weight 70kg if fetch fails
    }
  }

  /// Sync workouts from smartwatch via Health Connect
  Future<int> syncSmartwatch() async {
    if (isSyncingSmartwatch.value) return 0;
    
    isSyncingSmartwatch.value = true;
    
    try {
      final syncService = SmartwatchSyncService();
      
      // 1. Check Health Connect availability
      final isAvailable = await syncService.isHealthConnectAvailable();
      if (!isAvailable) {
        if (Get.context != null) {
          ElegantSnackbar.warning(
            Get.context!,
            'Health Connect belum terinstall. Install dulu dari Play Store ya!',
          );
        }
        return 0;
      }
      
      // 2. Request permissions
      final hasPermission = await syncService.requestPermissions();
      if (!hasPermission) {
        if (Get.context != null) {
          ElegantSnackbar.warning(
            Get.context!,
            'Izin akses Health Connect diperlukan untuk sinkronisasi.',
          );
        }
        return 0;
      }
      
      // 3. Fetch workouts from last 7 days
      final workouts = await syncService.fetchWorkouts();
      
      if (workouts.isEmpty) {
        if (Get.context != null) {
          ElegantSnackbar.info(
            Get.context!,
            'Tidak ada aktivitas baru dari smartwatch dalam 7 hari terakhir.',
          );
        }
        return 0;
      }
      
      // 4. Sync to backend
      final syncedCount = await syncService.syncToBackend(workouts);
      
      // 5. Refresh activity list
      await fetchActivitiesForDate(selectedDate.value);
      
      // 6. Check if any synced workout is from today
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      bool hasTodayWorkout = workouts.any((w) {
        final startTimeStr = w['startTime'] as String?;
        if (startTimeStr == null) return false;
        try {
          final startLocal = DateTime.parse(startTimeStr).toLocal();
          return DateFormat('yyyy-MM-dd').format(startLocal) == todayStr;
        } catch (_) {
          return false;
        }
      });

      if (hasTodayWorkout) {
        await StorageService().setLastActivityInputTime(DateTime.now());
        await NotificationService().refreshSystemNotifications();
      }
      
      return syncedCount;
    } catch (e) {
      print('Error syncing smartwatch: $e');
      if (Get.context != null) {
        ErrorSnackbar.show(Get.context!, 'Gagal sinkronisasi: $e');
      }
      return 0;
    } finally {
      isSyncingSmartwatch.value = false;
    }
  }

  void setActivityType(String type) {
    activityType.value = type;
  }

  // Helper method untuk build dialog stat dengan icon & warna (sama kayak bottom sheet)
  Widget _buildSimpleStatCard(IconData icon, String value, String label, Color color, Color textColor, Color subTextColor) {
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
              color: subTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleDistanceCard(String value, String label) {
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
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

