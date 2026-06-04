import '../constants/app_constants.dart';

/// Helper utilities for common calculations and conversions
class Helpers {
  Helpers._(); // Private constructor

  // ============================================
  // BMI CALCULATION
  // ============================================

  /// Calculate BMI (Body Mass Index)
  /// Formula: weight (kg) / (height (m))^2
  static double calculateBMI(double weightKg, double heightCm) {
    if (weightKg <= 0 || heightCm <= 0) return 0;

    final heightM = heightCm / 100;
    final bmi = weightKg / (heightM * heightM);

    return double.parse(bmi.toStringAsFixed(1));
  }

  /// Get BMI category
  static String getBMICategory(double bmi) {
    if (bmi < AppConstants.bmiUnderweightMax) {
      return 'Kurus';
    } else if (bmi < AppConstants.bmiNormalMax) {
      return 'Normal';
    } else if (bmi < AppConstants.bmiOverweightMax) {
      return 'Kelebihan Berat Badan';
    } else {
      return 'Obesitas';
    }
  }

  // ============================================
  // SUGAR CONVERSION
  // ============================================

  /// Convert gram to teaspoons (sendok teh)
  /// 1 sdt = 4 gram
  static double gramToTeaspoons(double grams) {
    return grams / AppConstants.sugarGramPerTeaspoon;
  }

  /// Convert teaspoons to gram
  static double teaspoonsToGram(double teaspoons) {
    return teaspoons * AppConstants.sugarGramPerTeaspoon;
  }

  /// Convert gram to tablespoons (sendok makan)
  /// 1 sdm = 12 gram
  static double gramToTablespoons(double grams) {
    return grams / AppConstants.sugarGramPerTablespoon;
  }

  /// Convert tablespoons to gram
  static double tablespoonsToGram(double tablespoons) {
    return tablespoons * AppConstants.sugarGramPerTablespoon;
  }

  /// Get sugar unit conversion text
  /// Example: "8 gram (2 sdt)"
  static String getSugarWithConversion(double grams) {
    final teaspoons = gramToTeaspoons(grams);
    final teaspoonsRounded = teaspoons.toStringAsFixed(1);

    // Remove .0 if it's a whole number
    final teaspoonsText = teaspoons % 1 == 0
        ? teaspoons.toInt().toString()
        : teaspoonsRounded;

    return '${grams.toStringAsFixed(1)}g (~$teaspoonsText sdt)';
  }

  // ============================================
  // MET CALCULATION (Calories Burned)
  // ============================================

  /// Calculate calories burned using MET formula
  /// Formula: Calories = MET × weight (kg) × duration (hours)
  static double calculateCaloriesBurned({
    required String activityType,
    required double weightKg,
    required double durationMinutes,
  }) {
    double met;

    switch (activityType.toLowerCase()) {
      case 'walking':
        met = AppConstants.metWalking;
        break;
      case 'jogging':
        met = AppConstants.metJogging;
        break;
      case 'running':
        met = AppConstants.metRunning;
        break;
      default:
        met = AppConstants.metWalking; // Default to walking
    }

    final durationHours = durationMinutes / 60;
    final calories = met * weightKg * durationHours;

    return double.parse(calories.toStringAsFixed(1));
  }

  // ============================================
  // GOAL VALIDATION
  // ============================================

  /// Check if sugar goal exceeds WHO recommendation
  static bool exceedsWHOSugarRecommendation(double sugarGoal) {
    return sugarGoal > AppConstants.defaultSugarGoal;
  }

  /// Check if calorie goal exceeds standard recommendation
  static bool exceedsCalorieRecommendation(double calorieGoal, String gender) {
    final maxRecommended = gender.toLowerCase() == 'male'
        ? AppConstants.defaultCalorieGoalMale
        : AppConstants.defaultCalorieGoalFemale;

    return calorieGoal > maxRecommended;
  }

  // ============================================
  // PERCENTAGE CALCULATION
  // ============================================

  /// Calculate percentage
  /// Example: 75 consumed, 100 goal = 75%
  static double calculatePercentage(double value, double total) {
    if (total <= 0) return 0;
    final percentage = (value / total) * 100;
    return percentage > 100 ? 100 : percentage;
  }

  /// Get percentage as string "75%"
  static String getPercentageString(double value, double total) {
    final percentage = calculatePercentage(value, total);
    return '${percentage.toStringAsFixed(0)}%';
  }

  // ============================================
  // PROGRESS STATUS
  // ============================================

  /// Get progress status color based on percentage
  /// Returns: 'success', 'warning', or 'danger'
  static String getProgressStatus(double percentage) {
    if (percentage < 50) {
      return 'success'; // On track
    } else if (percentage < 90) {
      return 'warning'; // Getting close
    } else {
      return 'danger'; // Exceeded or about to exceed
    }
  }

  // ============================================
  // GREETING
  // ============================================

  /// Get greeting based on current time
  static String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 11) {
      return 'Selamat Pagi';
    } else if (hour < 15) {
      return 'Selamat Siang';
    } else if (hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  // ============================================
  // DATA FORMATTING
  // ============================================

  /// Format calories: 1450 kcal
  static String formatCalories(double calories) {
    return '${calories.toStringAsFixed(0)} kcal';
  }

  /// Format sugar: 35 g
  static String formatSugar(double grams) {
    return '${grams.toStringAsFixed(1)} g';
  }

  /// Format water: 1250 ml
  static String formatWater(double ml) {
    return '${ml.toStringAsFixed(0)} ml';
  }

  /// Format distance: 2.5 km
  static String formatDistance(double km) {
    return '${km.toStringAsFixed(1)} km';
  }

  /// Format duration: 30 menit
  static String formatDuration(double minutes) {
    if (minutes < 60) {
      return '${minutes.toStringAsFixed(0)} menit';
    } else {
      final hours = (minutes / 60).floor();
      final remainingMinutes = (minutes % 60).toStringAsFixed(0);
      return '$hours jam $remainingMinutes menit';
    }
  }

  /// Format steps: 8,500 langkah
  static String formatSteps(int steps) {
    return '$steps langkah';
  }

  // ============================================
  // VALIDATION HELPERS
  // ============================================

  /// Check if today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Get default calorie goal based on gender
  static double getDefaultCalorieGoal(String gender) {
    return gender.toLowerCase() == 'male'
        ? AppConstants.defaultCalorieGoalMale
        : AppConstants.defaultCalorieGoalFemale;
  }
}
