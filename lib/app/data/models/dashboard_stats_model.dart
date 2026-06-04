import 'package:equatable/equatable.dart';
import 'food_model.dart';

/// Dashboard stats model untuk GET /stats/dashboard
class DashboardStatsModel extends Equatable {
  final DateTime date;
  final CalorieStatsModel calories;
  final SugarStatsModel sugar;
  final WaterStatsModel water;
  final ActivityStatsModel activity;
  final FoodModel? lastFood; // Makanan terakhir

  const DashboardStatsModel({
    required this.date,
    required this.calories,
    required this.sugar,
    required this.water,
    required this.activity,
    this.lastFood,
  });

  /// From JSON
  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      calories: CalorieStatsModel.fromJson(json['calories'] ?? {}),
      sugar: SugarStatsModel.fromJson(json['sugar'] ?? {}),
      water: WaterStatsModel.fromJson(json['water'] ?? {}),
      activity: ActivityStatsModel.fromJson(json['activity'] ?? {}),
      lastFood: json['lastFood'] != null
          ? FoodModel.fromJson(json['lastFood'])
          : null,
    );
  }

  @override
  List<Object?> get props => [date, calories, sugar, water, activity, lastFood];

  /// To JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'calories': calories.toJson(),
      'sugar': sugar.toJson(),
      'water': water.toJson(),
      'activity': activity.toJson(),
      'lastFood': lastFood?.toJson(),
    };
  }
}

/// Calorie stats
class CalorieStatsModel extends Equatable {
  final double consumed; // Total kalori dikonsumsi
  final double burned; // Total kalori dibakar
  final double goal; // Target kalori

  const CalorieStatsModel({
    required this.consumed,
    required this.burned,
    required this.goal,
  });

  /// Net calories (consumed - burned)
  double get net => consumed - burned;

  /// Percentage of goal (as method for consistency)
  double percentage() => goal > 0 ? (consumed / goal) * 100 : 0;
  
  /// Percentage of goal (as getter)
  double get percentageValue => percentage();

  /// Remaining to goal (as method)
  double remaining() => goal - consumed;
  
  /// Remaining to goal (as getter)
  double get remainingValue => remaining();

  factory CalorieStatsModel.fromJson(Map<String, dynamic> json) {
    return CalorieStatsModel(
      consumed: (json['consumed'] ?? 0).toDouble(),
      burned: (json['burned'] ?? 0).toDouble(),
      goal: (json['goal'] ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [consumed, burned, goal];

  Map<String, dynamic> toJson() {
    return {
      'consumed': consumed,
      'burned': burned,
      'goal': goal,
    };
  }
}

/// Sugar stats
class SugarStatsModel extends Equatable {
  final double consumed; // Total gula dikonsumsi (gram)
  final double goal; // Target gula (gram)

  const SugarStatsModel({
    required this.consumed,
    required this.goal,
  });

  /// Alias for consumed
  double get current => consumed;

  /// Percentage of goal (as method)
  double percentage() => goal > 0 ? (consumed / goal) * 100 : 0;
  
  /// Percentage of goal (as getter)
  double get percentageValue => percentage();

  /// Remaining to goal
  double get remaining => goal - consumed;

  /// Check if exceeded
  bool get isExceeded => consumed > goal;

  /// Check if near limit (>= 90%)
  bool get isNearLimit => percentage() >= 90;

  factory SugarStatsModel.fromJson(Map<String, dynamic> json) {
    return SugarStatsModel(
      consumed: (json['consumed'] ?? 0).toDouble(),
      goal: (json['goal'] ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [consumed, goal];

  Map<String, dynamic> toJson() {
    return {
      'consumed': consumed,
      'goal': goal,
    };
  }
}

/// Water stats
class WaterStatsModel extends Equatable {
  final double consumed; // Total air diminum (ml)
  final double goal; // Target air (ml)

  const WaterStatsModel({
    required this.consumed,
    required this.goal,
  });

  /// Alias for consumed
  int get current => consumed.toInt();

  /// Percentage of goal (as method)
  double percentage() => goal > 0 ? (consumed / goal) * 100 : 0;
  
  /// Percentage of goal (as getter)
  double get percentageValue => percentage();

  /// Remaining to goal
  double get remaining => goal - consumed;

  factory WaterStatsModel.fromJson(Map<String, dynamic> json) {
    return WaterStatsModel(
      consumed: (json['consumed'] ?? 0).toDouble(),
      goal: (json['goal'] ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [consumed, goal];

  Map<String, dynamic> toJson() {
    return {
      'consumed': consumed,
      'goal': goal,
    };
  }
}

/// Activity stats
class ActivityStatsModel extends Equatable {
  final double duration; // Total durasi aktivitas (menit)
  final int steps; // Total langkah
  final double distance; // Total jarak (km)
  final double caloriesBurned; // Total kalori terbakar
  final double goalBurn; // Target kalori terbakar
  final int goalSteps; // Target langkah (legacy/informational)
  final int walkingSteps; // Walking steps
  final int joggingSteps; // Jogging steps

  const ActivityStatsModel({
    required this.duration,
    required this.steps,
    required this.distance,
    required this.caloriesBurned,
    required this.goalBurn,
    required this.goalSteps,
    this.walkingSteps = 0,
    this.joggingSteps = 0,
  });

  /// Alias for steps
  int get current => steps;
  
  /// Alias for goalSteps
  int get goal => goalSteps;

  /// Percentage of burn goal
  double percentage() => goalBurn > 0 ? (caloriesBurned / goalBurn) * 100 : 0;
  
  /// Percentage of burn goal (as getter)
  double get burnPercentage => percentage();

  factory ActivityStatsModel.fromJson(Map<String, dynamic> json) {
    // Handle both 'steps' and 'totalSteps' field names
    final steps = (json['steps'] ?? json['totalSteps'] ?? 0).toInt();
    final caloriesBurned = (json['caloriesBurned'] ?? json['totalCaloriesBurned'] ?? 0).toDouble();
    
    return ActivityStatsModel(
      duration: (json['duration'] ?? json['totalDuration'] ?? 0).toDouble(),
      steps: steps,
      distance: (json['distance'] ?? json['totalDistance'] ?? 0).toDouble(),
      caloriesBurned: caloriesBurned,
      goalBurn: (json['goalBurn'] ?? 0).toDouble(),
      goalSteps: (json['goalSteps'] ?? 0).toInt(),
    );
  }

  @override
  List<Object?> get props => [
        duration,
        steps,
        distance,
        caloriesBurned,
        goalBurn,
        goalSteps,
        walkingSteps,
        joggingSteps,
      ];

  Map<String, dynamic> toJson() {
    return {
      'duration': duration,
      'steps': steps,
      'distance': distance,
      'caloriesBurned': caloriesBurned,
      'goalBurn': goalBurn,
      'goalSteps': goalSteps,
      'walkingSteps': walkingSteps,
      'joggingSteps': joggingSteps,
    };
  }
}
