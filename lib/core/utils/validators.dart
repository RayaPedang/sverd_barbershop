class Validators {
  /// Memvalidasi format email menggunakan Regex.
  /// Logika ini diekstrak dari login_page.dart dan register_page.dart
  static bool isEmailValid(String email) {
    return RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);
  }

  /// Anda dapat menambahkan validator lain di sini di masa depan,
  /// misalnya untuk kekuatan password.
  // static bool isPasswordStrong(String password) {
  //   ...
  // }
}
