import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sverd_barbershop/presentation/pages/splash/splash_page.dart';
import 'package:sverd_barbershop/core/services/notification_service.dart';
import 'package:sverd_barbershop/core/services/storage_service.dart';
import 'package:sverd_barbershop/core/theme/colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi StorageService (Hive)
  await StorageService().initialize();
  final box = StorageService().box;

  // 2. Inisialisasi Notification Service
  await NotificationService.initialize();

  // 3. Jadwalkan notifikasi default jika belum ada
  if (!box.containsKey('notification_enabled')) {
    // PERBAIKAN DISINI: Memanggil method yang benar 'scheduleRepeatingNotification'
    await NotificationService().scheduleRepeatingNotification(intervalDays: 30);
    debugPrint('Auto-enabled haircut reminder notification');
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
      // Menggunakan SplashPage sebagai halaman awal
      home: const SplashPage(),
    );
  }
}
