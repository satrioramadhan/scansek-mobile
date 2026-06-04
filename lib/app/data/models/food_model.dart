import 'package:equatable/equatable.dart';

/// Food consumption model
class FoodModel extends Equatable {
  final String id;
  final String userId;
  final String name;
  final double sugarContent; // gram per unit
  final double calorieContent; // kcal per unit
  final double weight; // berat isi
  final String weightUnit; // 'gram' or 'ml'
  final int quantity; // jumlah porsi
  final DateTime consumptionTime;
  final bool isScanned; // true jika dari scanner
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FoodModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.sugarContent,
    required this.calorieContent,
    required this.weight,
    required this.weightUnit,
    required this.quantity,
    required this.consumptionTime,
    this.isScanned = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Calculate total sugar
  double get totalSugar => sugarContent * quantity;

  /// Calculate total calories
  double get totalCalories => calorieContent * quantity;

  /// From JSON
  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      sugarContent: (json['sugarContent'] ?? 0).toDouble(),
      calorieContent: (json['calorieContent'] ?? 0).toDouble(),
      weight: (json['weight'] ?? 0).toDouble(),
      weightUnit: json['weightUnit'] ?? 'gram',
      quantity: (json['quantity'] ?? 1).toInt(),
      consumptionTime: json['consumptionTime'] != null
          ? DateTime.parse(json['consumptionTime'])
          : DateTime.now(),
      isScanned: json['isScanned'] ?? false,
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
      'name': name,
      'sugarContent': sugarContent,
      'calorieContent': calorieContent,
      'weight': weight,
      'weightUnit': weightUnit,
      'quantity': quantity,
      'consumptionTime': consumptionTime.toIso8601String(),
      'isScanned': isScanned,
    };
  }

  /// Copy with
  FoodModel copyWith({
    String? id,
    String? userId,
    String? name,
    double? sugarContent,
    double? calorieContent,
    double? weight,
    String? weightUnit,
    int? quantity,
    DateTime? consumptionTime,
    bool? isScanned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoodModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      sugarContent: sugarContent ?? this.sugarContent,
      calorieContent: calorieContent ?? this.calorieContent,
      weight: weight ?? this.weight,
      weightUnit: weightUnit ?? this.weightUnit,
      quantity: quantity ?? this.quantity,
      consumptionTime: consumptionTime ?? this.consumptionTime,
      isScanned: isScanned ?? this.isScanned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        sugarContent,
        calorieContent,
        weight,
        weightUnit,
        quantity,
        consumptionTime,
        isScanned,
        createdAt,
        updatedAt,
      ];
}
