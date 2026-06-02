// phong
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIChatRepository {
  static String get _baseUrl {
    final url = dotenv.env['baseURL'];
    if (url == null) {
      throw Exception("Lỗi: Không tìm thấy 'baseURL' trong file .env");
    }
    return url;
  }

  /// Gọi AI để trả lời câu hỏi về sách
  /// [userId] - User ID
  /// [bookId] - Book ID
  /// [chapterId] - Chapter ID (optional)
  /// [question] - Câu hỏi của user
  /// [context] - Ngữ cảnh (tóm tắt chương hoặc nội dung)
  Future<String> askAI({
    required String userId,
    required String bookId,
    String? chapterId,
    required String question,
    required String context,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/ai/chat');

      final response = await http
          .post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "userId": userId,
          "bookId": bookId,
          "chapterId": chapterId,
          "question": question,
          "context": context,
        }),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception("⏱️ Timeout: AI không phản hồi trong 30 giây");
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['answer'] ?? "Không thể lấy câu trả lời";
      } else if (response.statusCode == 429) {
        throw Exception("⚠️ Quá nhiều yêu cầu. Vui lòng chờ một lát.");
      } else {
        print(
          '❌ AI Chat Error: ${response.statusCode} - ${response.body}',
        );
        throw Exception(
          'Lỗi: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ AI Chat Exception: $e');
      rethrow;
    }
  }

  /// Tóm tắt chương sách
  Future<String> summarizeChapter({
    required String chapterId,
    required String chapterContent,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/ai/summarize');

      final response = await http
          .post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "chapterId": chapterId,
          "content": chapterContent,
        }),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception("⏱️ Timeout: Tóm tắt không thể hoàn thành");
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['summary'] ?? "Không thể tóm tắt";
      } else {
        throw Exception('Lỗi tóm tắt: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Summarize Exception: $e');
      rethrow;
    }
  }

  /// ✅ NEW: RAG Implementation - Vector Search + AI Generation
  /// [userId] - User ID
  /// [bookId] - Book ID
  /// [chapterId] - Chapter ID (optional)
  /// [question] - Câu hỏi của user
  /// Backend sẽ tự động:
  /// 1. Embed câu hỏi thành vector
  /// 2. Tìm chapters tương tự (vector similarity search)
  /// 3. Combine context → AI generation
  Future<Map<String, dynamic>> askAI_RAG({
    required String userId,
    required String bookId,
    String? chapterId,
    required String question,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/ai/chat-rag');

      print('🚀 RAG REQUEST:');
      print('  Question: $question');
      print('  BookId: $bookId');

      final response = await http
          .post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "bookId": bookId,
          "chapterId": chapterId,
          "question": question,
        }),
      )
          .timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          throw Exception(
            "⏱️ Timeout: AI không phản hồi trong 45 giây",
          );
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        print('✅ RAG RESPONSE:');
        print('  Method: ${data['method']}');
        print(
          '  Relevant Passages: ${(data['relevantPassages'] as List?)?.length ?? 0}',
        );

        return {
          'answer': data['answer'] ?? "Không thể lấy câu trả lời",
          'relevantPassages': data['relevantPassages'] ?? [],
          'method': data['method'] ?? 'RAG',
          'success': data['success'] ?? true,
        };
      } else if (response.statusCode == 429) {
        throw Exception(
          "⚠️ Quá nhiều yêu cầu. Vui lòng chờ một lát.",
        );
      } else {
        print('❌ RAG Error: ${response.statusCode}');
        throw Exception('Lỗi: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ RAG Exception: $e');
      rethrow;
    }
  }
}
