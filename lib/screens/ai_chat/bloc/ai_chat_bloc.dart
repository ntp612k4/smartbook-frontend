import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_reader/models/chat_message.dart';
import 'package:smart_reader/repositories/ai_chat_repository.dart';
import 'ai_chat_event.dart';
import 'ai_chat_state.dart';

class AIChatBloc extends Bloc<AIChatEvent, AIChatState> {
  final AIChatRepository repository;
  final String bookId;
  String? chapterId;

  late String userId;

  // ✅ NEW: RAG Mode Flag
  bool useRAG = true; // ✅ TRUE - Dùng RAG để tiết kiệm token!

  AIChatBloc({
    required this.repository,
    required this.bookId,
    this.chapterId,
  }) : super(const AIChatInitial()) {
    // Lấy userId từ Firebase
    final user = FirebaseAuth.instance.currentUser;
    userId = user?.uid ?? 'anonymous';

    // Lắng nghe events
    on<InitializeChat>(_onInitializeChat);
    on<SendChatMessage>(_onSendChatMessage);
    on<ClearChat>(_onClearChat);
  }

  // Khởi tạo chat (clear lịch sử)
  Future<void> _onInitializeChat(
    InitializeChat event,
    Emitter<AIChatState> emit,
  ) async {
    chapterId = event.chapterId;
    emit(const AIChatLoaded(messages: []));
  }

  // Gửi câu hỏi tới AI
  Future<void> _onSendChatMessage(
    SendChatMessage event,
    Emitter<AIChatState> emit,
  ) async {
    // 1. Lấy danh sách messages hiện tại
    List<ChatMessage> currentMessages = state.messages;

    // 2. Thêm message của user
    final userMessage = ChatMessage.fromUser(event.question);
    currentMessages = [...currentMessages, userMessage];

    // 3. Hiển thị loading state (AI đang suy nghĩ)
    final loadingMessage = ChatMessage.loading();
    emit(AIChatLoading(messages: [...currentMessages, loadingMessage]));

    try {
      // 4. ✅ NEW: Choose method (RAG or Legacy)
      String aiResponse;

      if (useRAG) {
        // ✅ RAG: Vector Search Mode (không cần truyền context)
        print('🚀 Using RAG method...');
        try {
          final ragResult = await repository.askAI_RAG(
            userId: userId,
            bookId: bookId,
            chapterId: chapterId,
            question: event.question,
          );
          aiResponse = ragResult['answer'] ?? "Không thể lấy câu trả lời";
          print('✅ RAG Response received');
        } catch (ragError) {
          // Fallback to Legacy if RAG fails
          print('⚠️ RAG failed, falling back to Legacy: $ragError');
          aiResponse = await repository.askAI(
            userId: userId,
            bookId: bookId,
            chapterId: chapterId,
            question: event.question,
            context: event.context,
          );
          print('✅ Fallback to Legacy successful');
        }
      } else {
        // ❌ Legacy: Prompt Engineering Mode (cần truyền context)
        print('📝 Using Legacy Prompt Engineering method...');
        aiResponse = await repository.askAI(
          userId: userId,
          bookId: bookId,
          chapterId: chapterId,
          question: event.question,
          context: event.context, // Full chapter content
        );
        print('✅ Legacy Response received');
      }

      // 5. Thêm response từ AI
      final aiMessage = ChatMessage.fromAI(aiResponse);
      currentMessages = [...currentMessages, aiMessage];

      // 6. Emit loaded state với messages
      emit(AIChatLoaded(messages: currentMessages));
    } catch (e) {
      print('❌ AI Chat Error: $e');
      // Giữ lại messages cũ nhưng hiển thị error
      emit(AIChatError(
        error: e.toString(),
        messages: currentMessages,
      ));

      // Sau 3 giây, quay lại loaded state
      await Future.delayed(const Duration(seconds: 3));
      emit(AIChatLoaded(messages: currentMessages));
    }
  }

  // Xóa lịch sử chat
  Future<void> _onClearChat(
    ClearChat event,
    Emitter<AIChatState> emit,
  ) async {
    emit(const AIChatLoaded(messages: []));
  }
}
