// phong
import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String id;
  final String text;
  final bool isUser; // true = user, false = AI
  final DateTime timestamp;
  final bool isLoading; // Cho thấy AI đang suy nghĩ

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
  });

  @override
  List<Object?> get props => [id, text, isUser, timestamp, isLoading];

  // Khởi tạo message user
  factory ChatMessage.fromUser(String text) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  // Khởi tạo message AI
  factory ChatMessage.fromAI(String text) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: false,
      timestamp: DateTime.now(),
    );
  }

  // Loading state khi AI đang suy nghĩ
  factory ChatMessage.loading() {
    return ChatMessage(
      id: 'loading_${DateTime.now().millisecondsSinceEpoch}',
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
      isLoading: true,
    );
  }
}
