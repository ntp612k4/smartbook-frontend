import 'package:equatable/equatable.dart';
import 'package:smart_reader/models/chat_message.dart';

abstract class AIChatState extends Equatable {
  final List<ChatMessage> messages;

  const AIChatState({this.messages = const []});

  @override
  List<Object?> get props => [messages];
}

// Trạng thái ban đầu
class AIChatInitial extends AIChatState {
  const AIChatInitial();
}

// Đang tải
class AIChatLoading extends AIChatState {
  const AIChatLoading({required List<ChatMessage> messages})
      : super(messages: messages);

  @override
  List<Object?> get props => [messages];
}

// Đã tải xong
class AIChatLoaded extends AIChatState {
  const AIChatLoaded({required List<ChatMessage> messages})
      : super(messages: messages);

  @override
  List<Object?> get props => [messages];
}

// Lỗi
class AIChatError extends AIChatState {
  final String error;

  const AIChatError({
    required this.error,
    required List<ChatMessage> messages,
  }) : super(messages: messages);

  @override
  List<Object?> get props => [error, messages];
}
