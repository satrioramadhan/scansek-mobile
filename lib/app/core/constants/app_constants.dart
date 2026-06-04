/// App-wide constants
class AppConstants {
  AppConstants._(); // Private constructor

  // ============================================
  // API Configuration
  // ============================================

  /// Base URL untuk production
  static const String baseUrl = 'https://api.scansek.my.id/api/v1';

  /// API timeout duration
  static const Duration apiTimeout = Duration(seconds: 60);

  // ============================================
  // Storage Keys
  // ============================================

  /// Secure Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';

  /// Shared Preferences Keys
  static const String isFirstLaunchKey = 'is_first_launch';
  static const String remindersKey = 'reminders';
  static const String notificationPrefsKey = 'notification_prefs';

  // ============================================
  // Default Goals (WHO Recommendations)
  // ============================================

  /// Default daily sugar goal (WHO recommendation)
  static const double defaultSugarGoal = 50.0; // gram

  /// Default daily calorie goal
  static const double defaultCalorieGoalMale = 2500.0; // kcal
  static const double defaultCalorieGoalFemale = 2000.0; // kcal

  /// Default daily water goal
  static const double defaultWaterGoal = 2000.0; // ml

  /// Default daily steps goal
  static const int defaultStepsGoal = 10000;

  // ============================================
  // Conversion Constants
  // ============================================

  /// Sugar conversion: 1 sendok teh = 4 gram
  static const double sugarGramPerTeaspoon = 4.0;

  /// Sugar conversion: 1 sendok makan = 12 gram
  static const double sugarGramPerTablespoon = 12.0;

  // ============================================
  // MET Values (Metabolic Equivalent of Task)
  // ============================================

  /// MET value untuk walking (3.5 METs)
  static const double metWalking = 3.5;

  /// MET value untuk jogging (7.0 METs)
  static const double metJogging = 7.0;

  /// MET value untuk running (9.8 METs)
  static const double metRunning = 9.8;

  // ============================================
  // Validation Constants
  // ============================================

  /// Minimum age requirement (years)
  static const int minimumAge = 13;

  /// Password minimum length
  static const int passwordMinLength = 6;

  /// OTP length
  static const int otpLength = 6;

  /// OTP validity duration
  static const Duration otpValidity = Duration(minutes: 10);

  /// Weight range (kg)
  static const double minWeight = 30.0;
  static const double maxWeight = 300.0;

  /// Height range (cm)
  static const double minHeight = 100.0;
  static const double maxHeight = 250.0;

  // ============================================
  // Pagination
  // ============================================

  /// Items per page untuk history
  static const int itemsPerPage = 20;

  // ============================================
  // Chart & Stats
  // ============================================

  /// Number of days untuk weekly graph
  static const int weeklyStatsDays = 7;

  // ============================================
  // Animation Durations
  // ============================================

  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // ============================================
  // Notification
  // ============================================

  /// Default reminder time untuk water (setiap 2 jam)
  static const Duration waterReminderInterval = Duration(hours: 2);

  /// Default reminder time untuk activity (setiap hari jam 6 sore)
  static const String activityReminderTime = '18:00';

  // ============================================
  // BMI Categories
  // ============================================

  static const double bmiUnderweightMax = 18.5;
  static const double bmiNormalMax = 24.9;
  static const double bmiOverweightMax = 29.9;
  // > 30 = Obesity

  // ============================================
  // Date & Time Formats
  // ============================================

  /// Format: 08 Jan 2026
  static const String dateFormat = 'dd MMM yyyy';

  /// Format: 14:30
  static const String timeFormat = 'HH:mm';

  /// Format: 08 Jan 2026, 14:30
  static const String dateTimeFormat = 'dd MMM yyyy, HH:mm';

  /// Hari dalam Bahasa Indonesia
  static const List<String> daysInIndonesian = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  /// Bulan dalam Bahasa Indonesia
  static const List<String> monthsInIndonesian = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
}
