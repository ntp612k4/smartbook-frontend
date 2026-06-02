import 'package:smart_reader/models/author.dart';
import 'package:smart_reader/models/chapter_info.dart';

class Book {
  final String bookId;
  final String title;
  final Author author;
  final String imgUrl;
  final double rating;
  final String description;
  final List<ChapterInfo> chapters;
  final double ratingCount;
  final double chapterCount;
  final List<String> genres;
  final bool isAddedToLibrary;

  Book({
    required this.bookId,
    required this.title,
    required this.author,
    required this.imgUrl,
    required this.rating,
    required this.description,
    this.chapters = const [],
    required this.ratingCount,
    required this.chapterCount,
    this.genres = const [],
    this.isAddedToLibrary = false,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    Author authorObj;
    if (json['author'] is String) {
      authorObj = Author(
        authorId: json['author'],
        authorName: 'Đang tải...', // Tên tạm thời
      );
    } else if (json['author'] is Map<String, dynamic>) {
      // Trường hợp 2: API trả về Object (đã populate) - Đây là trường hợp chính
      authorObj = Author.fromJson(json['author']);
    } else {
      // Trường hợp 3: Sách không có tác giả (dự phòng)
      authorObj = Author(authorId: '', authorName: 'Không rõ');
    }

    // Xử lý 'chapters' (List<ChapterInfo>)
    var chapterList = <ChapterInfo>[];
    if (json['chapters'] != null && json['chapters'] is List) {
      // Lặp qua mảng 'chapters' và parse từng cái thành ChapterInfo
      chapterList = (json['chapters'] as List)
          .map((chapterJson) => ChapterInfo.fromJson(chapterJson))
          .toList();
    }
    print(
        '📖 Book.fromJson: ${json['title']} - Chapters: ${chapterList.length}');

    // Xử lý 'genres' (List<String>)
    var genresList = <String>[];
    if (json['genres'] != null && json['genres'] is List) {
      genresList = List<String>.from(json['genres']);
    }
    return Book(
      bookId: json['_id'] ?? '',
      title: json['title'] ?? 'Không có tiêu đề',
      author: authorObj, // Gán tác giả đã xử lý
      imgUrl: json['imgUrl'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      chapters: chapterList, // Gán danh sách chương đã xử lý
      ratingCount: (json['ratingCount'] as num?)?.toDouble() ?? 0.0,
      chapterCount: (json['chapterCount'] as num?)?.toDouble() ?? 0.0,
      genres: genresList, // Gán thể loại đã xử lý
      isAddedToLibrary: json['isAddedToLibrary'] ?? false, // Sẽ dùng sau
    );
  }
}
