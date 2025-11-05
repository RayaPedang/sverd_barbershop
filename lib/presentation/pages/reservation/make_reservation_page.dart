import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sverd_barbershop/core/models/branch.dart';
import 'package:sverd_barbershop/core/models/service.dart';
import 'package:sverd_barbershop/core/models/reservation.dart';
import 'package:sverd_barbershop/core/theme/colors.dart';

class MakeReservationPage extends StatefulWidget {
  final Branch branch;
  final Service service;

  const MakeReservationPage({
    super.key,
    required this.branch,
    required this.service,
  });

  @override
  State<MakeReservationPage> createState() => _MakeReservationPageState();
}

class _MakeReservationPageState extends State<MakeReservationPage> {
  DateTime _selectedDate = DateTime.now();
  String _selectedTimeSlot = '09.00 - 10.30';

  // Konversi Waktu
  String _selectedTimeZone = 'WIB';
  final Map<String, int> _timeZoneOffsets = {
    'WIB': 7,
    'WITA': 8,
    'WIT': 9,
    'London': 0,
  };

  // Konvesi Mata Uang
  String _selectedCurrency = 'IDR';
  final Map<String, double> _currencyRates = {
    'IDR': 1.0,
    'USD': 0.000064,
    'JPY': 0.0095,
    'EUR': 0.000059,
  };

  final Map<String, String> _currencySymbols = {
    'IDR': 'Rp',
    'USD': '\$',
    'JPY': '¥',
    'EUR': '€',
  };

