import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scansek/app/data/models/reminder_model.dart';

/// Service untuk menyimpan dan mengelola reminders di local storage
class ReminderStorageService extends GetxService {
  static const String _key = 'reminders';

  SharedPreferences? _prefs;

  /// Constructor - will initialize prefs on first access
  ReminderStorageService() {
    _initPrefs();
  }

  /// Initialize shared preferences
  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get all reminders
  Future<List<ReminderModel>> getAllReminders() async {
    await _initPrefs(); // Ensure prefs is initialized
    try {
      final jsonString = _prefs?.getString(_key);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => ReminderModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading reminders: $e');
      return [];
    }
  }

  /// Save all reminders
  Future<bool> saveReminders(List<ReminderModel> reminders) async {
    try {
      final jsonList = reminders.map((r) => r.toJson()).toList();
      final jsonString = json.encode(jsonList);
      return await _prefs?.setString(_key, jsonString) ?? false;
    } catch (e) {
      print('Error saving reminders: $e');
      return false;
    }
  }

  /// Add a new reminder
  Future<bool> addReminder(ReminderModel reminder) async {
    final reminders = await getAllReminders();
    reminders.add(reminder);
    return await saveReminders(reminders);
  }

  /// Update a reminder
  Future<bool> updateReminder(ReminderModel reminder) async {
    final reminders = await getAllReminders();
    final index = reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      reminders[index] = reminder;
      return await saveReminders(reminders);
    }
    return false;
  }

  /// Delete a reminder
  Future<bool> deleteReminder(String id) async {
    final reminders = await getAllReminders();
    reminders.removeWhere((r) => r.id == id);
    return await saveReminders(reminders);
  }

  /// Toggle reminder enabled/disabled
  Future<bool> toggleReminder(String id) async {
    final reminders = await getAllReminders();
    final index = reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      reminders[index] = reminders[index].copyWith(
        isEnabled: !reminders[index].isEnabled,
      );
      return await saveReminders(reminders);
    }
    return false;
  }

  /// Clear all reminders
  Future<bool> clearAll() async {
    return await _prefs?.remove(_key) ?? false;
  }
}
