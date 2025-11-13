import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sverd_barbershop/core/services/storage_service.dart';
import 'package:sverd_barbershop/core/theme/colors.dart';
import 'package:sverd_barbershop/presentation/pages/auth/auth_page.dart';
import 'package:sverd_barbershop/presentation/pages/main_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // 1. Beri jeda waktu agar logo terlihat (misal 3 detik)
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // 2. Ambil box dari StorageService
    final box = StorageService().box;

    // 3. Cek apakah ada data 'currentUser'
    final currentUser = box.get('currentUser');

    if (currentUser != null && currentUser is Map) {
      // JIKA SUDAH LOGIN: Ambil username dan arahkan ke MainPage
      final String username = currentUser['username'] ?? 'User';

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainPage(username: username),
        ),
      );
    } else {
      // JIKA BELUM LOGIN: Arahkan ke AuthPage (Login/Register)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AuthPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          kBackgroundColor, // Menggunakan warna background putih sesuai tema
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Menampilkan Logo
            Image.asset(
              'assets/images/logo_sverd.png',
              width: 150,
              // Jika logo gagal dimuat, tampilkan teks fallback
              errorBuilder: (context, error, stackTrace) {
                return const Text(
                  "SVERD",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 5,
                    color: kTextColor,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            // Indikator Loading kecil di bawah
            const CircularProgressIndicator(
              color: kPrimaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
