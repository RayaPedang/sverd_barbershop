import 'dart:async';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchBranches();
    _searchController.addListener(_filterBranches);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterBranches);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBranches() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Memanggil dari ApiService
      final List<Branch> branches = await _apiService.fetchBranches();
      if (mounted) {
        setState(() {
          _allBranches = branches;
          _filteredBranches = branches;
          _isLoading = false;
        });
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
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

  Widget _buildBranchListItem(Branch branch) {
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
          Divider(height: 1, color: kSecondaryTextColor.withAlpha(76)),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }
}
