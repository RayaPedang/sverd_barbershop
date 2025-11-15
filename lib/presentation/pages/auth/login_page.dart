import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sverd_barbershop/presentation/widgets/my_button.dart';
import 'package:sverd_barbershop/presentation/widgets/my_textfield.dart';
import 'package:sverd_barbershop/core/theme/colors.dart';
import 'package:sverd_barbershop/presentation/pages/main_page.dart';
import 'package:sverd_barbershop/core/utils/validators.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onToggle;
  const LoginPage({super.key, required this.onToggle});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _obscurePassword = true;

  void signIn() {
    final box = Hive.box('sverd_box');
    String email = emailController.text.trim();
    String password = passwordController.text;

    // Validasi 1: Form kosong
    if (email.isEmpty || password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan Password harus diisi!")),
      );
      return;
    }

    //VALIDASI BARU 1: Format Email
    if (!Validators.isEmailValid(email)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Format email tidak valid!")),
      );
      return;
    }

    //VALIDASI BARU 2: Panjang Password
    if (password.length < 6) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password minimal harus 6 karakter!")),
      );
      return;
    }

    // Validasi 3: Cek email di Hive
    if (!box.containsKey(email)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Email tidak ditemukan!")));
      return;
    }

    final userData = box.get(email);
    String storedPassword = userData['password'];

    // Validasi 4: Cek password
    if (password == storedPassword) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login Berhasil!")));

      String username = userData['username'];
      box.put('currentUser', {'email': email, 'username': username});

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainPage(username: username)),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Password salah!")));
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
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
                Image.asset(
                  'assets/images/logo_sverd.png',
                  height: 64,
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
                const Text(
                  "Login",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kLightTextColor,
                  ),
                ),
                const SizedBox(height: 32),

                // EMAIL & PASSWORD TEXTFIELDS
                MyTextField(
                  controller: emailController,
                  labelText: "Email",
                  labelColor: kLightTextColor,
                  fillColor: kDarkComponentColor,
                ),
                const SizedBox(height: 16),
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

                const SizedBox(height: 24),
                MyButton(text: "Login", onTap: signIn),
                const SizedBox(height: 24),
                const Text(
                  "or",
                  style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an Account? ",
                      style: TextStyle(color: kLightTextColor),
                    ),
                    GestureDetector(
                      onTap: widget.onToggle,
                      child: const Text(
                        "Register",
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
