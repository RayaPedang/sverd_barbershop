import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sverd_barbershop/core/constants/api_constants.dart';
import 'package:sverd_barbershop/core/models/branch.dart';
import 'package:sverd_barbershop/core/models/info_news.dart';
import 'package:sverd_barbershop/core/models/service.dart';

// Kelas ini akan menangani semua panggilan HTTP ke API PHP Anda.
class ApiService {
  final http.Client _client;

  // Anda dapat menyediakan client jika diperlukan (misal untuk testing),
  // atau biarkan ia membuat client-nya sendiri.
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Mengambil daftar semua cabang barbershop
  Future<List<Branch>> fetchBranches() async {
    final uri = Uri.parse(ApiConstants.getBranches);
    try {
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((json) => Branch.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        // Melempar error spesifik berdasarkan status code
        throw Exception('HTTP Error ${response.statusCode}: ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Request timeout. Pastikan server API Anda berjalan.');
    } on http.ClientException catch (e) {
      throw Exception('Koneksi gagal. Periksa jaringan Anda. Error: $e');
    } catch (e) {
      throw Exception('Error tidak terduga saat mengambil data cabang: $e');
    }
  }

  /// Mengambil daftar semua info & berita
  Future<List<InfoNews>> fetchInfoNews() async {
    final uri = Uri.parse(ApiConstants.getInfoNews);
    try {
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((json) => InfoNews.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('HTTP Error ${response.statusCode}: ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Request timeout. Pastikan server API Anda berjalan.');
    } on http.ClientException catch (e) {
      throw Exception('Koneksi gagal. Periksa jaringan Anda. Error: $e');
    } catch (e) {
      throw Exception('Error tidak terduga saat mengambil info berita: $e');
    }
  }

  /// Mengambil daftar semua layanan (services)
  Future<List<Service>> fetchServices() async {
    final uri = Uri.parse(ApiConstants.getServices);
    try {
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((json) => Service.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('HTTP Error ${response.statusCode}: ${response.body}');
      }
    } on TimeoutException {
      throw Exception('Request timeout. Pastikan server API Anda berjalan.');
    } on http.ClientException catch (e) {
      throw Exception('Koneksi gagal. Periksa jaringan Anda. Error: $e');
    } catch (e) {
      throw Exception('Error tidak terduga saat mengambil layanan: $e');
    }
  }
}
