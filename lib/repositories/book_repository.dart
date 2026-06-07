import 'dart:convert';

import 'package:smart_reader/models/author.dart';
import 'package:smart_reader/models/book.dart';
import 'package:smart_reader/models/categories.dart';
import 'package:smart_reader/models/chapter_detail.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:smart_reader/models/highlight.dart';
import 'package:smart_reader/models/reivew.dart';

class BookRepository {
  // Sá»­a thÃ nh static GETTER
  static String get _baseUrl {
    final url = dotenv.env['baseURL'];
    if (url == null) {
      // BÃ¡o lá»—i rÃµ rÃ ng hÆ¡n náº¿u .env bá»‹ thiáº¿u
      throw Exception("Lá»—i: KhÃ´ng tÃ¬m tháº¥y 'baseURL' trong file .env");
    }
    return url;
  }
  // 3. DÃ¹ng cho Äiá»‡n thoáº¡i tháº­t (Cáº®M CÃP hoáº·c CÃ™NG WIFI):
  // (Thay 192.168.1.5 báº±ng IP Wifi cá»§a MÃY TÃNH báº¡n)
  // static const String _baseUrl = "http://192.168.1.5:5001";

  //Helper function Ä‘á»ƒ xá»­ lÃ½ response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      print('API Error: ${response.statusCode} - ${response.body}');
      throw Exception('Lá»—i khi gá»i API (Status code: ${response.statusCode})');
    }
  }

  // láº¥y tat ca thá»ƒ loáº¡i
  Future<List<BookCategory>> fetchCategories() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/categories'));
    final data = _handleResponse(response) as List;
    return data.map((json) => BookCategory.fromJson(json)).toList();
  }

  // Láº¥y sÃ¡ch theo thá»ƒ loáº¡i
  Future<List<Book>> fetchBooksByCategory(
    String endpoint, {
    int limit = 10,
  }) async {
    print('REPOSITORY: Fetching books for endpoint: $endpoint');
    await Future.delayed(const Duration(milliseconds: 500));

    final response = await http.get(
      Uri.parse('$_baseUrl/api/books?genre=$endpoint&limit=$limit'),
    );
    final data = _handleResponse(response) as List;

    return data.map((json) => Book.fromJson(json)).toList();
  }

  //Láº¥y chi tiáº¿t sÃ¡ch
  Future<Book> fetchBookDetails(String bookId) async {
    print('REPOSITORY: Fetching book details for: $bookId');
    final response = await http.get(Uri.parse('$_baseUrl/api/books/$bookId'));
    final data = _handleResponse(response);
    return Book.fromJson(data);
  }

  // Láº¥y ná»™i dung chÆ°Æ¡ng
  Future<ChapterDetail> fetchChapterContent(String chapterId) async {
    print('ðŸ“š REPOSITORY: Fetching chapter content for: $chapterId');
    final response = await http.get(
      Uri.parse('$_baseUrl/api/chapters/$chapterId'),
    );
    final data = _handleResponse(response);
    return ChapterDetail.fromJson(data);
  }

  //Láº¥y dá»¯ liá»‡u tá»•ng há»£p cho Home
  Future<Map<String, dynamic>> fetchHomeData() async {
    print('REPOSITORY: Fetching all data for Home Screen');
    final response = await http.get(Uri.parse('$_baseUrl/api/home'));
    final data = _handleResponse(response);

    // Parse dá»¯ liá»‡u tá»« API /api/home
    final categories = (data['categories'] as List)
        .map((json) => BookCategory.fromJson(json))
        .toList();

    final authors =
        (data['authors'] as List).map((json) => Author.fromJson(json)).toList();

    final newBooks =
        (data['newBooks'] as List).map((json) => Book.fromJson(json)).toList();

    final specialBooks = (data['specialBooks'] as List)
        .map((json) => Book.fromJson(json))
        .toList();

    return {
      'categories': categories,
      'authors': authors,
      'newBooks': newBooks,
      'specialBooks': specialBooks,
    };
  }

  //Láº¥y chi tiáº¿t tÃ¡c giáº£
  Future<Map<String, dynamic>> fetchAuthorDetails(String authorId) async {
    print('REPOSITORY: Fetching author details for: $authorId');
    final response = await http.get(
      Uri.parse('$_baseUrl/api/authors/$authorId'),
    );
    print("RESPONSE RAW: ${response.body}");
    final data = _handleResponse(response);
    // 1ï¸âƒ£ Parse author
    final author = Author.fromJson(data['author']);

    // 2ï¸âƒ£ Parse books
    List<Book> books = [];
    if (data['books'] != null) {
      books =
          (data['books'] as List).map((item) => Book.fromJson(item)).toList();
    }

    return {'author': author, 'books': books};
  }

  // HÃ m tÃ¬m kiáº¿m sÃ¡ch
  Future<List<Book>> searchBooks(String query) async {
    try {
      print('ðŸ”Ž Searching for: $query');
      final response = await http.get(
        Uri.parse('$_baseUrl/api/books/search?q=$query'),
      );

      final data = _handleResponse(response) as List;
      return data.map((json) => Book.fromJson(json)).toList();
    } catch (e) {
      print("Lá»—i searchBooks: $e");
      return []; // Tráº£ vá» rá»—ng náº¿u lá»—i
    }
  }

  // HÃ m chuyá»ƒn Text -> Audio
  Future<String?> getAudioFromText(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/tts'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": text}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['audioContent']; // Tráº£ vá» chuá»—i Base64
      } else {
        print("Lá»—i API TTS: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Lá»—i káº¿t ná»‘i TTS: $e");
      return null;
    }
  }

  // HÃ m gá»i AI tÃ³m táº¯t
  Future<String?> summarizeChapter(String text, {String? chapterId}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/ai/summarize'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "chapterId": chapterId,
          "content": text,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['summary']; // Tráº£ vá» Ä‘oáº¡n vÄƒn tÃ³m táº¯t
      } else {
        print("Lá»—i API AI: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Lá»—i káº¿t ná»‘i AI: $e");
      return null;
    }
  }

  // 1. Gá»­i bÃ¬nh luáº­n (Comment Only)
  Future<void> submitReview(
      {required String userId,
      required String bookId,
      required String comment,
      String userName = '',
      String userPhoto = '',
      }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/reviews'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
        'bookId': bookId,
        'comment': comment, // Chá»‰ gá»­i comment
        'userName': userName,
        'userPhoto': userPhoto,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to submit comment');
    }
  }

  // 2. Láº¥y danh sÃ¡ch Ä‘Ã¡nh giÃ¡
  Future<List<Review>> fetchReviews(String bookId) async {
    final response = await http.get(Uri.parse('$_baseUrl/api/reviews/$bookId'));
    if (response.statusCode == 200) {
      final List data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((json) => Review.fromJson(json)).toList();
    }
    return [];
  }

  Future<List<Highlight>> fetchHighlights({
    required String userId,
    required String bookId,
    required String chapterId,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/highlights').replace(
      queryParameters: {
        'userId': userId,
        'bookId': bookId,
        'chapterId': chapterId,
      },
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((json) => Highlight.fromJson(json)).toList();
    }
    throw Exception('Failed to fetch highlights');
  }

  Future<Highlight> createHighlight({
    required String userId,
    required String bookId,
    required String chapterId,
    required String selectedText,
    required int startOffset,
    required int endOffset,
    String color = '#FFF59D',
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/highlights'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
        'bookId': bookId,
        'chapterId': chapterId,
        'selectedText': selectedText,
        'startOffset': startOffset,
        'endOffset': endOffset,
        'color': color,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return Highlight.fromJson(data['highlight'] ?? data);
    }
    throw Exception('Failed to create highlight');
  }

  Future<void> deleteHighlight({
    required String userId,
    required String highlightId,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/highlights/$highlightId').replace(
      queryParameters: {'userId': userId},
    );
    final response = await http.delete(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete highlight');
    }
  }
}

