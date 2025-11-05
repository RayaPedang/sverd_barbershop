import 'package:flutter/material.dart';
import 'package:sverd_barbershop/presentation/pages/auth/login_page.dart';
import 'package:sverd_barbershop/presentation/pages/auth/register_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool showLoginPage = true;

  // Method untuk beralih halaman
  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(onToggle: togglePages);
    } else {
      return RegisterPage(onToggle: togglePages);
    }
  }
}
