class Branch {
  final int id;
  final String name;
  final String address;
  final double rating;
  final double latitude;
  final double longitude;
  final String? phoneNumber;
  final String? imageUrl;
  final String? openingHours;
  final String? description;

  Branch({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.latitude,
    required this.longitude,
    this.phoneNumber,
    this.imageUrl,
    this.openingHours,
    this.description,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      phoneNumber: json['phone_number']?.toString(),
      imageUrl: json['image_url']?.toString(),
      openingHours:
          json['opening_hours']?.toString() ?? 'Senin - Minggu: 09.00 - 21.00',
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'rating': rating,
      'latitude': latitude,
      'longitude': longitude,
      'phone_number': phoneNumber,
      'image_url': imageUrl,
      'opening_hours': openingHours,
      'description': description,
    };
  }

  @override
  String toString() {
    return 'Branch(id: $id, name: $name, lat: $latitude, lng: $longitude)';
  }
}
