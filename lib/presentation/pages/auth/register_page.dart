// lib/presentation/pages/auth/register_page.dart

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sverd_barbershop/presentation/widgets/my_button.dart';
import 'package:sverd_barbershop/presentation/widgets/my_textfield.dart';
import 'package:sverd_barbershop/core/theme/colors.dart';
import 'package:sverd_barbershop/core/utils/validators.dart'; // <-- IMPORT BARU

class RegisterPage extends StatefulWidget {
  final VoidCallback onToggle;

  // --- PERBAIKAN DI SINI ---
  // Tanda titik dua (:) setelah 'required' telah dihapus.
  const RegisterPage({super.key, required this.onToggle});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controllers
  final userNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Password visibility
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // --- FUNGSI VALIDASI EMAIL (DIHAPUS) ---
  // bool _isEmailValid(String email) { ... }

  void signUp() async {
    final box = Hive.box('sverd_box');

    // Ambil data dari controllers
    String username = userNameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;

    // Validasi 1: Form kosong
    if (username.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Semua form harus diisi!")));
      return;
    }

    // --- VALIDASI BARU 1: Format Email (DIMODIFIKASI) ---
    if (!Validators.isEmailValid(email)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Format email tidak valid!")),
      );
      return;
    }

    // --- VALIDASI BARU 2: Panjang Password ---
    if (password.length < 6) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password minimal harus 6 karakter!")),
      );
      return;
    }

    // Validasi 2: Password cocok
    if (password != confirmPassword) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password konfirmasi tidak cocok!")),
      );
      return;
    }

    // Validasi 3: Email sudah terdaftar
    if (box.containsKey(email)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email ini sudah terdaftar!")),
      );
      return;
    }

    // Simpan data ke Hive
    await box.put(email, {'username': username, 'password': password});

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Registrasi Berhasil! Silakan Login.")),
    );

    widget.onToggle();
  }

  @override
  void dispose() {
    userNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBlockColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Sverd
                Image.asset(
                  'assets/images/logo_sverd.png',
                  height: 48,
                  color: kLightTextColor,
                  errorBuilder: (context, error, stackTrace) {
                    return const CircleAvatar(
                      radius: 40,
                      backgroundColor: kPrimaryColor,
                      child: Icon(
                        Icons.cut_sharp,
                        size: 40,
                        color: kLightTextColor,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),
                // Judul
                const Text(
                  "Register",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kLightTextColor,
                  ),
                ),
                const SizedBox(height: 32),

                // Form User Name
                MyTextField(
                  controller: userNameController,
                  labelText: "Username",
                  labelColor: kLightTextColor,
                  fillColor: kDarkComponentColor,
                ),
                const SizedBox(height: 16),

                // Form Email
                MyTextField(
                  controller: emailController,
                  labelText: "Email",
                  labelColor: kLightTextColor,
                  fillColor: kDarkComponentColor,
                ),
                const SizedBox(height: 16),

                // Form Password
                MyTextField(
                  controller: passwordController,
                  labelText: "Password",
                  obscureText: _obscurePassword,
                  labelColor: kLightTextColor,
                  fillColor: kDarkComponentColor,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: kSecondaryTextColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Form Confirm Password
                MyTextField(
                  controller: confirmPasswordController,
                  labelText: "Confirm Password",
                  obscureText: _obscureConfirmPassword,
                  labelColor: kLightTextColor,
                  fillColor: kDarkComponentColor,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: kSecondaryTextColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Tombol Sign Up
                MyButton(text: "Register", onTap: signUp),
                const SizedBox(height: 24),

                // "or"
                const Text("or", style: TextStyle(color: kSecondaryTextColor)),
                const SizedBox(height: 12),

                // Link ke Sign In
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an Account? ",
                      style: TextStyle(color: kLightTextColor),
                    ),
                    GestureDetector(
                      onTap: widget.onToggle,
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          color: Color.fromARGB(255, 98, 130, 255),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
