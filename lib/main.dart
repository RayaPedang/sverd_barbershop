import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sverd_barbershop/presentation/pages/auth/auth_page.dart'; // <-- DIMODIFIKASI
import 'package:sverd_barbershop/core/services/notification_service.dart'; // <-- DIMODIFIKASI
import 'package:sverd_barbershop/core/services/storage_service.dart'; // <-- IMPORT BARU
import 'package:sverd_barbershop/core/theme/colors.dart'; // <-- DIMODIFIKASI

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi StorageService (Hive) kita
  await StorageService().initialize(); // <-- DIMODIFIKASI
  final box = StorageService().box; // <-- DIMODIFIKASI (menggunakan getter)

  // --- MODIFIKASI DISINI ---
  // Kita panggil metode 'initialize' statis yang baru.
  // Ini akan membuat dan menginisialisasi instance singleton-nya.
  await NotificationService.initialize();
  // -------------------------

  if (!box.containsKey('notification_enabled')) {
    // Sekarang kita bisa panggil instance-nya dengan aman
    await NotificationService().scheduleHaircutReminder(intervalDays: 30);
    print('Auto-enabled haircut reminder notification');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sverd Barbershop',
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
        },
      ),
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: kBackgroundColor,
        fontFamily: GoogleFonts.poppins().fontFamily,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: kBackgroundColor,
          iconTheme: IconThemeData(color: kTextColor),
          titleTextStyle: TextStyle(
            color: kTextColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: kTextColor),
          bodyLarge: TextStyle(color: kTextColor),
          headlineSmall: TextStyle(color: kTextColor),
          titleLarge: TextStyle(color: kTextColor),
        ),
      ),
      home: const AuthPage(),
    );
  }
}
