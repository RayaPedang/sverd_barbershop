import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sverd_barbershop/core/services/storage_service.dart';
// ignore: depend_on_referenced_packages
import 'package:timezone/data/latest_all.dart' as tz;
// ignore: depend_on_referenced_packages
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // 1. Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // 2. Ambil box Hive dari StorageService
  final Box _box = StorageService().box;

  // 3. Konstanta
  static const String _channelId = 'sverd_reminder_channel';
  static const String _channelName = 'Sverd Barbershop Reminder';
  static const String _channelDesc = 'Pengingat potong rambut berkala';

  static const String _hiveEnabledKey = 'notification_enabled';
  static const String _hiveIntervalKey = 'notification_interval_days';
  static const String _hiveNextDateKey = 'notification_next_date';

  /// Inisialisasi service
  static Future<void> initialize() async {
    tz.initializeTimeZones();

    // Set lokasi default ke Jakarta agar tidak error 'LateInitializationError'
    try {
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

  // --- METHOD YANG DIBUTUHKAN OLEH PROFILE_TAB.DART ---

  /// 1. Cek apakah notifikasi aktif
  bool isNotificationEnabled() {
    return _box.get(_hiveEnabledKey, defaultValue: false);
  }

  /// 2. Ambil interval (default 30 hari)
  int getNotificationInterval() {
    return _box.get(_hiveIntervalKey, defaultValue: 30);
  }

  /// 3. Jadwalkan notifikasi berulang
  Future<void> scheduleRepeatingNotification(
      {required int intervalDays}) async {
    // Batalkan jadwal lama
    await _notifications.cancelAll();

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // Jadwalkan X hari ke depan jam 10:00 pagi
    final tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      10,
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
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    // Simpan state ke Hive
    await _box.put(_hiveEnabledKey, true);
    await _box.put(_hiveIntervalKey, intervalDays);
    await _box.put(_hiveNextDateKey, scheduledDate.toIso8601String());

    print('🔔 Notification scheduled for: $scheduledDate');
  }

  /// 4. Update interval tanpa menjadwalkan ulang (jika switch mati)
  Future<void> updateNotificationInterval(int newIntervalDays) async {
    await _box.put(_hiveIntervalKey, newIntervalDays);
  }

  /// 5. Batalkan semua notifikasi
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    await _box.put(_hiveEnabledKey, false);
    await _box.delete(_hiveNextDateKey);
    print('🔕 All notifications cancelled.');
  }

  /// 6. Tampilkan notifikasi tes (muncul dalam 5 detik)
  Future<void> showTestNotification() async {
    final tz.TZDateTime scheduledDate =
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));

    await _notifications.zonedSchedule(
      999,
      'Test Notifikasi SVERD',
      'Ini contoh notifikasi pengingat cukur rambut! 💈',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Channel',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
