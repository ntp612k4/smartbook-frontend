class Review {
  final String id;
  final String userId;
  final String comment;
  final DateTime createdAt;
  final String userName;
  final String userPhoto;

  Review({
    required this.id,
    required this.userId,
    required this.comment,
    required this.createdAt,
    required this.userName,
    required this.userPhoto,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final userId = json['userId']?.toString() ?? '';
    final shortId = userId.length > 6 ? userId.substring(0, 6) : userId;
    final fallbackName = shortId.isNotEmpty ? 'User $shortId' : 'Người dùng';
    final name = (json['userName'] ?? '').toString().trim();

    return Review(
      id: json['_id']?.toString() ?? '',
      userId: userId,
      comment: json['comment'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      userName: name.isNotEmpty ? name : fallbackName,
      userPhoto: json['userPhoto'] ?? '',
    );
  }
}
