import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sverd_barbershop/core/services/storage_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // 1. Singleton pattern standar
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // 2. Ambil box Hive dari StorageService Anda
  final Box _box = StorageService().box;

  // 3. Definisikan konstanta untuk ID channel dan key Hive
  static const String _channelId = 'sverd_reminder_channel';
  static const String _channelName = 'Sverd Barbershop Reminder';
  static const String _channelDesc = 'Pengingat potong rambut berkala';

  static const String _hiveEnabledKey = 'notification_enabled';
  static const String _hiveIntervalKey = 'notification_interval_days';
  static const String _hiveNextDateKey = 'notification_next_date';

  /// Panggil ini di main.dart
  static Future<void> initialize() async {
    tz.initializeTimeZones();
    // Atur zona waktu lokal Anda
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

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

    // Inisialisasi instance
    await _instance._notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _instance._onNotificationTapped,
    );

    await _instance._requestPermissions();
    print('✅ NotificationService Initialized');
  }

  /// Meminta izin notifikasi (wajib untuk iOS & Android 13+)
  Future<void> _requestPermissions() async {
    try {
      // Android 13+
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      // iOS
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      print('Error requesting permissions: $e');
    }
  }

  /// Handler saat notifikasi di-tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped with payload: ${response.payload}');
    // Di masa depan, Anda bisa menambahkan navigasi ke halaman promo, dll.
  }

  // --- GETTER UNTUK PENGATURAN ---

  bool isNotificationEnabled() {
    return _box.get(_hiveEnabledKey, defaultValue: false);
  }

  int getNotificationInterval() {
    // Default ke 30 hari jika tidak ada, sesuai permintaan Anda (14, 30, 60)
    return _box.get(_hiveIntervalKey, defaultValue: 30);
  }

  // --- FUNGSI UTAMA ---

  /// Menjadwalkan notifikasi berdasarkan interval hari
  Future<void> scheduleRepeatingNotification(
      {required int intervalDays}) async {
    // Batalkan notifikasi lama sebelum mengatur yang baru
    await _notifications.cancelAll();

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    // Jadwalkan untuk 'intervalDays' dari sekarang, pada jam 10 pagi
    final tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      10, // Jam 10 pagi
    ).add(Duration(days: intervalDays));

    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notifications.zonedSchedule(
      0, // ID notifikasi
      'Waktunya Potong Rambut!',
      'Sudah $intervalDays hari! Saatnya kembali ke Sverd Barbershop untuk tampil keren lagi.',
      scheduledDate,
      notificationDetails,
      // --- PERBAIKAN 1 ---
      // Menggunakan alarm "tidak tepat" agar tidak memerlukan izin khusus
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    // Simpan status ke Hive
    await _box.put(_hiveEnabledKey, true);
    await _box.put(_hiveIntervalKey, intervalDays);
    await _box.put(_hiveNextDateKey, scheduledDate.toIso8601String());

    print('🔔 Notification scheduled for: $scheduledDate');
  }

  /// Membatalkan semua notifikasi dan menghapus dari Hive
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();

    // Hapus semua pengaturan terkait notifikasi
    await _box.put(_hiveEnabledKey, false);
    await _box.delete(_hiveIntervalKey);
    await _box.delete(_hiveNextDateKey);

    print('🔕 All notifications cancelled and settings cleared.');
  }

  /// Hanya update interval di Hive (jika notifikasi sedang non-aktif)
  Future<void> updateNotificationInterval(int newIntervalDays) async {
    await _box.put(_hiveIntervalKey, newIntervalDays);
    print(
        'Notification interval updated to $newIntervalDays days (no reschedule)');
  }

  /// Periksa dan jadwalkan ulang saat aplikasi dibuka
  Future<void> rescheduleNotificationOnBoot() async {
    final bool isEnabled = isNotificationEnabled();
    if (!isEnabled) {
      print('Notifications are disabled. No reschedule needed.');
      return;
    }

    final int interval = getNotificationInterval();
    final String? nextDateString = _box.get(_hiveNextDateKey);
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime nextScheduleDate;

    if (nextDateString == null) {
      // Tidak ada tanggal tersimpan, buat baru
      print('No next date found. Scheduling new notification.');
      nextScheduleDate =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, 10)
              .add(Duration(days: interval));
    } else {
      tz.TZDateTime savedDate;
      try {
        savedDate = tz.TZDateTime.parse(tz.local, nextDateString);
      } catch (e) {
        // Handle error parsing, buat tanggal baru
        print('Error parsing saved date. Scheduling new one.');
        savedDate = now.subtract(const Duration(days: 1)); // Anggap sudah lewat
      }

      if (savedDate.isBefore(now)) {
        // Tanggal sudah lewat, buat tanggal baru
        print('Saved date $savedDate is in the past. Scheduling new one.');
        nextScheduleDate =
            tz.TZDateTime(tz.local, now.year, now.month, now.day, 10)
                .add(Duration(days: interval));
      } else {
        // Tanggal masih di masa depan, kita jadwalkan ulang untuk tanggal tsb
        print('Rescheduling notification for saved date: $savedDate');
        nextScheduleDate = savedDate;
      }
    }

    // Batalkan notifikasi lama (jika ada) dan set yang baru
    await _notifications.cancelAll();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _notifications.zonedSchedule(
      0, // ID notifikasi
      'Waktunya Potong Rambut!',
      'Sudah $interval hari! Saatnya kembali ke Sverd Barbershop.',
      nextScheduleDate,
      notificationDetails,
      // --- PERBAIKAN 2 ---
      // Menggunakan alarm "tidak tepat" agar tidak memerlukan izin khusus
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    // Update Hive dengan tanggal baru
    await _box.put(_hiveNextDateKey, nextScheduleDate.toIso8601String());
    print('🔄 Notification rescheduled on boot for: $nextScheduleDate');
  }

  /// Menampilkan notifikasi tes instan (5 detik)
  Future<void> showTestNotification() async {
    try {
      final tz.TZDateTime scheduledDate =
          tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));

      const NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'sverd_test_channel',
          'Sverd Test Channel',
          channelDescription: 'Channel untuk tes notifikasi',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notifications.zonedSchedule(
        999, // ID notifikasi tes
        'Test Notifikasi Sverd',
        'Ini adalah notifikasi tes, akan muncul dalam 5 detik. 💈',
        scheduledDate,
        notificationDetails,
        // --- PERBAIKAN 3 ---
        // Menggunakan alarm "tidak tepat" agar tidak memerlukan izin khusus
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      print('Test notification scheduled in 5 seconds.');
    } catch (e) {
      print('Error showing test notification: $e');
    }
  }
}
