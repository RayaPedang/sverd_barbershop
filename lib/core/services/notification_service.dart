import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sverd_barbershop/core/services/storage_service.dart';

// --- PERBAIKAN IMPORT DISINI ---
// Kita ganti aliasnya menjadi 'tzData' agar tidak bentrok dengan 'tz' di bawahnya
import 'package:timezone/data/latest_all.dart' as tzData;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  final Box _box = StorageService().box;

  static const String _channelId = 'sverd_reminder_channel';
  static const String _channelName = 'Sverd Barbershop Reminder';
  static const String _channelDesc = 'Pengingat potong rambut berkala';

  static const String _hiveEnabledKey = 'notification_enabled';
  static const String _hiveIntervalKey = 'notification_interval_days';
  static const String _hiveNextDateKey = 'notification_next_date';

  static Future<void> initialize() async {
    // --- PERBAIKAN PEMANGGILAN DISINI ---
    // Menggunakan alias 'tzData' yang baru
    tzData.initializeTimeZones();

    try {
      // Menggunakan alias 'tz' untuk fungsi lokasi
      final location = tz.getLocation('Asia/Jakarta');
      tz.setLocalLocation(location);
    } catch (e) {
      print('Timezone error (fallback to UTC): $e');
      tz.setLocalLocation(tz.UTC);
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _instance._notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle tap event here
      },
    );

    await _instance._requestPermissions();
    print('✅ NotificationService Initialized');
  }

  Future<void> _requestPermissions() async {
    try {
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      print('Error requesting permissions: $e');
    }
  }

  bool isNotificationEnabled() {
    return _box.get(_hiveEnabledKey, defaultValue: false);
  }

  int getNotificationInterval() {
    return _box.get(_hiveIntervalKey, defaultValue: 30);
  }

  // --- [DEBUGGING SECTION] ---
  // Ubah jam/menit di bawah ini untuk mengetes notifikasi
  Future<void> scheduleRepeatingNotification(
      {required int intervalDays}) async {
    await _notifications.cancelAll();

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // Ganti angka jam (10) dan menit (0) jika ingin tes
    // Contoh Tes: now.add(Duration(minutes: 2)) -> untuk notif 2 menit lagi
    final tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      10, // Jam 10 pagi
      0, // Menit 0
    ).add(Duration(days: intervalDays));

    await _notifications.zonedSchedule(
      0,
      'Waktunya Potong Rambut! ✂️',
      'Sudah $intervalDays hari nih. Yuk booking lagi di SVERD!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    await _box.put(_hiveEnabledKey, true);
    await _box.put(_hiveIntervalKey, intervalDays);
    await _box.put(_hiveNextDateKey, scheduledDate.toIso8601String());

    print('🔔 Notification scheduled for: $scheduledDate');
  }

  Future<void> updateNotificationInterval(int newIntervalDays) async {
    await _box.put(_hiveIntervalKey, newIntervalDays);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    await _box.put(_hiveEnabledKey, false);
    await _box.delete(_hiveNextDateKey);
    print('🔕 All notifications cancelled.');
  }

  Future<void> showTestNotification() async {
    // Fungsi tes manual (opsional)
  }
}
