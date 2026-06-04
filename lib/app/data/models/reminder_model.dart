import 'package:flutter/material.dart';

/// Reminder type enum
enum ReminderType {
  water,
  activity,
}

extension ReminderTypeExtension on ReminderType {
  String get label {
    switch (this) {
      case ReminderType.water:
        return 'Minum Air';
      case ReminderType.activity:
        return 'Aktivitas Fisik';
    }
  }

  String get icon {
    switch (this) {
      case ReminderType.water:
        return '💧';
      case ReminderType.activity:
        return '🏃';
    }
  }

  IconData get iconData {
    switch (this) {
      case ReminderType.water:
        return Icons.water_drop;
      case ReminderType.activity:
        return Icons.directions_run;
    }
  }
}

/// Reminder frequency enum
enum ReminderFrequency {
  daily,
  once,
  custom,
}

extension ReminderFrequencyExtension on ReminderFrequency {
  String get label {
    switch (this) {
      case ReminderFrequency.daily:
        return 'Setiap Hari';
      case ReminderFrequency.once:
        return 'Sekali';
      case ReminderFrequency.custom:
        return 'Hari Tertentu';
    }
  }
}

/// Reminder model
class ReminderModel {
  final String id;
  final String title;
  final ReminderType type;
  final TimeOfDay time;
  final ReminderFrequency frequency;
  final List<int> customDays; // 1=Monday, 7=Sunday
  final bool isEnabled;
  final String? customMessage; // Custom notification message

  const ReminderModel({
    required this.id,
    required this.title,
    required this.type,
    required this.time,
    required this.frequency,
    this.customDays = const [],
    this.isEnabled = true,
    this.customMessage,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'hour': time.hour,
      'minute': time.minute,
      'frequency': frequency.name,
      'customDays': customDays,
      'isEnabled': isEnabled,
      'customMessage': customMessage,
    };
  }

  /// Create from JSON
  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] as String,
      title: json['title'] as String,
      type: ReminderType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReminderType.water,
      ),
      time: TimeOfDay(
        hour: json['hour'] as int,
        minute: json['minute'] as int,
      ),
      frequency: ReminderFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => ReminderFrequency.daily,
      ),
      customDays: (json['customDays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      isEnabled: json['isEnabled'] as bool? ?? true,
      customMessage: json['customMessage'] as String?,
    );
  }

  /// Copy with modifications
  ReminderModel copyWith({
    String? id,
    String? title,
    ReminderType? type,
    TimeOfDay? time,
    ReminderFrequency? frequency,
    List<int>? customDays,
    bool? isEnabled,
    String? customMessage,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      time: time ?? this.time,
      frequency: frequency ?? this.frequency,
      customDays: customDays ?? this.customDays,
      isEnabled: isEnabled ?? this.isEnabled,
      customMessage: customMessage ?? this.customMessage,
    );
  }
}