  // Daftar time slot yang tersedia (dalam WIB)
  final List<String> _timeSlots = [
    '09.00 - 10.30',
    '10.30 - 12.00',
    '12.00 - 13.30',
    '13.30 - 15.00',
    '15.00 - 16.30',
    '16.30 - 18.00',
    '18.00 - 19.30',
    '19.30 - 21.00',
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kPrimaryColor,
              onPrimary: kLightTextColor,
              onSurface: kTextColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Konversi waktu ke timezone yang dipilih
  String _convertTimeSlot(String timeSlot) {
    if (_selectedTimeZone == 'WIB') {
      return timeSlot;
    }

    final parts = timeSlot.split(' - ');
    final startTime = parts[0];
    final endTime = parts[1];

    // Konversi
    final convertedStart = _convertTime(startTime);
    final convertedEnd = _convertTime(endTime);

    return '$convertedStart - $convertedEnd';
  }

  String _convertTime(String time) {
    final timeParts = time.split('.');
    int hour = int.parse(timeParts[0]);
    final minute = timeParts[1];

    // Hitung offset dari WIB ke timezone yang dipilih
    final wibOffset = _timeZoneOffsets['WIB']!;
    final targetOffset = _timeZoneOffsets[_selectedTimeZone]!;
    final difference = targetOffset - wibOffset;

    hour += difference;

    // Handle overflow/underflow
    if (hour >= 24) {
      hour -= 24;
    } else if (hour < 0) {
      hour += 24;
    }

    return '${hour.toString().padLeft(2, '0')}.$minute';
  }

  /// Format harga dengan currency yang dipilih
  String _formatPrice() {
    final priceInIDR = widget.service.price;
    final rate = _currencyRates[_selectedCurrency]!;
    final convertedPrice = priceInIDR * rate;
    final symbol = _currencySymbols[_selectedCurrency]!;

    if (_selectedCurrency == 'IDR') {
      // Format Rupiah
      return '$symbol${convertedPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
    } else if (_selectedCurrency == 'JPY') {
      // Format Yen
      return '$symbol${convertedPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    } else {
      // Format USD dan EUR
      return '$symbol${convertedPrice.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    }
  }

  void _makeReservation() {
    // Generate unique ID untuk reservasi
    final reservationId = DateTime.now().millisecondsSinceEpoch.toString();

    // Konversi harga sesuai currency
    final convertedPrice =
        widget.service.price * _currencyRates[_selectedCurrency]!;

    // Buat object Reservation
    final reservation = Reservation(
      id: reservationId,
      branchName: widget.branch.name,
      serviceName: widget.service.name,
      serviceDescription: widget.service.description,
      date: _selectedDate,
      timeSlot: _selectedTimeSlot,
      timeZone: _selectedTimeZone,
      price: convertedPrice,
      currency: _selectedCurrency,
      createdAt: DateTime.now(),
      status: 'pending',
    );

    // Dialog konfirmasi
    final displayTime = _convertTimeSlot(_selectedTimeSlot);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kBackgroundColor,
        title: const Text(
          'Konfirmasi Reservasi',
          style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cabang: ${widget.branch.name}',
              style: const TextStyle(color: kTextColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Layanan: ${widget.service.name}',
              style: const TextStyle(color: kTextColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Tanggal: ${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}',
              style: const TextStyle(color: kTextColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Waktu: $displayTime $_selectedTimeZone',
              style: const TextStyle(color: kTextColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Harga: ${reservation.formattedPrice} ($_selectedCurrency)',
              style: const TextStyle(
                color: kTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(color: kSecondaryTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final box = Hive.box('sverd_box');
              final currentUser = box.get('currentUser');

              if (currentUser == null) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: User tidak ditemukan'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final userEmail = currentUser['email'] ?? '';
              List<dynamic> userReservations =
                  box.get('reservations_$userEmail') ?? [];
              userReservations.add(reservation.toMap());
              box.put('reservations_$userEmail', userReservations);

              print('Reservasi disimpan untuk user: $userEmail');
              print('Total reservasi: ${userReservations.length}');

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reservasi berhasil dibuat!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );

              // Kembali ke home
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: kLightTextColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Konfirmasi'),
          ),
        ],
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
          'Buat Reservasi',
          style: TextStyle(
            color: kTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nama Layanan
            Center(
              child: Text(
                widget.service.name,
                style: const TextStyle(
                  color: kTextColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Deskripsi Layanan
            const Text(
              'Deskripsi Layanan',
              style: TextStyle(
                color: kTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kSecondaryTextColor.withAlpha(76)),
              ),
              child: Text(
                widget.service.description,
                style: const TextStyle(
                  color: kTextColor,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: kBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: kSecondaryTextColor.withAlpha(76),
                    ),
                  ),
                  child: const Text(
                    'Harga',
                    style: TextStyle(
                      color: kTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: kBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: kSecondaryTextColor.withAlpha(76),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _formatPrice(),
                            style: const TextStyle(
                              color: kTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Currency Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: kSecondaryTextColor.withAlpha(76),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCurrency,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: kTextColor,
                      ),
                      style: const TextStyle(
                        color: kTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      dropdownColor: kBackgroundColor,
                      items: _currencyRates.keys.map((String currency) {
                        return DropdownMenuItem<String>(
                          value: currency,
                          child: Text(currency),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedCurrency = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Pilih Jadwal
            const Text(
              'Pilih Jadwal',
              style: TextStyle(
                color: kTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Date Picker
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: kBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: kSecondaryTextColor.withAlpha(76),
                    ),
                  ),
                  child: const Text(
                    'Tanggal',
                    style: TextStyle(
                      color: kTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: kBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: kSecondaryTextColor.withAlpha(76),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_selectedDate.day.toString().padLeft(2, '0')} - ${_selectedDate.month.toString().padLeft(2, '0')} - ${_selectedDate.year}',
                            style: const TextStyle(
                              color: kTextColor,
                              fontSize: 14,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today,
                            color: kTextColor,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: kBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: kSecondaryTextColor.withAlpha(76),
                    ),
                  ),
                  child: const Text(
                    'Jam',
                    style: TextStyle(
                      color: kTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: kSecondaryTextColor.withAlpha(76),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedTimeSlot,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: kTextColor,
                        ),
                        style: const TextStyle(color: kTextColor, fontSize: 14),
                        dropdownColor: kBackgroundColor,
                        items: _timeSlots.map((String slot) {
                          final displaySlot = _convertTimeSlot(slot);
                          return DropdownMenuItem<String>(
                            value: slot,
                            child: Text(displaySlot),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedTimeSlot = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Time Zone Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: kBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: kSecondaryTextColor.withAlpha(76),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedTimeZone,
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: kTextColor,
                      ),
                      style: const TextStyle(
                        color: kTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      dropdownColor: kBackgroundColor,
                      items: _timeZoneOffsets.keys.map((String timezone) {
                        return DropdownMenuItem<String>(
                          value: timezone,
                          child: Text(timezone),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedTimeZone = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),

            // Button Reservasi
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _makeReservation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: kLightTextColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: const Text('Reservasi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
