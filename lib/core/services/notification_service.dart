import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sverd_barbershop/core/services/storage_service.dart';
import 'package:timezone/data/latest_all.dart' as tzData;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

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
    tzData.initializeTimeZones();

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
        print('📱 Notification tapped: ${details.payload}');
      },
    );

    await _instance._requestPermissions();
    print('✅ NotificationService Initialized');
  }

  Future<void> _requestPermissions() async {
    try {
      // Request permission notifikasi biasa
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      // Request permission untuk exact alarm (Android 12+)
      if (await Permission.scheduleExactAlarm.isDenied) {
        final status = await Permission.scheduleExactAlarm.request();
        if (status.isDenied) {
          print('⚠️ Exact alarm permission denied');
        } else if (status.isGranted) {
          print('✅ Exact alarm permission granted');
        }
      }

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

  Future<void> scheduleRepeatingNotification(
      {required int intervalDays}) async {
    // Cek permission dulu
    final permissionStatus = await Permission.scheduleExactAlarm.status;

    if (permissionStatus.isDenied || permissionStatus.isPermanentlyDenied) {
      print('⚠️ Cannot schedule exact alarm - permission not granted');
      await _scheduleInexactNotification(intervalDays: intervalDays);
      return;
    }

    await _notifications.cancelAll();

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    final tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      10, // Jam 10 pagi
      0, // Menit 0
    ).add(Duration(days: intervalDays));

    try {
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
            enableLights: true,
            enableVibration: true,
            playSound: true,
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
    } catch (e) {
      print('❌ Error scheduling exact notification: $e');
      await _scheduleInexactNotification(intervalDays: intervalDays);
    }
  }

  Future<void> _scheduleInexactNotification({required int intervalDays}) async {
    await _notifications.cancelAll();

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    final tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      10,
      0,
    ).add(Duration(days: intervalDays));

    try {
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
            enableLights: true,
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      await _box.put(_hiveEnabledKey, true);
      await _box.put(_hiveIntervalKey, intervalDays);
      await _box.put(_hiveNextDateKey, scheduledDate.toIso8601String());

      print('🔔 Inexact notification scheduled for: $scheduledDate');
    } catch (e) {
      print('❌ Error scheduling inexact notification: $e');
    }
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

  /// Tes notifikasi instan (muncul langsung)
  Future<void> showTestNotificationInstant() async {
    try {
      await _notifications.show(
        999, // ID unik untuk tes
        'Waktunya Menjadi TAMPAN! ✂️',
        'Kamu perlu potong rambut nih! Ayo booking di SVERD sekarang juga!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Tes notifikasi instant',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableLights: true,
            enableVibration: true,
            playSound: true,
            styleInformation: BigTextStyleInformation(
              'Rambutmu jelek! Ayo booking potong rambut di SVERD sekarang juga! ✂️',
            ),
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      print('✅ Test notification sent instantly');
    } catch (e) {
      print('❌ Error showing instant notification: $e');
      rethrow;
    }
  }

  /// Tes notifikasi delay
  Future<void> showTestNotificationDelayed({int delaySeconds = 5}) async {
    try {
      final tz.TZDateTime scheduledDate =
          tz.TZDateTime.now(tz.local).add(Duration(seconds: delaySeconds));

      await _notifications.zonedSchedule(
        998, // ID unik untuk tes delayed
        'Waktunya Menjadi TAMPAN! ✂️',
        'Kamu perlu potong rambut nih! Ayo booking di SVERD sekarang juga!',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Tes notifikasi delayed',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableLights: true,
            enableVibration: true,
            playSound: true,
            styleInformation: BigTextStyleInformation(
              'Rambutmu jelek! Ayo booking potong rambut di SVERD sekarang juga! ✂️',
            ),
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

      print(
          '🔔 Test notification scheduled for: $scheduledDate ($delaySeconds seconds from now)');
      print('👉 Tutup aplikasi untuk mengetes apakah notifikasi muncul!');
    } catch (e) {
      print('❌ Error scheduling delayed notification: $e');

      // Fallback ke inexact jika exact gagal
      try {
        final tz.TZDateTime scheduledDate =
            tz.TZDateTime.now(tz.local).add(Duration(seconds: delaySeconds));

        await _notifications.zonedSchedule(
          998,
          'Waktunya Menjadi TAMPAN! ✂️',
          'Kamu perlu potong rambut nih! Ayo booking di SVERD sekarang juga!',
          scheduledDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: 'Tes notifikasi delayed',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              enableLights: true,
              enableVibration: true,
              playSound: true,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexact,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        print('🔔 Fallback to inexact mode successful');
      } catch (e2) {
        print('❌ Even inexact mode failed: $e2');
        rethrow;
      }
    }
  }

  /// Batalkan tes notifikasi
  Future<void> cancelTestNotifications() async {
    try {
      await _notifications.cancel(999); // Cancel instant test
      await _notifications.cancel(998); // Cancel delayed test
      print('🔕 Test notifications cancelled');
    } catch (e) {
      print('❌ Error cancelling test notifications: $e');
    }
  }

  /// Cek pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      print('📋 Pending notifications: ${pending.length}');
      for (var notif in pending) {
        print('  - ID: ${notif.id}, Title: ${notif.title}');
      }
      return pending;
    } catch (e) {
      print('❌ Error getting pending notifications: $e');
      return [];
    }
  }
}
