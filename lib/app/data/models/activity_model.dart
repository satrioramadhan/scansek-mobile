import 'package:equatable/equatable.dart';

/// Physical activity model
class ActivityModel extends Equatable {
  final String id;
  final String userId;
  final String type; // 'walking', 'jogging', 'running'
  final double duration; // minutes
  final double distance; // km
  final double caloriesBurned; // kcal
  final int? steps; // optional steps count
  final List<Map<String, dynamic>>? route; // optional GPS route
  final DateTime startTime;
  final DateTime endTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ActivityModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.duration,
    required this.distance,
    required this.caloriesBurned,
    this.steps,
    this.route,
    required this.startTime,
    required this.endTime,
    this.createdAt,
    this.updatedAt,
  });

  /// From JSON
  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? 'walking',
      duration: (json['duration'] ?? 0).toDouble(),
      distance: (json['distance'] ?? 0).toDouble(),
      caloriesBurned: (json['caloriesBurned'] ?? 0).toDouble(),
      steps: json['steps'],
      route: json['route'] != null ? List<Map<String, dynamic>>.from(json['route']) : null,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'])
          : DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'])
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'duration': duration,
      'distance': distance,
      'caloriesBurned': caloriesBurned,
      'steps': steps,
      'route': route,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    };
  }

  /// Copy with
  ActivityModel copyWith({
    String? id,
    String? userId,
    String? type,
    double? duration,
    double? distance,
    double? caloriesBurned,
    int? steps,
    List<Map<String, dynamic>>? route,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      distance: distance ?? this.distance,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      steps: steps ?? this.steps,
      route: route ?? this.route,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        duration,
        distance,
        caloriesBurned,
        steps,
        route,
        startTime,
        endTime,
        createdAt,
        updatedAt,
      ];
}
