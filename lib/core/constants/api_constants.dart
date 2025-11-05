class ApiConstants {
  // Base URL untuk API Anda. IP 10.0.2.2 adalah cara emulator Android
  // mengakses 'localhost' di mesin host (laptop/PC Anda).
  static const String _baseUrl = 'http://localhost/sverd_api';

  // Endpoint untuk mengambil daftar cabang
  static const String getBranches = '$_baseUrl/get_branches.php';

  // Endpoint untuk mengambil daftar info & berita
  static const String getInfoNews = '$_baseUrl/get_info_news.php';

  // Endpoint untuk mengambil daftar layanan/servis
  static const String getServices = '$_baseUrl/get_services.php';
}
