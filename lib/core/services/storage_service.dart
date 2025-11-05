import 'package:hive_flutter/hive_flutter.dart';

/// Kelas ini bertindak sebagai pembungkus (wrapper) sederhana untuk Hive.
/// Ini membantu mengelola instance Box di satu tempat.
class StorageService {
  // Nama box Hive utama Anda.
  static const String _boxName = 'sverd_box';

  // Instance Box yang akan digunakan di seluruh aplikasi.
  late final Box _box;

  /// Kunci untuk data yang disimpan di Hive
  static const String currentUserKey = 'currentUser';

  /// Kunci prefix untuk reservasi (diikuti dengan email user)
  /// contoh: 'reservations_user@example.com'
  static const String reservationsPrefix = 'reservations_';

  // --- SINGLETON PATTERN ---
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();
  // -------------------------

  /// Metode inisialisasi untuk membuka box.
  /// Harus dipanggil di main.dart sebelum runApp().
  Future<void> initialize() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    print('✅ StorageService Initialized (Hive Box "$_boxName" opened)');
  }

  /// Menyediakan akses 'read-only' ke box
  Box get box => _box;

  /// -- CATATAN --
  ///
  /// Saat ini, logika untuk 'login', 'register', 'saveProfile', 'loadReservations'
  /// masih ada di dalam file UI Anda (pages).
  ///
  /// Ini adalah langkah awal. Nanti, kita bisa memindahkan logika tersebut
  /// ke dalam service ini agar kode UI Anda lebih bersih.
  ///
  /// Contoh:
  ///
  /// Future<void> registerUser(String email, String username, String password) async {
  ///   await _box.put(email, {
  ///     'username': username,
  ///     'password': password,
  ///   });
  /// }
  ///
  /// Map<String, dynamic>? getCurrentUser() {
  ///   return _box.get(currentUserKey);
  /// }
}
