import 'package:equatable/equatable.dart';

/// Water intake model
class WaterModel extends Equatable {
  final String id;
  final String userId;
  final double amount; // ml
  final DateTime intakeTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WaterModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.intakeTime,
    this.createdAt,
    this.updatedAt,
  });

  /// From JSON
  factory WaterModel.fromJson(Map<String, dynamic> json) {
    return WaterModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      intakeTime: json['intakeTime'] != null
          ? DateTime.parse(json['intakeTime'])
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
      'amount': amount,
      'intakeTime': intakeTime.toIso8601String(),
    };
  }

  /// Copy with
  WaterModel copyWith({
    String? id,
    String? userId,
    double? amount,
    DateTime? intakeTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WaterModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      intakeTime: intakeTime ?? this.intakeTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        amount,
        intakeTime,
        createdAt,
        updatedAt,
      ];
}
