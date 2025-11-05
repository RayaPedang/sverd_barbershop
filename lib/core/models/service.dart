class Service {
  final int id;
  final String name;
  final String description;
  final double price;
  final int duration;
  final String? imageUrl;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
    this.imageUrl,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      duration: int.tryParse(json['duration'].toString()) ?? 0,
      imageUrl: json['image_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'duration': duration,
      'image_url': imageUrl,
    };
  }

  // Format harga ke Rupiah
  String get formattedPrice {
    return 'Rp${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  // Format durasi
  String get formattedDuration {
    if (duration < 60) {
      return '$duration menit';
    } else {
      int hours = duration ~/ 60;
      int minutes = duration % 60;
      if (minutes == 0) {
        return '$hours jam';
      }
      return '$hours jam $minutes menit';
    }
  }

  @override
  String toString() {
    return 'Service(id: $id, name: $name, price: $price)';
  }
}
