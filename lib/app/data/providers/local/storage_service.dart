import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

/// Storage service untuk manage tokens (secure) dan preferences
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;

  // Secure storage untuk tokens
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Shared preferences untuk non-sensitive data
  late SharedPreferences _prefs;

  StorageService._internal();

  /// Initialize storage
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ============================================
  // SECURE STORAGE (TOKENS & SENSITIVE DATA)
  // ============================================

  /// Save access token
  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(
      key: AppConstants.accessTokenKey,
      value: token,
    );
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: AppConstants.accessTokenKey);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(
      key: AppConstants.refreshTokenKey,
      value: token,
    );
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: AppConstants.refreshTokenKey);
  }

  /// Save user data (as JSON string)
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final jsonString = jsonEncode(userData);
    await _secureStorage.write(
      key: AppConstants.userDataKey,
      value: jsonString,
    );
  }

  /// Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    final jsonString = await _secureStorage.read(key: AppConstants.userDataKey);
    if (jsonString == null) return null;

    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Delete access token
  Future<void> deleteAccessToken() async {
    await _secureStorage.delete(key: AppConstants.accessTokenKey);
  }

  /// Delete refresh token
  Future<void> deleteRefreshToken() async {
    await _secureStorage.delete(key: AppConstants.refreshTokenKey);
  }

  /// Delete user data
  Future<void> deleteUserData() async {
    await _secureStorage.delete(key: AppConstants.userDataKey);
  }

  /// Clear all secure storage
  Future<void> clearSecureStorage() async {
    await _secureStorage.deleteAll();
  }

  // ============================================
  // SHARED PREFERENCES (NON-SENSITIVE DATA)
  // ============================================

  /// Check if first launch
  bool get isFirstLaunch {
    return _prefs.getBool(AppConstants.isFirstLaunchKey) ?? true;
  }

  /// Set first launch flag
  Future<void> setFirstLaunch(bool value) async {
    await _prefs.setBool(AppConstants.isFirstLaunchKey, value);
  }

  /// Check if BMI dialog has been shown
  bool get hasShownBMIDialog {
    return _prefs.getBool('has_shown_bmi_dialog') ?? false;
  }

  /// Set BMI dialog shown flag
  Future<void> setBMIDialogShown(bool value) async {
    await _prefs.setBool('has_shown_bmi_dialog', value);
  }

  /// Check Fasting Mode Status
  bool get isFastingMode {
    return _prefs.getBool('is_fasting_mode') ?? false;
  }

  /// Save Fasting Mode Status
  Future<void> setFastingMode(bool value) async {
    await _prefs.setBool('is_fasting_mode', value);
  }

  // ============================================
  // SMART NOTIFICATION TIMESTAMPS
  // ============================================

  /// Simpan waktu terakhir user input konsumsi (food)
  Future<void> setLastFoodInputTime(DateTime time) async {
    await _prefs.setString('last_food_input_time', time.toIso8601String());
  }

  /// Ambil waktu terakhir user input konsumsi
  DateTime? get lastFoodInputTime {
    final str = _prefs.getString('last_food_input_time');
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  /// Simpan waktu terakhir user input air minum
  Future<void> setLastWaterInputTime(DateTime time) async {
    await _prefs.setString('last_water_input_time', time.toIso8601String());
  }

  /// Ambil waktu terakhir user input air minum
  DateTime? get lastWaterInputTime {
    final str = _prefs.getString('last_water_input_time');
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  /// Simpan waktu terakhir user simpan aktivitas
  Future<void> setLastActivityInputTime(DateTime time) async {
    await _prefs.setString('last_activity_input_time', time.toIso8601String());
  }

  /// Ambil waktu terakhir user simpan aktivitas
  DateTime? get lastActivityInputTime {
    final str = _prefs.getString('last_activity_input_time');
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  /// Save reminders data
  Future<void> saveReminders(List<Map<String, dynamic>> reminders) async {
    final jsonString = jsonEncode(reminders);
    await _prefs.setString(AppConstants.remindersKey, jsonString);
  }

  /// Get reminders data
  List<Map<String, dynamic>> getReminders() {
    final jsonString = _prefs.getString(AppConstants.remindersKey);
    if (jsonString == null) return [];

    try {
      final list = jsonDecode(jsonString) as List;
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  /// Save notification preferences
  Future<void> saveNotificationPrefs(Map<String, dynamic> prefs) async {
    final jsonString = jsonEncode(prefs);
    await _prefs.setString(AppConstants.notificationPrefsKey, jsonString);
  }

  /// Get notification preferences
  Map<String, dynamic>? getNotificationPrefs() {
    final jsonString = _prefs.getString(AppConstants.notificationPrefsKey);
    if (jsonString == null) return null;

    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Generic save string
  Future<void> saveString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  /// Generic get string
  String? getString(String key) {
    return _prefs.getString(key);
  }

  /// Generic save bool
  Future<void> saveBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  /// Generic get bool
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  /// Generic save int
  Future<void> saveInt(String key, int value) async {
    await _prefs.setInt(key, value);
  }

  /// Generic get int
  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  /// Generic save double
  Future<void> saveDouble(String key, double value) async {
    await _prefs.setDouble(key, value);
  }

  /// Generic get double
  double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  /// Clear all shared preferences
  Future<void> clearSharedPreferences() async {
    await _prefs.clear();
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Check if user is logged in (has access token)
  Future<bool> get isLoggedIn async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Check if user has completed onboarding
  bool get hasCompletedOnboarding {
    return !isFirstLaunch;
  }

  /// Clear everything (logout)
  Future<void> clearAll() async {
    await clearSecureStorage();
    // Keep some prefs like onboarding status
    final onboardingStatus = isFirstLaunch;
    await clearSharedPreferences();
    await setFirstLaunch(onboardingStatus);
  }
}
