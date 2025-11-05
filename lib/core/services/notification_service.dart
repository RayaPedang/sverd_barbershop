import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:hive_flutter/hive_flutter.dart';

class NotificationService {
  // --- MODIFIKASI SINGLETON PATTERN ---

  // 1. Buat instance 'late' dan private
  static late final NotificationService _instance;

  // 2. Buat factory constructor yang mengembalikan instance
  factory NotificationService() => _instance;

  // 3. Buat private constructor
  NotificationService._internal();

  // 4. Buat plugin instance-nya
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // 5. Buat metode initialize STATIC
  static Future<void> initialize() async {
    // 6. Buat dan inisialisasi instance-nya DI SINI
    _instance = NotificationService._internal();

    // 7. Inisialisasi Timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta')); // WIB

    // 8. Setting platform
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

    // 9. Inisialisasi plugin-nya menggunakan instance
    await _instance._notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _instance._onNotificationTapped,
    );

    // 10. Request permission menggunakan instance
    await _instance._requestPermissions();
    print('✅ NotificationService Initialized');
  }

  // --- SEMUA METODE LAIN SEKARANG MENJADI METODE INSTANCE (NON-STATIC) ---

  /// Request notification permissions (private)
  Future<void> _requestPermissions() async {
    final bool? granted = await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    print('導 Notification permission granted: $granted');
  }

  /// Handle notification tap (private)
  void _onNotificationTapped(NotificationResponse response) {
    print('粕 Notification tapped: ${response.payload}');
    // TODO: Navigate to specific page if needed
  }

  /// Schedule recurring notification
  Future<void> scheduleHaircutReminder({int intervalDays = 30}) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + 1, // Besok
        10, // Jam 10 pagi
        0, // Menit 0
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(Duration(days: 1));
      }

      print('竢ｰ Scheduling notification for: $scheduledDate');

      await _notifications.zonedSchedule(
        0, // Notification ID
        'Sudah Potong Rambut Belum?',
        'Halo! Sudah waktunya refresh gaya rambut kamu di Sverd Barbershop!',
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'haircut_reminder', // Channel ID
            'Haircut Reminder', // Channel name
            channelDescription: 'Pengingat untuk potong rambut secara berkala',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            styleInformation: const BigTextStyleInformation(
              'Halo! Sudah waktunya refresh gaya rambut kamu di Sverd Barbershop!\n\nBuka aplikasi dan booking sekarang untuk dapatkan promo spesial!',
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      final box = Hive.box('sverd_box');
      // --- PERBAIKAN DI SINI ---
      await box.put('notification_enabled', true);
      await box.put('notification_interval_days', intervalDays);
      await box.put('notification_next_date', scheduledDate.toString());
      // -------------------------

      print('Notification scheduled successfully!');
      print('Next notification: $scheduledDate');
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      final box = Hive.box('sverd_box');
      // --- PERBAIKAN DI SINI ---
      await box.put('notification_enabled', false);
      // -------------------------
      print('All notifications cancelled');
    } catch (e) {
      print('Error cancelling notifications: $e');
    }
  }

  /// Show instant test notification
  Future<void> showTestNotification() async {
    try {
      final tz.TZDateTime scheduledDate = tz.TZDateTime.now(
        tz.local,
      ).add(const Duration(seconds: 5));

      await _notifications.zonedSchedule(
        999, // Test notification ID
        'Test Notifikasi',
        'Ini adalah test notification dari Sverd Barbershop! 宙',
        scheduledDate, // Dijadwalkan 5 detik dari sekarang
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'test_channel',
            'Test Notifications',
            channelDescription: 'Channel untuk test notifikasi',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher', // Tambahkan icon
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      print('Test notification scheduled for 5 seconds from now!');
    } catch (e) {
      print('Error sending test notification: $e');
    }
  }

  // --- Metode helper (getter) ---

  bool isNotificationEnabled() {
    final box = Hive.box('sverd_box');
    return box.get('notification_enabled', defaultValue: false);
  }

  String? getNextNotificationDate() {
    final box = Hive.box('sverd_box');
    return box.get('notification_next_date');
  }

  int getNotificationInterval() {
    final box = Hive.box('sverd_box');
    return box.get('notification_interval_days', defaultValue: 30);
  }

  Future<void> updateNotificationInterval(int newIntervalDays) async {
    await cancelAllNotifications();
    await scheduleHaircutReminder(intervalDays: newIntervalDays);
  }
}
