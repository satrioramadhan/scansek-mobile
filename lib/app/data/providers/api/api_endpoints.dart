/// API endpoint constants
class ApiEndpoints {
  ApiEndpoints._(); // Private constructor

  // ============================================
  // HEALTH & TEST
  // ============================================

  static const String health = '/health';
  static const String testPing = '/test/ping';
  static const String testInfo = '/test/info';
  static const String testEcho = '/test/echo';
  static const String testHeaders = '/test/headers';
  static const String testMethods = '/test/methods';

  // ============================================
  // AUTHENTICATION
  // ============================================

  static const String register = '/auth/register';
  static const String verifyOtp = '/auth/verify-otp';
  static const String login = '/auth/login';
  static const String googleLogin = '/auth/google-login';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyResetOtp = '/auth/verify-reset-otp';
  static const String resetPassword = '/auth/reset-password';
  static const String resendOtp = '/auth/resend-otp';

  // ============================================
  // USER PROFILE
  // ============================================

  static const String getProfile = '/users/profile';
  static const String updateProfile = '/users/profile';
  static const String updateGoals = '/users/goals';

  // ============================================
  // FOOD
  // ============================================

  static const String addFood = '/food/add';
  static const String todayFood = '/food/today';
  static const String getFoodHistory = '/food/history';
  static const String foodHistory = '/food/history'; // Alias
  static const String updateFood = '/food/update';
  static const String deleteFood = '/food/delete';

  // ============================================
  // WATER
  // ============================================

  static const String addWater = '/water/add';
  static const String getWaterHistory = '/water/history';
  static const String waterHistory = '/water/history'; // Alias
  static const String deleteWater = '/water/delete';

  // ============================================
  // ACTIVITIES
  // ============================================

  static const String addActivity = '/activity/add';
  static const String updateActivity = '/activity/update-by-uuid';
  static const String editActivity = '/activity'; // Appended with /:id
  static const String activityHistory = '/activity/history';
  static const String todayActivity = '/activity/today';
  static const String deleteActivity = '/activity'; // Appended with /:id
  static const String checkSynced = '/activity/check-synced';

  // ============================================
  // STATS
  // ============================================

  static const String getDashboard = '/stats/dashboard';
  static const String dashboardStats = '/stats/dashboard'; // Alias
  static const String getWeeklyStats = '/stats/weekly';
}
