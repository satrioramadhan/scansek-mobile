import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scansek/app/data/models/reminder_model.dart';
import 'package:scansek/app/data/providers/api/api_client.dart';
import 'package:scansek/app/services/notification_service.dart';
import 'package:scansek/app/widgets/snackbars/snackbar_designs.dart';

class ReminderController extends GetxController {
  final ApiClient _apiClient = ApiClient();
  final NotificationService _notificationService = NotificationService();

  // Reactive list of reminders
  final RxList<ReminderModel> reminders = <ReminderModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    _loadReminders();
  }

  /// Initialize notification service
  Future<void> _initializeServices() async {
    print('🔔 Initializing notification service...');
    await _notificationService.initialize();
    print('🔔 Requesting permissions...');
    final granted = await _notificationService.requestPermissions();
    print('🔔 Permissions granted: $granted');
    
    if (!granted) {
      print('⚠️ WARNING: Notification permissions not granted!');
      ElegantSnackbar.warning(
        Get.context, 
        'Izinkan notifikasi untuk reminder bisa berfungsi'
      );
    }
  }

  /// Load all reminders from server
  Future<void> _loadReminders() async {
    isLoading.value = true;
    try {
      final response = await _apiClient.get('/reminders');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        final loadedReminders = data.map((e) => ReminderModel.fromJson(e)).toList();
        reminders.assignAll(loadedReminders);
        
        // Sync these to local notifications!
        for (final r in loadedReminders) {
          if (r.isEnabled) {
            await _notificationService.scheduleReminder(r);
          } else {
            await _notificationService.cancelReminder(r.id);
          }
        }
      }
    } catch (e) {
      print('Error loading reminders: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Add new reminder
  Future<void> addReminder(ReminderModel reminder) async {
    isLoading.value = true;
    
    try {
      final data = reminder.toJson();
      // Remove id before sending to backend to let mongodb create it
      data.remove('id');
      
      final response = await _apiClient.post('/reminders', data: data);
      
      if (response.statusCode == 201) {
        final newReminder = ReminderModel.fromJson(response.data['data']);
        reminders.add(newReminder);
        
        // Schedule notification
        if (newReminder.isEnabled) {
          await _notificationService.scheduleReminder(newReminder);
        }
        
        Get.back(); // Close dialog
        await _loadReminders();
        ElegantSnackbar.success(Get.context, 'Pengingat berhasil ditambahkan');
      } else {
        ElegantSnackbar.error(Get.context, 'Gagal menambahkan pengingat');
      }
    } catch (e) {
      print('Error adding reminder: $e');
      ElegantSnackbar.error(Get.context, 'Gagal menambahkan pengingat');
    } finally {
      isLoading.value = false;
    }
  }

  /// Update existing reminder
  Future<void> updateReminder(ReminderModel reminder) async {
    isLoading.value = true;
    
    try {
      final data = reminder.toJson();
      final response = await _apiClient.put('/reminders/${reminder.id}', data: data);
      
      if (response.statusCode == 200) {
        final updatedData = ReminderModel.fromJson(response.data['data']);
        final index = reminders.indexWhere((r) => r.id == reminder.id);
        if (index != -1) {
          reminders[index] = updatedData;
        }
        
        // Reschedule notification
        await _notificationService.cancelReminder(reminder.id);
        if (updatedData.isEnabled) {
          await _notificationService.scheduleReminder(updatedData);
        }
        
        Get.back(); // Close dialog
        await _loadReminders();
        ElegantSnackbar.success(Get.context, 'Pengingat berhasil diperbarui');
      } else {
        ElegantSnackbar.error(Get.context, 'Gagal memperbarui pengingat');
      }
    } catch (e) {
      print('Error updating reminder: $e');
      ElegantSnackbar.error(Get.context, 'Gagal memperbarui pengingat');
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete reminder
  Future<void> deleteReminder(String id) async {
    final reminder = reminders.firstWhere((r) => r.id == id);
    
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Hapus Pengingat?'),
        content: Text('Apakah Anda yakin ingin menghapus pengingat "${reminder.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      isLoading.value = true;
      try {
        final response = await _apiClient.delete('/reminders/$id');
        
        if (response.statusCode == 200) {
          reminders.removeWhere((r) => r.id == id);
          
          // Cancel notification
          await _notificationService.cancelReminder(id);
          
          ElegantSnackbar.success(Get.context, 'Pengingat berhasil dihapus');
        } else {
          ElegantSnackbar.error(Get.context, 'Gagal menghapus pengingat');
        }
      } catch (e) {
        print('Error deleting reminder: $e');
        ElegantSnackbar.error(Get.context, 'Gagal menghapus pengingat');
      } finally {
        isLoading.value = false;
      }
    }
  }

  /// Toggle reminder enabled/disabled
  Future<void> toggleReminder(String id) async {
    final index = reminders.indexWhere((r) => r.id == id);
    if (index == -1) return;
    
    final updatedReminder = reminders[index].copyWith(
      isEnabled: !reminders[index].isEnabled,
    );
    
    try {
      final data = {'isEnabled': updatedReminder.isEnabled};
      final response = await _apiClient.put('/reminders/$id', data: data);
      
      if (response.statusCode == 200) {
        reminders[index] = updatedReminder;
        
        // Update notification
        if (updatedReminder.isEnabled) {
          await _notificationService.scheduleReminder(updatedReminder);
          ElegantSnackbar.success(
            Get.context, 
            'Pengingat diaktifkan! Notifikasi siap dikirim 🔔'
          );
        } else {
          await _notificationService.cancelReminder(id);
          ElegantSnackbar.info(
            Get.context,
            'Pengingat dinonaktifkan'
          );
        }
      } else {
        ElegantSnackbar.error(Get.context, 'Gagal mengubah status pengingat');
      }
    } catch (e) {
      print('Error toggling reminder: $e');
      ElegantSnackbar.error(Get.context, 'Gagal mengubah status pengingat');
    }
  }

  /// Navigate to add reminder screen
  void navigateToAddReminder() {
    Get.toNamed('/reminder/add');
  }

  /// Navigate to edit reminder screen
  void navigateToEditReminder(ReminderModel reminder) {
    Get.toNamed('/reminder/edit', arguments: reminder);
  }
}
