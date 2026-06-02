class Highlight {
  final String id;
  final String userId;
  final String bookId;
  final String chapterId;
  final String selectedText;
  final int startOffset;
  final int endOffset;
  final String color;
  final DateTime createdAt;

  Highlight({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.chapterId,
    required this.selectedText,
    required this.startOffset,
    required this.endOffset,
    required this.color,
    required this.createdAt,
  });

  factory Highlight.fromJson(Map<String, dynamic> json) {
    return Highlight(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      bookId: json['bookId']?.toString() ?? '',
      chapterId: json['chapterId']?.toString() ?? '',
      selectedText: json['selectedText'] ?? '',
      startOffset: json['startOffset'] ?? 0,
      endOffset: json['endOffset'] ?? 0,
      color: json['color'] ?? '#FFF59D',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
