/// Service untuk sinkronisasi data aktivitas dari smartwatch via Health Connect.
/// 
/// Alur: Smartwatch → Mi Fitness → Health Connect → ScanSek → Backend
library;

import 'dart:convert';
import 'package:health/health.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scansek/app/data/providers/api/api_client.dart';
import 'package:scansek/app/data/providers/local/storage_service.dart';
import 'package:scansek/app/data/providers/api/api_endpoints.dart';

class SmartwatchSyncService {
  final Health _health = Health();
  final ApiClient _apiClient = Get.find<ApiClient>();
  static const MethodChannel _routeChannel = MethodChannel('com.scansek.app/health_route');
  
  bool _isConfigured = false;

  /// Configure Health plugin — harus dipanggil sekali sebelum pakai
  Future<void> configure() async {
    if (_isConfigured) return;
    await _health.configure();
    _isConfigured = true;
  }

  /// Check apakah Health Connect tersedia di device
  Future<bool> isHealthConnectAvailable() async {
    try {
      await configure();
      final status = await _health.getHealthConnectSdkStatus();
      return status == HealthConnectSdkStatus.sdkAvailable;
    } catch (e) {
      print('Error checking Health Connect: $e');
      return false;
    }
  }

  /// Request permissions untuk baca workout, steps, heart rate, exercise route
  Future<bool> requestPermissions() async {
    try {
      await configure();
      
      // Request activity recognition permission first
      await Permission.activityRecognition.request();
      
      final types = [
        HealthDataType.WORKOUT,
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.TOTAL_CALORIES_BURNED,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.DISTANCE_DELTA,
      ];
      
      final permissions = types.map((_) => HealthDataAccess.READ).toList();
      
      final authorized = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );
      
      return authorized;
    } catch (e) {
      print('Error requesting Health Connect permissions: $e');
      return false;
    }
  }

  /// Fetch semua workout dari Health Connect dalam 7 hari terakhir.
  /// Return list of maps yang siap POST ke backend.
  Future<List<Map<String, dynamic>>> fetchWorkouts() async {
    try {
      await configure();
      
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      
      // 1. Fetch workout data
      final workoutData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: sevenDaysAgo,
        endTime: now,
      );
      
      if (workoutData.isEmpty) return [];
      
      // 2. Get UUIDs and check which ones are already synced
      final uuids = workoutData.map((w) => w.uuid).toList();
      final syncedUuids = await _checkSyncedUuids(uuids);
      
      // 3. Filter out already-synced workouts
      final newWorkouts = workoutData.where((w) => !syncedUuids.contains(w.uuid)).toList();
      
      // 4. Smart Sync (Fase 2 Lite): Update calories for already synced workouts
      final alreadySyncedWorkouts = workoutData.where((w) => syncedUuids.contains(w.uuid)).toList();
      if (alreadySyncedWorkouts.isNotEmpty) {
        _processSmartSyncUpdates(alreadySyncedWorkouts); // Fire and forget async
      }
      
      if (newWorkouts.isEmpty) return [];
      
      // 4. Process each new workout
      List<Map<String, dynamic>> results = [];
      
      for (final workout in newWorkouts) {
        final workoutValue = workout.value;
        if (workoutValue is! WorkoutHealthValue) continue;
        
        var type = _mapWorkoutType(workoutValue.workoutActivityType);
        final startTime = workout.dateFrom;
        final endTime = workout.dateTo;
        final durationMinutes = endTime.difference(startTime).inSeconds / 60.0;
        
        // Get calories from workout summary
        double summaryCalories = workoutValue.totalEnergyBurned?.toDouble() ?? 0.0;
        double fetchedCalories = await _fetchCalories(startTime, endTime);
        double calories = summaryCalories > fetchedCalories ? summaryCalories : fetchedCalories;
        
        // Fetch Raw Metadata (title/notes) from Native MethodChannel to fix generic "other" type
        try {
          final String? metadataJson = await _routeChannel.invokeMethod('getRawSessionMetadata', {
            'sessionId': workout.uuid
          });
          print('RAW METADATA from Kotlin for ${workout.uuid}: $metadataJson');
          
          if (metadataJson != null && metadataJson.isNotEmpty) {
            final Map<String, dynamic> metadata = jsonDecode(metadataJson);
            final title = (metadata['title'] as String?)?.toLowerCase() ?? '';
            final notes = (metadata['notes'] as String?)?.toLowerCase() ?? '';
            
            // Override type if it contains specific keywords
            if (title.contains('jump') || notes.contains('jump') || title.contains('lompat')) {
              type = 'jump_rope';
            } else if (title.contains('weight') || notes.contains('weight') || title.contains('beban') || title.contains('dumble')) {
              type = 'weightlifting';
            } else if (title.contains('yoga')) {
              type = 'yoga';
            } else if (title.contains('badminton')) {
              type = 'badminton';
            } else if (title.contains('lari') || title.contains('run')) {
               type = 'running';
            } else if (title.contains('renang') || title.contains('swim')) {
               type = 'swimming';
            } else if (title.contains('sepeda') || title.contains('cycl')) {
               type = 'cycling';
            } else if (title.contains('jalan') || title.contains('walk')) {
               type = 'walking';
            }
          }
        } catch (e) {
          print('Failed to get metadata for session ${workout.uuid}: $e');
        }

        // Fallback for smartwatches that do not sync calories explicitly to Health Connect
        if (calories <= 0 && durationMinutes > 0) {
          double met = 4.0; // Default moderate
          if (type == 'walking') met = 3.5;
          else if (type == 'jogging') met = 7.0;
          else if (type == 'running') met = 9.8;
          else if (type == 'cycling') met = 7.5;
          else if (type == 'jump_rope') met = 11.0;
          else if (type == 'weightlifting') met = 5.0;
          else if (type == 'swimming') met = 8.0;
          else if (type == 'badminton') met = 5.5;
          
          double userWeight = 65.0; // Default
          try {
            if (Get.isRegistered<StorageService>()) {
              final storage = Get.find<StorageService>();
              final userData = await storage.getUserData();
              if (userData != null && userData['weight'] != null) {
                userWeight = (userData['weight'] as num).toDouble();
                if (userWeight <= 0) userWeight = 65.0;
              }
            }
          } catch (e) {
            print('Failed to get user weight: $e');
          }
          
          // Calories = MET * Weight * Duration (hours)
          calories = met * userWeight * (durationMinutes / 60.0);
        }
        
        // Get distance from workout summary
        double distance = 0;
        if (workoutValue.totalDistance != null) {
          distance = workoutValue.totalDistance!.toDouble() / 1000.0; // meters → km
        }
        
        // Get steps from workout summary
        int steps = 0;
        if (workoutValue.totalSteps != null) {
          steps = workoutValue.totalSteps!.toInt();
        } else {
          // Fallback: try fetching steps separately
          steps = await _fetchSteps(startTime, endTime);
        }
        
        // Get avg heart rate for workout interval
        final avgHR = await _fetchAvgHeartRate(startTime, endTime);
        
        // Determine category
        final category = _isOutdoorActivity(type, distance) ? 'outdoor' : 'indoor';
        
        // Calculate pace/speed for outdoor
        double pace = 0;
        double speed = 0;
        if (distance > 0 && durationMinutes > 0) {
          pace = durationMinutes / distance; // min/km
          speed = distance / (durationMinutes / 60); // km/h
        }
        
        // Fetch GPS Route using Native MethodChannel
        List<Map<String, dynamic>>? routeCoords;
        try {
          final String? routeJson = await _routeChannel.invokeMethod('requestRouteConsent', {
            'sessionId': workout.uuid
          });
          if (routeJson != null && routeJson.isNotEmpty) {
            final List<dynamic> parsed = jsonDecode(routeJson);
            routeCoords = parsed.map((e) => Map<String, dynamic>.from(e)).toList();
            print('Successfully extracted ${routeCoords.length} route coordinates for ${workout.uuid}');
          }
        } catch (e) {
          print('Failed to get route for session ${workout.uuid}: $e');
        }
        
        final workoutMap = {
          'type': type,
          'duration': double.parse(durationMinutes.toStringAsFixed(1)),
          'distance': double.parse(distance.toStringAsFixed(2)),
          'caloriesBurned': double.parse(calories.toStringAsFixed(1)),
          'steps': steps,
          'pace': double.parse(pace.toStringAsFixed(2)),
          'speed': double.parse(speed.toStringAsFixed(2)),
          'startTime': startTime.toUtc().toIso8601String(),
          'endTime': endTime.toUtc().toIso8601String(),
          'source': 'smartwatch',
          'category': category,
          'healthConnectUuid': workout.uuid,
          'avgHeartRate': avgHR,
        };

        // Backend validates that route must be between 2 and 500 items if provided.
        // For indoor workouts (or when route is missing), don't send the route field at all.
        if (routeCoords != null && routeCoords.length >= 2) {
          workoutMap['route'] = routeCoords;
        }

        results.add(workoutMap);
      }
      
      // ==========================================
      // DAILY SUMMARY ACTIVITY (GERAK AKTIF LAINNYA)
      // ==========================================
      final startOfToday = DateTime(now.year, now.month, now.day);
      
      double sumTodayCals = 0;
      int sumTodaySteps = 0;
      
      // Calculate sum of TODAY's workouts
      for (final w in workoutData) {
        if (w.dateFrom.isAfter(startOfToday) || w.dateFrom.isAtSameMomentAs(startOfToday)) {
          final wv = w.value;
          if (wv is WorkoutHealthValue) {
            double cals = wv.totalEnergyBurned?.toDouble() ?? 0;
            if (cals <= 0) {
                cals = await _fetchCalories(w.dateFrom, w.dateTo);
            }
            sumTodayCals += cals;
            
            int steps = wv.totalSteps?.toInt() ?? 0;
            if (steps <= 0) {
                steps = await _fetchSteps(w.dateFrom, w.dateTo);
            }
            sumTodaySteps += steps;
          }
        }
      }
      
      // Fetch Daily Totals from Smartwatch
      final dailyTotals = await _fetchDailyTotalsFromSmartwatch();
      double totalDailyCals = dailyTotals['calories'] ?? 0;
      int totalDailySteps = (dailyTotals['steps'] ?? 0).toInt();
      
      double diffCals = totalDailyCals - sumTodayCals;
      int diffSteps = totalDailySteps - sumTodaySteps;
      
      if (diffCals < 0) diffCals = 0;
      if (diffSteps < 0) diffSteps = 0;
      
      if (diffCals > 0 || diffSteps > 0) {
        final dummyUuid = 'daily_summary_${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}';
        
        final summaryMap = {
          'type': 'daily_summary',
          'duration': 0.0,
          'distance': 0.0,
          'caloriesBurned': double.parse(diffCals.toStringAsFixed(1)),
          'steps': diffSteps,
          'pace': 0.0,
          'speed': 0.0,
          'startTime': startOfToday.toUtc().toIso8601String(),
          'endTime': now.toUtc().toIso8601String(),
          'source': 'smartwatch',
          'category': 'daily_summary',
          'healthConnectUuid': dummyUuid,
          'avgHeartRate': 0,
        };
        
        if (syncedUuids.contains(dummyUuid)) {
          // Update existing daily summary
          try {
            await _apiClient.put(
              ApiEndpoints.updateActivity,
              data: {
                'healthConnectUuid': dummyUuid,
                'caloriesBurned': double.parse(diffCals.toStringAsFixed(1)),
                'steps': diffSteps,
              },
            );
          } catch (e) {
            print('Error updating daily summary: $e');
          }
        } else {
          results.add(summaryMap);
        }
      }
      
      return results;
    } catch (e) {
      print('Error fetching workouts from Health Connect: $e');
      return [];
    }
  }

  /// Sync semua workout ke backend. Returns jumlah yang berhasil di-sync.
  Future<int> syncToBackend(List<Map<String, dynamic>> workouts) async {
    int synced = 0;
    
    for (final workout in workouts) {
      try {
        final response = await _apiClient.post(
          ApiEndpoints.addActivity,
          data: workout,
        );
        if (response.statusCode == 201) {
          synced++;
        }
      } catch (e) {
        print('Error syncing workout: $e');
        // Continue syncing rest
      }
    }
    
    return synced;
  }

  // ============================================
  // PRIVATE HELPERS
  // ============================================

  /// Fase 2 Lite (Smart Sync): Cek kalori untuk olahraga yang sudah pernah di-sync.
  /// Kalau sekarang kalorinya udah > 0 (Mi Fitness udah nyetor data baru), 
  /// langsung tembak endpoint update secara diam-diam.
  Future<void> _processSmartSyncUpdates(List<HealthDataPoint> alreadySynced) async {
    for (final workout in alreadySynced) {
      try {
        final workoutValue = workout.value;
        if (workoutValue is! WorkoutHealthValue) continue;
        
        final startTime = workout.dateFrom;
        final endTime = workout.dateTo;
        
        // Cek kalori aslinya sekarang
        double fetchedCalories = await _fetchCalories(startTime, endTime);
        double summaryCalories = workoutValue.totalEnergyBurned?.toDouble() ?? 0.0;
        double realCalories = summaryCalories > fetchedCalories ? summaryCalories : fetchedCalories;
        
        // Kalau Mi Fitness udah nyetor kalori > 0, kita update ke backend
        if (realCalories > 0.1) {
          int steps = workoutValue.totalSteps?.toInt() ?? 0;
          if (steps == 0) {
            steps = await _fetchSteps(startTime, endTime);
          }
          
          await _apiClient.put(
            ApiEndpoints.updateActivity,
            data: {
              'healthConnectUuid': workout.uuid,
              'caloriesBurned': double.parse(realCalories.toStringAsFixed(1)),
              'steps': steps,
            },
          );
        }
      } catch (e) {
        print('Error smart syncing update for ${workout.uuid}: $e');
      }
    }
  }

  /// Check UUIDs yang sudah pernah di-sync ke backend
  Future<List<String>> _checkSyncedUuids(List<String> uuids) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.checkSynced,
        data: {'uuids': uuids},
      );
      if (response.statusCode == 200) {
        final synced = response.data['data']['synced'] as List;
        return synced.cast<String>();
      }
    } catch (e) {
      print('Error checking synced UUIDs: $e');
    }
    return [];
  }

  /// Fetch avg heart rate selama interval workout
  Future<double?> _fetchAvgHeartRate(DateTime from, DateTime to) async {
    try {
      final hrData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: from,
        endTime: to,
      );
      
      if (hrData.isEmpty) return null;
      
      double total = 0;
      int count = 0;
      for (final point in hrData) {
        if (point.value is NumericHealthValue) {
          total += (point.value as NumericHealthValue).numericValue.toDouble();
          count++;
        }
      }
      
      if (count == 0) return null;
      return double.parse((total / count).toStringAsFixed(0));
    } catch (e) {
      print('Error fetching heart rate: $e');
      return null;
    }
  }

  /// Fetch total steps selama interval workout
  Future<int> _fetchSteps(DateTime from, DateTime to) async {
    try {
      final steps = await _health.getTotalStepsInInterval(from, to);
      return steps ?? 0;
    } catch (e) {
      print('Error fetching steps: $e');
      return 0;
    }
  }

  /// Fetch total active calories burned selama interval workout
  Future<double> _fetchCalories(DateTime from, DateTime to) async {
    try {
      final calData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: from,
        endTime: to,
      );
      
      double activeTotal = 0.0;
      for (final point in calData) {
        if (point.value is NumericHealthValue) {
          activeTotal += (point.value as NumericHealthValue).numericValue.toDouble();
        }
      }
      
      double totalTotal = 0.0;
      final totalCalData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.TOTAL_CALORIES_BURNED],
        startTime: from,
        endTime: to,
      );
      for (final point in totalCalData) {
        if (point.value is NumericHealthValue) {
          totalTotal += (point.value as NumericHealthValue).numericValue.toDouble();
        }
      }
      
      return activeTotal > totalTotal ? activeTotal : totalTotal;
    } catch (e) {
      print('Error fetching calories: $e');
      return 0.0;
    }
  }

  /// Fetch total active calories and steps from smartwatch source for today
  Future<Map<String, double>> _fetchDailyTotalsFromSmartwatch() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      // Fetch steps
      final stepsData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: startOfDay,
        endTime: now,
      );
      
      double totalSteps = 0;
      for (var point in stepsData) {
        final source = point.sourceName.toLowerCase();
        final sourceId = point.sourceId.toLowerCase();
        // Filter strictly for smartwatch sources
        if (source.contains('mi fitness') || sourceId.contains('xiaomi') || 
            source.contains('zepp') || source.contains('smartwatch') || 
            sourceId.contains('garmin') || source.contains('garmin') || 
            source.contains('coros') || source.contains('suunto')) {
          if (point.value is NumericHealthValue) {
            totalSteps += (point.value as NumericHealthValue).numericValue.toDouble();
          }
        }
      }
      
      // Fetch active calories
      final calData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: startOfDay,
        endTime: now,
      );
      
      double totalCal = 0;
      for (var point in calData) {
        final source = point.sourceName.toLowerCase();
        final sourceId = point.sourceId.toLowerCase();
        // Filter strictly for smartwatch sources
        if (source.contains('mi fitness') || sourceId.contains('xiaomi') || 
            source.contains('zepp') || source.contains('smartwatch') || 
            sourceId.contains('garmin') || source.contains('garmin') || 
            source.contains('coros') || source.contains('suunto')) {
          if (point.value is NumericHealthValue) {
            totalCal += (point.value as NumericHealthValue).numericValue.toDouble();
          }
        }
      }
      
      return {
        'steps': totalSteps,
        'calories': totalCal,
      };
    } catch (e) {
      print('Error fetching daily totals: $e');
      return {'steps': 0.0, 'calories': 0.0};
    }
  }

  /// Map HealthWorkoutActivityType → ScanSek activity type string
  String _mapWorkoutType(HealthWorkoutActivityType type) {
    switch (type) {
      // Outdoor
      case HealthWorkoutActivityType.RUNNING:
        return 'running';
      case HealthWorkoutActivityType.WALKING:
        return 'walking';
      case HealthWorkoutActivityType.HIKING:
        return 'hiking';
      case HealthWorkoutActivityType.BIKING:
        return 'cycling';
        
      // Swimming
      case HealthWorkoutActivityType.SWIMMING:
        return 'swimming';
        
      // Indoor
      case HealthWorkoutActivityType.YOGA:
        return 'yoga';
      case HealthWorkoutActivityType.PILATES:
        return 'pilates';
      case HealthWorkoutActivityType.WEIGHTLIFTING:
        return 'weightlifting';
      case HealthWorkoutActivityType.JUMP_ROPE:
        return 'jump_rope';
      case HealthWorkoutActivityType.ROWING_MACHINE:
        return 'rowing';
      case HealthWorkoutActivityType.ELLIPTICAL:
        return 'elliptical';
      case HealthWorkoutActivityType.STAIR_CLIMBING:
        return 'stair_climbing';
      case HealthWorkoutActivityType.CALISTHENICS:
        return 'calisthenics';
      case HealthWorkoutActivityType.BADMINTON:
        return 'badminton';
      case HealthWorkoutActivityType.BASKETBALL:
        return 'basketball';
      case HealthWorkoutActivityType.SOCCER:
        return 'soccer';
      case HealthWorkoutActivityType.TABLE_TENNIS:
        return 'table_tennis';
      case HealthWorkoutActivityType.TENNIS:
        return 'tennis';
      case HealthWorkoutActivityType.MARTIAL_ARTS:
        return 'martial_arts';
      case HealthWorkoutActivityType.DANCING:
        return 'dancing';
      case HealthWorkoutActivityType.CRICKET:
        return 'cricket';
      case HealthWorkoutActivityType.VOLLEYBALL:
        return 'volleyball';
        
      default:
        return type.name.toLowerCase();
    }
  }

  /// Determine apakah activity outdoor (punya jarak / route berarti outdoor)
  bool _isOutdoorActivity(String type, double distance) {
    // Type-based: beberapa tipe selalu outdoor
    const outdoorTypes = {
      'running', 'walking', 'hiking', 'cycling', 'jogging',
    };
    
    if (outdoorTypes.contains(type)) return true;
    
    // Distance-based: kalau ada jarak berarti kemungkinan outdoor
    if (distance > 0.01) return true; // > 10 meters
    
    return false;
  }

  /// Get activity display label
  static String getActivityLabel(String type) {
    switch (type) {
      case 'walking': return 'Jalan';
      case 'jogging': return 'Jogging';
      case 'running': return 'Lari';
      case 'cycling': return 'Sepeda';
      case 'hiking': return 'Mendaki';
      case 'swimming': return 'Renang';
      case 'yoga': return 'Yoga';
      case 'pilates': return 'Pilates';
      case 'weightlifting': return 'Angkat Beban';
      case 'jump_rope': return 'Lompat Tali';
      case 'rowing': return 'Rowing';
      case 'elliptical': return 'Elliptical';
      case 'stair_climbing': return 'Naik Tangga';
      case 'calisthenics': return 'Kalistenik';
      case 'badminton': return 'Badminton';
      case 'basketball': return 'Basket';
      case 'soccer': return 'Sepak Bola';
      case 'table_tennis': return 'Tenis Meja';
      case 'tennis': return 'Tenis';
      case 'martial_arts': return 'Bela Diri';
      case 'dancing': return 'Menari';
      case 'cricket': return 'Kriket';
      case 'volleyball': return 'Voli';
      case 'treadmill': return 'Treadmill';
      case 'daily_summary': return 'Gerak Aktif Lainnya';
      default: 
        if (type == 'other') return 'Aktivitas Khusus';
        return type.split('_').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '').join(' ');
    }
  }
}
