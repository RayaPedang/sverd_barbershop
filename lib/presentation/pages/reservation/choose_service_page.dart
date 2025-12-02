import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sverd_barbershop/core/models/branch.dart';
import 'package:sverd_barbershop/core/models/service.dart';
import 'package:sverd_barbershop/core/services/api_service.dart';
import 'package:sverd_barbershop/core/theme/colors.dart';
import 'package:sverd_barbershop/presentation/pages/reservation/make_reservation_page.dart';

class ChooseServicePage extends StatefulWidget {
  final Branch branch;

  const ChooseServicePage({super.key, required this.branch});

  @override
  State<ChooseServicePage> createState() => _ChooseServicePageState();
}

class _ChooseServicePageState extends State<ChooseServicePage> {
  final ApiService _apiService = ApiService();
  List<Service> _services = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      print('[API] Fetching services from: ChooseServicePage');
      final List<Service> services = await _apiService.fetchServices();

      if (mounted) {
        setState(() {
          _services = services;
          _isLoading = false;
        });
      }

      print('[API] Berhasil load ${services.length} layanan');
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _error = 'Request timeout!\nPastikan Laragon running.';
          _isLoading = false;
        });
      }
      print('[API] Timeout');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _isLoading = false;
        });
      }
      print('[API] Error: $e');
    }
  }

  void _selectService(Service service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MakeReservationPage(branch: widget.branch, service: service),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pilih Layanan',
          style: TextStyle(
            color: kTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kPrimaryColor),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: kTextColor, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchServices,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: kLightTextColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_services.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada layanan tersedia',
          style: TextStyle(color: kSecondaryTextColor),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.separated(
        itemCount: _services.length,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final service = _services[index];
          return _buildServiceCard(service);
        },
      ),
    );
  }

  Widget _buildServiceCard(Service service) {
    return InkWell(
      onTap: () => _selectService(service),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: kDarkBlockColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // PERBAIKAN: Bungkus Text dengan Expanded untuk mencegah overflow
            Expanded(
              child: Text(
                service.name,
                style: const TextStyle(color: kLightTextColor, fontSize: 18),
                overflow: TextOverflow
                    .ellipsis, // Tambahkan ellipsis jika kepanjangan
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8), // Beri jarak sedikit
            const Icon(Icons.chevron_right, color: kLightTextColor, size: 28),
          ],
        ),
      ),
    );
  }
}
