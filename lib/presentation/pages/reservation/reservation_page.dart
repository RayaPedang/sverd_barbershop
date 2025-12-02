import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // Import package geocoding
import 'package:sverd_barbershop/core/models/branch.dart';
import 'package:sverd_barbershop/core/services/api_service.dart';
import 'package:sverd_barbershop/core/theme/colors.dart';
import 'package:sverd_barbershop/presentation/pages/reservation/branch_detail_page_osm.dart';

class ReservationPage extends StatefulWidget {
  const ReservationPage({super.key});

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  final _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  List<Branch> _allBranches = [];
  List<Branch> _filteredBranches = [];
  bool _isLoading = true;
  String _error = '';

  // Location Based Service (LBS) variables
  Position? _currentPosition;
  String _locationText = 'Mendapatkan lokasi...';
  bool _isLoadingLocation = true;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _fetchBranches();
    _getCurrentLocation();
    _searchController.addListener(_filterBranches);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterBranches);
    _searchController.dispose();
    super.dispose();
  }

  // Mendapatkan lokasi pengguna saat ini
  Future<void> _getCurrentLocation() async {
    try {
      // Cek apakah layanan lokasi aktif
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationText = 'Layanan lokasi tidak aktif';
          _locationError = 'GPS';
          _isLoadingLocation = false;
        });
        return;
      }

      // Cek permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationText = 'Izin lokasi ditolak';
            _locationError = 'PERMISSION';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationText = 'Izin lokasi ditolak permanen';
          _locationError = 'PERMISSION_FOREVER';
          _isLoadingLocation = false;
        });
        return;
      }

      // STRATEGI 1: Coba dapatkan last known location dulu (sangat cepat)
      Position? lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null && mounted) {
        setState(() {
          _currentPosition = lastPosition;
          _isLoadingLocation = false;
          _locationError = null;
        });

        // Convert kordinat ke alamat
        _getAddressFromCoordinates(lastPosition);

        if (_allBranches.isNotEmpty) {
          _sortBranchesByDistance();
        }

        // Update di background dengan lokasi real-time
        _updateLocationInBackground();
        return;
      }

      // STRATEGI 2: Jika tidak ada cache, dapatkan lokasi baru dengan timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Tidak dapat menemukan lokasi dalam 10 detik');
        },
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
          _locationError = null;
        });

        // Convert kordinat ke alamat
        _getAddressFromCoordinates(position);

        if (_allBranches.isNotEmpty) {
          _sortBranchesByDistance();
        }
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _locationText = 'Timeout - Coba lagi atau aktifkan GPS';
          _locationError = 'TIMEOUT';
          _isLoadingLocation = false;
        });
      }
      print('⏱️ Location timeout');
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationText = 'Error mendapatkan lokasi';
          _locationError = 'ERROR';
          _isLoadingLocation = false;
        });
      }
      print('❌ Error getting location: $e');
    }
  }

  // Update lokasi di background
  Future<void> _updateLocationInBackground() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        // Update alamat juga jika lokasi berubah signifikan
        _getAddressFromCoordinates(position);

        if (_allBranches.isNotEmpty) {
          _sortBranchesByDistance();
        }
      }
    } catch (e) {
      print('Background update failed (OK): $e');
    }
  }

  // ---- PERUBAHAN: Fungsi untuk mengubah Kordinat menjadi Alamat ----
  Future<void> _getAddressFromCoordinates(Position position) async {
    try {
      // Menggunakan package geocoding
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks[0];

        // Menyusun string alamat
        // street: Nama Jalan
        // subLocality: Kelurahan/Desa
        // locality: Kecamatan/Kota
        // subAdministrativeArea: Kabupaten/Kota

        String address = '';
        if (place.street != null && place.street!.isNotEmpty) {
          address += '${place.street}, ';
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          address += '${place.subLocality}, ';
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          address += place.locality!;
        }

        // Hapus koma di akhir jika ada
        if (address.endsWith(', ')) {
          address = address.substring(0, address.length - 2);
        }

        setState(() {
          _locationText =
              address.isNotEmpty ? address : 'Alamat tidak ditemukan';
        });
      }
    } catch (e) {
      print("Error Geocoding: $e");
      if (mounted) {
        // Fallback jika gagal convert alamat (misal tidak ada internet)
        setState(() {
          _locationText =
              'Lat: ${position.latitude.toStringAsFixed(4)}, Long: ${position.longitude.toStringAsFixed(4)}';
        });
      }
    }
  }

  // Sort branches berdasarkan jarak dari lokasi pengguna
  void _sortBranchesByDistance() {
    if (_currentPosition == null) return;

    _allBranches.sort((a, b) {
      double distanceA = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        a.latitude,
        a.longitude,
      );

      double distanceB = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        b.latitude,
        b.longitude,
      );

      return distanceA.compareTo(distanceB);
    });

    setState(() {
      _filteredBranches = _allBranches;
    });
  }

  // Hitung jarak dari lokasi pengguna ke cabang
  String _calculateDistance(Branch branch) {
    if (_currentPosition == null) return '';

    double distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      branch.latitude,
      branch.longitude,
    );

    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      double km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  Future<void> _fetchBranches() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final List<Branch> branches = await _apiService.fetchBranches();
      if (mounted) {
        setState(() {
          _allBranches = branches;
          _filteredBranches = branches;
          _isLoading = false;
        });

        // Sort by distance jika lokasi sudah didapat
        if (_currentPosition != null) {
          _sortBranchesByDistance();
        }
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _error = 'Request timeout!';
          _isLoading = false;
        });
      }
    } on FormatException catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Format JSON tidak valid!\n\nError: ${e.message}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _filterBranches() {
    String query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        _filteredBranches = _allBranches;
      });
    } else {
      setState(() {
        _filteredBranches = _allBranches.where((branch) {
          final nameLower = branch.name.toLowerCase();
          final addressLower = branch.address.toLowerCase();
          return nameLower.contains(query) || addressLower.contains(query);
        }).toList();
      });
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: kPrimaryColor),
            SizedBox(height: 16),
            Text(
              'Memuat data cabang...',
              style: TextStyle(color: kSecondaryTextColor, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                _error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: kTextColor,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchBranches,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: kLightTextColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredBranches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: kSecondaryTextColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'Belum ada cabang tersedia'
                  : 'Tidak ada hasil untuk "${_searchController.text}"',
              textAlign: TextAlign.center,
              style: const TextStyle(color: kSecondaryTextColor, fontSize: 16),
            ),
            if (_searchController.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                },
                child: const Text('Hapus pencarian'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _filteredBranches.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: kSecondaryTextColor.withAlpha(76),
        indent: 88,
        endIndent: 16,
      ),
      itemBuilder: (context, index) {
        final branch = _filteredBranches[index];
        return _buildBranchListItem(branch);
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari cabang barbershop...',
          hintStyle: const TextStyle(color: kSecondaryTextColor),
          prefixIcon: const Icon(Icons.search, color: kSecondaryTextColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, color: kSecondaryTextColor),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          filled: true,
          fillColor: kSecondaryTextColor.withAlpha(30),
          contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimaryColor, width: 2),
          ),
        ),
      ),
    );
  }

  // Widget untuk menampilkan lokasi pengguna
  Widget _buildLocationIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          _buildLocationIcon(),
          const SizedBox(width: 12),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLoadingLocation ? 'Mencari lokasi Anda...' : 'Lokasi Anda',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _locationText,
                  style: TextStyle(
                    color: _locationError != null ? Colors.red : kTextColor,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Refresh button jika error atau ingin refresh alamat
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue, size: 20),
            onPressed: () {
              setState(() {
                _isLoadingLocation = true;
                _locationError = null;
                _locationText = 'Memperbarui lokasi...';
              });
              _getCurrentLocation();
            },
            tooltip: 'Refresh lokasi',
          ),
        ],
      ),
    );
  }

  Widget _buildLocationIcon() {
    if (_isLoadingLocation) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    }

    if (_locationError != null) {
      return const Icon(
        Icons.location_off,
        color: Colors.red,
        size: 24,
      );
    }

    return const Icon(
      Icons.my_location,
      color: Colors.blue,
      size: 24,
    );
  }

  Widget _buildBranchListItem(Branch branch) {
    final distance = _calculateDistance(branch);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BranchDetailPageOSM(branch: branch),
          ),
        );
      },
      leading: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: kSecondaryTextColor.withAlpha(51),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.store, color: kSecondaryTextColor, size: 28),
      ),
      title: Text(
        branch.name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: kTextColor,
          fontSize: 16,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            branch.address,
            style: const TextStyle(color: kSecondaryTextColor, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.orange, size: 16),
              const SizedBox(width: 4),
              Text(
                branch.rating.toStringAsFixed(1),
                style: const TextStyle(
                  color: kTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (distance.isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(Icons.location_on, color: Colors.blue, size: 16),
                const SizedBox(width: 4),
                Text(
                  distance,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right, color: kSecondaryTextColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Column(
        children: [
          _buildSearchBar(),
          _buildLocationIndicator(),
          Divider(height: 1, color: kSecondaryTextColor.withAlpha(76)),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }
}
