import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_reader/models/book.dart';
import 'package:smart_reader/models/reading_progess.dart';
import 'package:smart_reader/models/user_stats.dart';

class UserRepository {
  // Sửa thành static GETTER
  static String get _baseUrl {
    final url = dotenv.env['baseURL'];
    if (url == null) {
      // Báo lỗi rõ ràng hơn nếu .env bị thiếu
      throw Exception("Lỗi: Không tìm thấy 'baseURL' trong file .env");
    }
    return url;
  }

  Future<List<ReadingProgress>> fetchContinueReading(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/progress?userId=$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));

        // Map từng phần tử JSON sang Model ReadingProgress
        return data.map((json) => ReadingProgress.fromJson(json)).toList();
      } else {
        print("Lỗi API: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Lỗi fetchContinueReading: $e");
      return [];
    }
  }

  Future<void> saveReadingProgress({
    required String userId,
    required String bookId,
    required String chapterId,
  }) async {
    final url = Uri.parse('$_baseUrl/api/progress'); // API POST

    try {
      print('USER_REPO: Đang lưu tiến độ -> $url');
      print('Data: userId=$userId, bookId=$bookId, chap=$chapterId');

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "bookId": bookId,
          "chapterId": chapterId,
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Lưu tiến độ thành công!");
      } else {
        print("❌ Lỗi lưu tiến độ: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("❌ Lỗi kết nối khi lưu tiến độ: $e");
    }
  }

  // 1. Hàm Thêm/Xóa
  Future<bool> toggleLibrary(String userId, String bookId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/library/toggle'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId, "bookId": bookId}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body)['isAdded'];
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // 2. Hàm Lấy danh sách (Cho Home)
  Future<List<Book>> fetchLibrary(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/library?userId=$userId'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => Book.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 3. Hàm kiểm tra trạng thái ban đầu
  Future<bool> checkIsAdded(String userId, String bookId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/library/check?userId=$userId&bookId=$bookId'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body)['isAdded'];
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateReadingStats({
    required String bookId,
    required String userId,
    required int minutesRead,
    required bool isBookFinished,
  }) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/users/stats'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "bookId": bookId,
          "userId": userId,
          "minutesRead": minutesRead,
          "isBookFinished": isBookFinished
        }),
      );
    } catch (e) {
      print("Lỗi update stats: $e");
    }
  }

  Future<UserStats> fetchUserStats(String userId) async {
    try {
      // Gọi API GET để lấy thông tin User (bao gồm stats)
      // Lưu ý: Bạn cần chắc chắn Backend đã có API này (xem bước 2 bên dưới)
      final response = await http.get(
        Uri.parse('$_baseUrl/api/users/$userId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        // Backend trả về object User, ta lấy trường 'stats' bên trong
        return UserStats.fromJson(data['stats'] ?? {});
      } else {
        print("Lỗi lấy User Stats: ${response.statusCode}");
        return UserStats.empty(); // Trả về data rỗng nếu lỗi
      }
    } catch (e) {
      print("Lỗi kết nối fetchUserStats: $e");
      return UserStats.empty();
    }
  }

// 1. Hàm Upload ảnh lên Firebase và lấy URL
  Future<String> uploadAvatar(File imageFile, String userId) async {
    try {
      // Tạo tên file: avatars/uid_time.jpg (thêm time để tránh cache ảnh cũ)
      if (!await imageFile.exists()) {
        throw Exception('File ảnh không tồn tại trên thiết bị');
      }

      final safeUserId = userId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final fileName =
          'avatars/$safeUserId/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final ref = FirebaseStorage.instance.ref().child(fileName);
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': userId},
      );

      // Bắt đầu upload
      await ref.putFile(imageFile, metadata);

      // Lấy link tải về
      final url = await ref.getDownloadURL();
      return url;
    } on FirebaseException catch (e) {
      print(
        'Firebase Storage upload error: code=${e.code}, message=${e.message}',
      );
      throw Exception(_getStorageErrorMessage(e));
    } catch (e) {
      print("Lỗi upload Storage: $e");
      throw Exception('Không thể upload ảnh: $e');
    }
  }

  String _getStorageErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'unauthorized':
        return 'Firebase Storage chưa cho phép tài khoản này upload ảnh. Hãy kiểm tra Storage Rules.';
      case 'bucket-not-found':
        return 'Không tìm thấy Firebase Storage bucket. Hãy kiểm tra cấu hình Firebase.';
      case 'canceled':
        return 'Upload ảnh đã bị hủy.';
      case 'retry-limit-exceeded':
        return 'Mạng yếu hoặc upload quá lâu. Vui lòng thử lại.';
      case 'object-not-found':
        return 'Không tìm thấy file ảnh sau khi upload.';
      default:
        return e.message ?? 'Không thể upload ảnh lên Firebase Storage.';
    }
  }

// 2. Hàm cập nhật thông tin (Gọi cả Firebase & Mongo)
  Future<void> updateUserProfile(
      {required String userId, String? photoUrl, String? displayName}) async {
    // A. Cập nhật Firebase Auth (Để app hiển thị ngay)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (photoUrl != null) await user.updatePhotoURL(photoUrl);
      if (displayName != null) await user.updateDisplayName(displayName);
      await user.reload(); // Refresh user
    }

    // B. Cập nhật MongoDB (Để lưu lâu dài)
    try {
      Map<String, dynamic> body = {};
      if (photoUrl != null) body['photoURL'] = photoUrl;
      if (displayName != null) body['displayName'] = displayName;

      await http.put(
        Uri.parse('$_baseUrl/api/users/$userId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
    } catch (e) {
      print("Lỗi sync MongoDB: $e");
    }
  }
}
