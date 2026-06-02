import 'package:equatable/equatable.dart';

abstract class AIChatEvent extends Equatable {
  const AIChatEvent();

  @override
  List<Object?> get props => [];
}

// Khởi tạo chat (clear messages)
class InitializeChat extends AIChatEvent {
  final String bookId;
  final String? chapterId;
  const InitializeChat({required this.bookId, this.chapterId});

  @override
  List<Object?> get props => [bookId, chapterId];
}

// Gửi câu hỏi tới AI
class SendChatMessage extends AIChatEvent {
  final String question;
  final String context; // Nội dung/tóm tắt để AI sử dụng

  const SendChatMessage({
    required this.question,
    required this.context,
  });

  @override
  List<Object?> get props => [question, context];
}

// Clear lịch sử chat
class ClearChat extends AIChatEvent {
  const ClearChat();
}
