import 'package:equatable/equatable.dart';

/// User model
class UserModel extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? dateOfBirth;
  final String gender; 
  final double weight; 
  final double height;
  final double bmi;
  final GoalsModel goals;
  final bool isVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastBodyMetricsUpdate;
  final String? previousBmiCategory;
  final DateTime? bmiCategoryUpdatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.dateOfBirth,
    required this.gender,
    required this.weight,
    required this.height,
    required this.bmi,
    required this.goals,
    this.isVerified = false,
    this.createdAt,
    this.updatedAt,
    this.lastBodyMetricsUpdate,
    this.previousBmiCategory,
    this.bmiCategoryUpdatedAt,
  });

  /// From JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      dateOfBirth: json['dateOfBirth'],
      gender: json['gender'] ?? 'male',
      weight: (json['weight'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      bmi: (json['bmi'] ?? 0).toDouble(),
      goals: GoalsModel.fromJson(json['goals'] ?? {}),
      isVerified: json['isVerified'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      lastBodyMetricsUpdate: json['lastBodyMetricsUpdate'] != null
          ? DateTime.parse(json['lastBodyMetricsUpdate'])
          : null,
      previousBmiCategory: json['previousBmiCategory'],
      bmiCategoryUpdatedAt: json['bmiCategoryUpdatedAt'] != null
          ? DateTime.parse(json['bmiCategoryUpdatedAt'])
          : null,
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'goals': goals.toJson(),
      'isVerified': isVerified,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastBodyMetricsUpdate': lastBodyMetricsUpdate?.toIso8601String(),
      'previousBmiCategory': previousBmiCategory,
      'bmiCategoryUpdatedAt': bmiCategoryUpdatedAt?.toIso8601String(),
    };
  }

  /// Copy with
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? dateOfBirth,
    String? gender,
    double? weight,
    double? height,
    double? bmi,
    GoalsModel? goals,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastBodyMetricsUpdate,
    String? previousBmiCategory,
    DateTime? bmiCategoryUpdatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      bmi: bmi ?? this.bmi,
      goals: goals ?? this.goals,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastBodyMetricsUpdate: lastBodyMetricsUpdate ?? this.lastBodyMetricsUpdate,
      previousBmiCategory: previousBmiCategory ?? this.previousBmiCategory,
      bmiCategoryUpdatedAt: bmiCategoryUpdatedAt ?? this.bmiCategoryUpdatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        dateOfBirth,
        gender,
        weight,
        height,
        bmi,
        goals,
        isVerified,
        createdAt,
        updatedAt,
        lastBodyMetricsUpdate,
        previousBmiCategory,
        bmiCategoryUpdatedAt,
      ];
}

/// Goals model (nested in UserModel)
class GoalsModel extends Equatable {
  final double dailySugarGoal; // gram
  final double dailyCalorieGoal; // kcal
  final double dailyWaterGoal; // ml
  final double dailyBurnGoal; // kcal burned

  const GoalsModel({
    required this.dailySugarGoal,
    required this.dailyCalorieGoal,
    required this.dailyWaterGoal,
    required this.dailyBurnGoal,
  });

  /// From JSON
  factory GoalsModel.fromJson(Map<String, dynamic> json) {
    return GoalsModel(
      dailySugarGoal: (json['dailySugarGoal'] ?? json['sugar'] ?? 50.0).toDouble(),
      dailyCalorieGoal: (json['dailyCalorieGoal'] ?? json['calories'] ?? 2000.0).toDouble(),
      dailyWaterGoal: (json['dailyWaterGoal'] ?? json['water'] ?? 2000.0).toDouble(),
      dailyBurnGoal: (json['dailyBurnGoal'] ?? json['burn'] ?? 400.0).toDouble(),
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'dailySugarGoal': dailySugarGoal,
      'dailyCalorieGoal': dailyCalorieGoal,
      'dailyWaterGoal': dailyWaterGoal,
      'dailyBurnGoal': dailyBurnGoal,
    };
  }

  /// Copy with
  GoalsModel copyWith({
    double? dailySugarGoal,
    double? dailyCalorieGoal,
    double? dailyWaterGoal,
    double? dailyBurnGoal,
  }) {
    return GoalsModel(
      dailySugarGoal: dailySugarGoal ?? this.dailySugarGoal,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
      dailyWaterGoal: dailyWaterGoal ?? this.dailyWaterGoal,
      dailyBurnGoal: dailyBurnGoal ?? this.dailyBurnGoal,
    );
  }

  @override
  List<Object?> get props => [
        dailySugarGoal,
        dailyCalorieGoal,
        dailyWaterGoal,
        dailyBurnGoal,
      ];
}
