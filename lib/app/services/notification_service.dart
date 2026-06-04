import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scansek/app/data/models/reminder_model.dart';
import 'package:scansek/app/data/providers/local/storage_service.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';

/// Service untuk mengelola local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone natively
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channels for Android
    await _createNotificationChannels();

    _initialized = true;
  }

  /// Create notification channels (required for Android 8.0+)
  Future<void> _createNotificationChannels() async {
    // 1. Channel Pengingat Pribadi
    const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
      'reminders', // id - must match the channel ID used in scheduleReminder
      'Pengingat', // name shown in Android settings
      description: 'Pengingat minum air dan aktivitas fisik',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // 2. Channel Pengingat Sistem
    const AndroidNotificationChannel systemChannel = AndroidNotificationChannel(
      'system_reminders',
      'Pengingat Sistem',
      description: 'Pengingat otomatis dari sistem aplikasi',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // 3. Channel Tracking Aktivitas (ongoing foreground notification)
    const AndroidNotificationChannel trackingChannel = AndroidNotificationChannel(
      'activity_tracking',
      'Tracking Aktivitas',
      description: 'Notifikasi saat aktivitas fisik sedang direkam',
      importance: Importance.low, // Low = no sound, silent, but always shown
      playSound: false,
      enableVibration: false,
      showBadge: false,
    );

    // Create the channels on Android
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
    await androidImplementation?.createNotificationChannel(reminderChannel);
    await androidImplementation?.createNotificationChannel(systemChannel);
    await androidImplementation?.createNotificationChannel(trackingChannel);
  }

  // ==========================================
  // ACTIVITY TRACKING NOTIFICATION (Foreground)
  // ==========================================
  
  static const int _trackingNotificationId = 99999;

  /// Show or update the tracking notification
  Future<void> showTrackingNotification({
    required String activityLabel,
    required String duration,
    required String distance,
    bool isPaused = false,
  }) async {
    final title = isPaused 
      ? '⏸️ ScanSek: $activityLabel dijeda' 
      : '🏃 ScanSek: $activityLabel sedang direkam';

    final androidDetails = AndroidNotificationDetails(
      'activity_tracking',
      'Tracking Aktivitas',
      channelDescription: 'Notifikasi saat aktivitas fisik sedang direkam',
      importance: Importance.low,
      priority: Priority.low,
      icon: 'ic_stat_notification',
      ongoing: true, // Cannot be dismissed by user
      autoCancel: false,
      showWhen: false,
      playSound: false,
      enableVibration: false,
      category: AndroidNotificationCategory.service,
      visibility: NotificationVisibility.public,
      colorized: true,
      color: const Color(0xFF81C784), // ScanSek green
      styleInformation: BigTextStyleInformation(
        '⏱ $duration  ·  📍 $distance km',
        contentTitle: title,
        htmlFormatBigText: false,
        htmlFormatContentTitle: false,
      ),
      // Set to true so tapping the notification brings app to foreground
      // Since it's an ongoing notification, users can just tap it to open the app
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      _trackingNotificationId,
      title,
      '⏱ $duration  ·  📍 $distance km',
      notificationDetails,
      payload: 'activity_tracking',
    );
  }

  /// Cancel the tracking notification
  Future<void> cancelTrackingNotification() async {
    await _notifications.cancel(_trackingNotificationId);
  }

  /// Request notification permissions (Android 13+) and exact alarm (Android 12+)
  Future<bool> requestPermissions() async {
    // 1. Standard notification permission (Android 13+) - normally an in-app popup
    if (!(await Permission.notification.isGranted)) {
      await Permission.notification.request();
    }
    
    // 2. Disruptive permissions (Android 12+) - jumps to system settings
    final exactAlarmStatus = await Permission.scheduleExactAlarm.status;
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    
    if (!exactAlarmStatus.isGranted || !batteryStatus.isGranted) {
      // Tampilkan popup penejelasan ke user dulu agar tidak kaget dilempar ke setting
      final bool? proceed = await Get.dialog<bool>(
        Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.battery_charging_full_rounded, color: Color(0xFF4CAF50), size: 40),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Biar Notifnya Gak Ngaret!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Biar aplikasi ini tetep rajin ngingetin kamu walau aplikasinya lagi ditutup, kita butuh izin nih:\n\n1. Izinin \"Mulai Otomatis\"\n2. Bebasin batasan baterai\n\nNanti kamu bakal diarahin masuk ke pengaturan HP buat nyalain keduanya ya!',
                  style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(result: false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Ntar Aja', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Get.back(result: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Gass Atur', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      if (proceed == true) {
        if (!exactAlarmStatus.isGranted) {
          await Permission.scheduleExactAlarm.request();
        }
        if (!batteryStatus.isGranted) {
          await Permission.ignoreBatteryOptimizations.request();
        }
      }
    }
    
    return (await Permission.notification.isGranted) && (await Permission.scheduleExactAlarm.isGranted);
  }

  /// Schedule a reminder notification
  Future<void> scheduleReminder(ReminderModel reminder) async {
    if (!reminder.isEnabled) return;

    final notificationId = reminder.id.hashCode;

    final androidDetails = AndroidNotificationDetails(
      'reminders',
      'Pengingat',
      channelDescription: 'Pengingat minum air dan aktivitas fisik',
      importance: Importance.max,
      priority: Priority.max,
      icon: 'ic_stat_notification', // Custom ScanSek logo in top-left corner
      color: Colors.white, // White icon color (default Android style)
      colorized: true, // Make notification colored
      playSound: true, // Will use default Android sound
      enableVibration: true,
      styleInformation: const BigTextStyleInformation(
        '', // Will be filled with notification body
        contentTitle: '', // Will be filled with title
        htmlFormatContentTitle: false,
        htmlFormatBigText: false,
      ),
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      ticker: 'ScanSek Reminder',
      autoCancel: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Use custom message if provided, otherwise use default
    final notificationBody = reminder.customMessage?.isNotEmpty == true
        ? reminder.customMessage!
        : _getNotificationBody(reminder.type);

    // Get scheduled times based on frequency
    final scheduledTimes = _getScheduledTimes(reminder);

    // Notification title without emoji
    final notificationTitle = reminder.title;

    print('📅 Scheduling ${scheduledTimes.length} notification(s) for "${reminder.title}"');
    
    // Schedule for each time
    for (final scheduledTime in scheduledTimes) {
      final scheduleId = notificationId + scheduledTimes.indexOf(scheduledTime);
      print('   └─ ID: $scheduleId, Time: $scheduledTime');
      
      await _notifications.zonedSchedule(
        scheduleId,
        notificationTitle,
        notificationBody, // Use custom or default message
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: _getMatchComponents(reminder.frequency),
      );
    }
  }

  /// Cancel a reminder notification
  Future<void> cancelReminder(String reminderId) async {
    final notificationId = reminderId.hashCode;
    // Cancel with all possible IDs (for custom days)
    for (int i = 0; i < 7; i++) {
      await _notifications.cancel(notificationId + i);
    }
  }

  /// Cancel all user notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  // ==========================================
  // DEFAULT SYSTEM REMINDERS LOGIC (SMART)
  // ==========================================

  /// Cek apakah DateTime adalah hari ini
  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  /// Helper: jadwalkan satu notif dengan logic pintar
  /// Kalau user sudah input hari ini sebelum [notifHour], skip (geser besok).
  /// Kalau belum input, jadwalkan normal.
  Future<void> _scheduleSmartNotif({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required NotificationDetails details,
    required tz.TZDateTime now,
    DateTime? lastInput,
    int? shiftStartHour,
  }) async {
    bool shouldSkipToday = false;
    
    if (lastInput != null && _isToday(lastInput)) {
      if (shiftStartHour != null) {
        // Hanya skip jika input terjadi SETELAH shiftStartHour
        final shiftStartTime = DateTime(lastInput.year, lastInput.month, lastInput.day, shiftStartHour, 0);
        if (lastInput.isAfter(shiftStartTime)) {
          shouldSkipToday = true;
        }
      } else {
        // Default: kalau ada input hari ini jam berapapun, skip.
        shouldSkipToday = true;
      }
    }

    var baseTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (baseTime.isBefore(now)) {
      // Jam notif hari ini sudah lewat, mulai dari besok
      baseTime = baseTime.add(const Duration(days: 1));
    } else if (shouldSkipToday) {
      // Belum lewat, TAPI user sudah memenuhi syarat (input), skip hari ini
      baseTime = baseTime.add(const Duration(days: 1));
      print('📵 Notif #$id SKIPPED hari ini (user sudah input), mulai dari besok');
    }

    // Jadwalkan untuk 7 hari berturut-turut (menghindari bug komponen waktu bawaan Android)
    for (int i = 0; i < 7; i++) {
      final targetTime = baseTime.add(Duration(days: i));
      final scheduleId = id + (i * 100);
      
      await _notifications.zonedSchedule(
        scheduleId,
        title,
        body,
        targetTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Lebih kalem dari alarmClock
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null, // Jangan repeat, kita loop manual
      );
    }
    print('🔔 Notif #$id dijadwalkan mulai dari: $baseTime selama 7 hari');
  }

  /// Schedule system default reminders dengan logic pintar.
  /// Menerima timestamp terakhir input user untuk menentukan notif mana yang di-skip.
  Future<void> scheduleSystemDefaults({
    required DateTime lastBodyMetricsUpdate,
    DateTime? lastFoodInput,
    DateTime? lastWaterInput,
    DateTime? lastActivityInput,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'system_reminders',
      'Pengingat Sistem',
      channelDescription: 'Pengingat dari sistem aplikasi',
      importance: Importance.max,
      priority: Priority.max,
      icon: 'ic_stat_notification',
      color: Colors.white,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final now = tz.TZDateTime.now(tz.local);
    final isFasting = StorageService().isFastingMode;

    print('🔄 refreshSystemNotifications — food: $lastFoodInput, water: $lastWaterInput, activity: $lastActivityInput, fasting: $isFasting');

    // Cancel ALL system notifs dulu biar fresh (untuk 7 hari yang dijadwalkan)
    for (final baseId in [10001, 10002, 10003, 10004, 10005, 10006, 10007, 10008]) {
      for (int i = 0; i < 7; i++) {
        await _notifications.cancel(baseId + (i * 100));
      }
    }

    if (!isFasting) {
      // === KONSUMSI (11:00 & 18:00) ===
      await _scheduleSmartNotif(
        id: 10001, hour: 11, minute: 0,
        title: 'Hai haii, ada orang??',
        body: 'Kamu kemana aja kok sampe sekarang belum catat konsumsi harian kamu? 🍽️',
        details: details, now: now, lastInput: lastFoodInput,
      );
      await _scheduleSmartNotif(
        id: 10002, hour: 18, minute: 0,
        title: 'Mataharinya ngilang, kok kamunya juga ilang?',
        body: 'Menjelang malam nih, yuk catat udah makan/minum apa aja sebelum kamu lupa! 🍽️',
        details: details, now: now, lastInput: lastFoodInput,
        shiftStartHour: 11,
      );

      // === AIR MINUM (09:00 & 15:00) ===
      await _scheduleSmartNotif(
        id: 10003, hour: 9, minute: 0,
        title: 'Kamu kok ga minum air putih?',
        body: 'Yuk minum dulu, atau kalo sudah jangan lupa dicatat yaa💧',
        details: details, now: now, lastInput: lastWaterInput,
      );
      await _scheduleSmartNotif(
        id: 10004, hour: 15, minute: 0,
        title: 'Hey hey minum!!',
        body: 'Jangan lupa minum air putih, atau jangan lupa catat di scansek yaa 💧',
        details: details, now: now, lastInput: lastWaterInput,
        shiftStartHour: 9,
      );
    } else {
      // === FASTING MODE (Sahur 03:10 & Buka 18:30) — selalu bunyi ===
      await _scheduleSmartNotif(
        id: 10007, hour: 3, minute: 10,
        title: 'Waktunya Sahur! 🌙',
        body: 'Jangan lupa makan yang bertenaga & banyakin minum, terus dicatat ya catat nutrisinya! Semangat puasanya!😘',
        details: details, now: now, lastInput: null,
      );
      await _scheduleSmartNotif(
        id: 10008, hour: 18, minute: 30,
        title: 'Selamat Berbuka! 🌅',
        body: 'Alhamdulillah maghrib, jangan lupa sama targetnya dan jangan lupa dicatat di ScanSek yaa! Selamat berbuka! 🥰',
        details: details, now: now, lastInput: null,
      );
    }

    // === AKTIVITAS (16:00) — selalu jalan walau puasa ===
    await _scheduleSmartNotif(
      id: 10005, hour: 16, minute: 0,
      title: 'Heyyy, niat sehat gak nihh??',
      body: 'Kamu itu loh belum ada pergerakan, yuk aktivitas dulu biar sehat 🏃',
      details: details, now: now, lastInput: lastActivityInput,
    );

    // === BMI Weekly (19:30) ===
    // Find the 7th day after last update
    final targetDate = lastBodyMetricsUpdate.add(const Duration(days: 7));
    var baseBmiTime = tz.TZDateTime(tz.local, targetDate.year, targetDate.month, targetDate.day, 19, 30);
    
    // If the 7th day has already passed (or is today but past 19:30), start scheduling from today/tomorrow
    if (baseBmiTime.isBefore(now)) {
      baseBmiTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, 19, 30);
      if (baseBmiTime.isBefore(now)) {
        baseBmiTime = baseBmiTime.add(const Duration(days: 1));
      }
    }
    
    // Schedule for 7 consecutive days starting from baseBmiTime
    for (int i = 0; i < 7; i++) {
      final scheduleTime = baseBmiTime.add(Duration(days: i));
      final scheduleId = 10006 + (i * 100);
      await _notifications.zonedSchedule(
        scheduleId,
        'Waktunya update BB & TB lohh!',
        'Udah seminggu nih, waktunya cek dan update data BB & TB kamu!🕖',
        scheduleTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Lebih kalem
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
      );
    }
  }

  /// Cancel specific system default by ID
  Future<void> cancelSystemDefault(int id) async {
    await _notifications.cancel(id);
  }

  /// Satu fungsi untuk refresh semua notif sistem.
  /// Baca timestamp dari local storage, lalu panggil scheduleSystemDefaults.
  Future<void> refreshSystemNotifications() async {
    final storage = StorageService();
    final user = await storage.getUserData();
    final lastUpdateStr = user?['lastBodyMetricsUpdate'] ?? user?['createdAt'];
    final lastBodyMetrics = lastUpdateStr != null
        ? DateTime.tryParse(lastUpdateStr.toString()) ?? DateTime.now()
        : DateTime.now();

    await scheduleSystemDefaults(
      lastBodyMetricsUpdate: lastBodyMetrics,
      lastFoodInput: storage.lastFoodInputTime,
      lastWaterInput: storage.lastWaterInputTime,
      lastActivityInput: storage.lastActivityInputTime,
    );
  }

  // ==========================================
  // PERSONAL REMINDER HELPERS
  // ==========================================

  /// Get scheduled times based on reminder configuration
  List<tz.TZDateTime> _getScheduledTimes(ReminderModel reminder) {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      reminder.time.hour,
      reminder.time.minute,
    );

    switch (reminder.frequency) {
      case ReminderFrequency.daily:
        if (scheduledTime.isBefore(now)) {
          return [scheduledTime.add(const Duration(days: 1))];
        }
        return [scheduledTime];
      case ReminderFrequency.once:
        if (scheduledTime.isBefore(now)) {
          return [scheduledTime.add(const Duration(days: 1))];
        }
        return [scheduledTime];
      case ReminderFrequency.custom:
        return _getCustomDaySchedules(reminder, now);
    }
  }

  /// Get schedules for custom days
  List<tz.TZDateTime> _getCustomDaySchedules(
    ReminderModel reminder,
    tz.TZDateTime now,
  ) {
    final schedules = <tz.TZDateTime>[];
    for (final day in reminder.customDays) {
      final currentWeekday = now.weekday;
      int daysUntil = day - currentWeekday;
      if (daysUntil < 0) daysUntil += 7;
      final scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + daysUntil,
        reminder.time.hour,
        reminder.time.minute,
      );
      schedules.add(scheduledTime);
    }
    return schedules;
  }

  /// Get match components for scheduling
  DateTimeComponents? _getMatchComponents(ReminderFrequency frequency) {
    switch (frequency) {
      case ReminderFrequency.daily:
        return DateTimeComponents.time;
      case ReminderFrequency.once:
        return null;
      case ReminderFrequency.custom:
        return DateTimeComponents.dayOfWeekAndTime;
    }
  }

  /// Get notification body based on reminder type
  String _getNotificationBody(ReminderType type) {
    switch (type) {
      case ReminderType.water:
        return 'Jangan lupa minum yaa bestie, biar sehat terus😘';
      case ReminderType.activity:
        return 'Ayo aktivitas fisik! Biar badanmu makin fit dan keren😘';
    }
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    if (response.payload == 'activity_tracking') {
      Get.toNamed('/start-activity');
    }
  }
}
