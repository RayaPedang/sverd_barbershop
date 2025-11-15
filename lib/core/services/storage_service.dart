import 'package:hive_flutter/hive_flutter.dart';

/// Service untuk menangani penyimpanan data lokal menggunakan Hive.
class StorageService {
  // Nama box Hive utama.
  static const String _boxName = 'sverd_box';

  // Instance Box yang akan digunakan di seluruh aplikasi.
  late final Box _box;

  /// Kunci untuk data yang disimpan di Hive
  static const String currentUserKey = 'currentUser';

  /// Prefix untuk menyimpan data reservasi per pengguna
  static const String reservationsPrefix = 'reservations_';

  /// Singleton pattern untuk memastikan hanya ada satu instance StorageService
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  //Metode inisialisasi untuk membuka box.
  Future<void> initialize() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    print('✅ StorageService Initialized (Hive Box "$_boxName" opened)');
  }

  /// Menyediakan akses 'read-only' ke box
  Box get box => _box;
}
