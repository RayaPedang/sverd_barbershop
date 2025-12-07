import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static const String _boxName = 'sverd_box';
  late final Box _box;

  // Instance untuk Secure Storage
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String currentUserKey = 'currentUser';
  static const String reservationsPrefix = 'reservations_';

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<void> initialize() async {
    await Hive.initFlutter();

    // 1. Cek apakah kunci enkripsi sudah ada di Secure Storage
    String? encryptionKeyString = await _secureStorage.read(key: 'hive_key');

    // 2. Jika belum ada, buat kunci baru dan simpan
    if (encryptionKeyString == null) {
      final key = Hive.generateSecureKey();
      // Konversi list byte ke string base64 agar bisa disimpan
      await _secureStorage.write(key: 'hive_key', value: base64UrlEncode(key));
      encryptionKeyString = base64UrlEncode(key);
    }

    // 3. Decode string kembali menjadi List<int> untuk digunakan Hive
    final encryptionKeyUint8List = base64Url.decode(encryptionKeyString);

    // 4. Buka box dengan parameter encryptionCipher (Menggunakan AES-256)
    try {
      _box = await Hive.openBox(
        _boxName,
        encryptionCipher: HiveAesCipher(encryptionKeyUint8List),
      );
      print('✅ StorageService Initialized with AES-256 Encryption');
    } catch (e) {
      // Jika terjadi error (misal data lama tidak terenkripsi),
      // Kita mungkin perlu menghapus box lama (HATI-HATI: Data hilang)
      print('❌ Error opening encrypted box: $e');
      await Hive.deleteBoxFromDisk(_boxName);
      // Coba buka lagi
      _box = await Hive.openBox(
        _boxName,
        encryptionCipher: HiveAesCipher(encryptionKeyUint8List),
      );
    }
  }

  Box get box => _box;
}
