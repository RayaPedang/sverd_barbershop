import 'package:flutter/material.dart';

class Reservation {
  final String id;
  final String branchName;
  final String serviceName;
  final String serviceDescription;
  final DateTime date;
  final String timeSlot;
  final String timeZone;
  final double price;
  final String currency;
  final DateTime createdAt;
  final String status;

  Reservation({
    required this.id,
    required this.branchName,
    required this.serviceName,
    required this.serviceDescription,
    required this.date,
    required this.timeSlot,
    required this.timeZone,
    required this.price,
    required this.currency,
    required this.createdAt,
    this.status = 'pending',
  });

  // Convert to Map untuk disimpan ke Hive
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'branchName': branchName,
      'serviceName': serviceName,
      'serviceDescription': serviceDescription,
      'date': date.toIso8601String(),
      'timeSlot': timeSlot,
      'timeZone': timeZone,
      'price': price,
      'currency': currency,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  // Convert dari Map (dari Hive)
  factory Reservation.fromMap(Map<dynamic, dynamic> map) {
    return Reservation(
      id: map['id']?.toString() ?? '',
      branchName: map['branchName']?.toString() ?? '',
      serviceName: map['serviceName']?.toString() ?? '',
      serviceDescription: map['serviceDescription']?.toString() ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      timeSlot: map['timeSlot']?.toString() ?? '',
      timeZone: map['timeZone']?.toString() ?? 'WIB',
      price: double.tryParse(map['price'].toString()) ?? 0.0,
      currency: map['currency']?.toString() ?? 'IDR',
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      status: map['status']?.toString() ?? 'pending',
    );
  }

  // Format harga dengan currency
  String get formattedPrice {
    final symbols = {'IDR': 'Rp', 'USD': '\$', 'JPY': '¥', 'EUR': '€'};

    final symbol = symbols[currency] ?? '';

    if (currency == 'IDR' || currency == 'JPY') {
      return '$symbol${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
    } else {
      return '$symbol${price.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    }
  }

  // Format tanggal
  String get formattedDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Status color
  static Map<String, dynamic> getStatusInfo(String status) {
    switch (status) {
      case 'confirmed':
        return {
          'color': const Color(0xFF4CAF50),
          'text': 'Dikonfirmasi',
          'icon': Icons.check_circle,
        };
      case 'pending':
        return {
          'color': const Color(0xFFFFA726),
          'text': 'Menunggu',
          'icon': Icons.schedule,
        };
      case 'completed':
        return {
          'color': const Color(0xFF2196F3),
          'text': 'Selesai',
          'icon': Icons.done_all,
        };
      case 'cancelled':
        return {
          'color': const Color(0xFFF44336),
          'text': 'Dibatalkan',
          'icon': Icons.cancel,
        };
      default:
        return {
          'color': const Color(0xFF9E9E9E),
          'text': 'Unknown',
          'icon': Icons.help,
        };
    }
  }

  @override
  String toString() {
    return 'Reservation(id: $id, branch: $branchName, service: $serviceName, date: $formattedDate)';
  }
}
