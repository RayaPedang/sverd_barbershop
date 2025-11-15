import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sverd_barbershop/core/models/reservation.dart';
import 'package:sverd_barbershop/core/theme/colors.dart';

class YourReservationPage extends StatefulWidget {
  const YourReservationPage({super.key});

  @override
  State<YourReservationPage> createState() => _YourReservationPageState();
}

class _YourReservationPageState extends State<YourReservationPage> {
  List<Reservation> _reservations = [];
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  void _loadReservations() {
    final box = Hive.box('sverd_box');
    final currentUser = box.get('currentUser');

    if (currentUser == null) {
      setState(() {
        _reservations = [];
      });
      return;
    }

    final userEmail = currentUser['email'] ?? '';
    final reservationsData =
        box.get('reservations_$userEmail') as List<dynamic>?;

    if (reservationsData != null) {
      setState(() {
        _reservations = reservationsData
            .map((data) => Reservation.fromMap(data as Map<dynamic, dynamic>))
            .toList();
        _reservations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
    } else {
      setState(() {
        _reservations = [];
      });
    }
  }

  List<Reservation> _getFilteredReservations() {
    if (_selectedFilter == 'all') {
      return _reservations;
    }
    return _reservations.where((r) => r.status == _selectedFilter).toList();
  }

  void _cancelReservation(Reservation reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kBackgroundColor,
        title: const Text(
          'Batalkan Reservasi?',
          style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin membatalkan reservasi di ${reservation.branchName}?',
          style: const TextStyle(color: kTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Tidak',
              style: TextStyle(color: kSecondaryTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final box = Hive.box('sverd_box');
              final currentUser = box.get('currentUser');
              final userEmail = currentUser['email'] ?? '';

              final reservationsData =
                  box.get('reservations_$userEmail') as List<dynamic>;
              final updatedList = reservationsData.map((data) {
                final res = Reservation.fromMap(data as Map<dynamic, dynamic>);
                if (res.id == reservation.id) {
                  return Reservation(
                    id: res.id,
                    branchName: res.branchName,
                    serviceName: res.serviceName,
                    serviceDescription: res.serviceDescription,
                    date: res.date,
                    timeSlot: res.timeSlot,
                    timeZone: res.timeZone,
                    price: res.price,
                    currency: res.currency,
                    createdAt: res.createdAt,
                    status: 'cancelled',
                  ).toMap();
                }
                return data;
              }).toList();

              box.put('reservations_$userEmail', updatedList);

              Navigator.pop(context);
              _loadReservations();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reservasi berhasil dibatalkan'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: kLightTextColor,
            ),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredReservations = _getFilteredReservations();

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
          'Your Reservation',
          style: TextStyle(
            color: kTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          const Divider(height: 1),
          Expanded(
            child: filteredReservations.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: () async {
                      _loadReservations();
                    },
                    color: kPrimaryColor,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredReservations.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final reservation = filteredReservations[index];
                        return _buildReservationCard(reservation);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      {'key': 'all', 'label': 'Semua'},
      {'key': 'pending', 'label': 'Menunggu'},
      {'key': 'confirmed', 'label': 'Dikonfirmasi'},
      {'key': 'completed', 'label': 'Selesai'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedFilter = filter['key'] as String;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? kPrimaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? kPrimaryColor : kSecondaryTextColor,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    filter['label'] as String,
                    style: TextStyle(
                      color: isSelected ? kLightTextColor : kTextColor,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildReservationCard(Reservation reservation) {
    final statusInfo = Reservation.getStatusInfo(reservation.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kDarkBlockColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reservation.branchName,
                        style: const TextStyle(
                          color: kLightTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Booking ID: ${reservation.id.substring(0, 8)}',
                        style: TextStyle(
                          color: kLightTextColor.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusInfo['color'],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusInfo['icon'], size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        statusInfo['text'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow(
                  Icons.content_cut,
                  'Layanan',
                  reservation.serviceName,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.calendar_today,
                  'Tanggal',
                  reservation.formattedDate,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.access_time,
                  'Waktu',
                  '${reservation.timeSlot} ${reservation.timeZone}',
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  Icons.attach_money,
                  'Harga',
                  '${reservation.formattedPrice} (${reservation.currency})',
                ),
                if (reservation.status == 'pending') ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelReservation(reservation),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Batalkan Reservasi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: kPrimaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: kSecondaryTextColor, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: kTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_selectedFilter) {
      case 'pending':
        message = 'Tidak ada reservasi menunggu konfirmasi';
        icon = Icons.schedule;
        break;
      case 'confirmed':
        message = 'Tidak ada reservasi terkonfirmasi';
        icon = Icons.check_circle_outline;
        break;
      case 'completed':
        message = 'Tidak ada reservasi selesai';
        icon = Icons.done_all;
        break;
      default:
        message = 'Belum ada reservasi';
        icon = Icons.event_busy;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: kSecondaryTextColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: kSecondaryTextColor, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.add),
            label: const Text('Buat Reservasi Baru'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: kLightTextColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
