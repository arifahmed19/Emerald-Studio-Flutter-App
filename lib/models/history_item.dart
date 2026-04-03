class HistoryItem {
  final String id;
  final String userId;
  final String imageUrl;
  final String standardName;
  final DateTime createdAt;

  HistoryItem({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.standardName,
    required this.createdAt,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'].toString(),
      userId: json['user_id'],
      imageUrl: json['image_url'],
      standardName: json['standard_name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'image_url': imageUrl,
      'standard_name': standardName,
    };
  }
}
