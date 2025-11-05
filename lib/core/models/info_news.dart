class InfoNews {
  final int id;
  final String title;
  final String? imageUrl;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  InfoNews({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InfoNews.fromJson(Map<String, dynamic> json) {
    return InfoNews(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      content: json['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image_url': imageUrl,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'InfoNews(id: $id, title: $title)';
  }
}
