import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_reader/models/chat_message.dart';
import 'package:smart_reader/repositories/ai_chat_repository.dart';
import 'package:smart_reader/theme/app_colors.dart';
import 'bloc/ai_chat_bloc.dart';
import 'bloc/ai_chat_event.dart';
import 'bloc/ai_chat_state.dart';

class AIChatDialog extends StatefulWidget {
  final String bookId;
  final String? chapterId;
  final String bookTitle;
  final String chapterTitle;
  final String chapterContent;

  const AIChatDialog({
    super.key,
    required this.bookId,
    this.chapterId,
    required this.bookTitle,
    required this.chapterTitle,
    required this.chapterContent,
  });

  @override
  State<AIChatDialog> createState() => _AIChatDialogState();
}

class _AIChatDialogState extends State<AIChatDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return BlocProvider(
      create: (_) => AIChatBloc(
        repository: AIChatRepository(),
        bookId: widget.bookId,
        chapterId: widget.chapterId,
      )..add(
          InitializeChat(bookId: widget.bookId, chapterId: widget.chapterId),
        ),
      child: Builder(
        builder: (dialogContext) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: SizedBox(
              width: size.width * 0.9,
              height: size.height * 0.78,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  children: [
                    _buildHeader(dialogContext),
                    Expanded(child: _buildMessages(dialogContext)),
                    _buildError(),
                    _buildInput(dialogContext),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext dialogContext) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Assistant',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${widget.bookTitle} • ${widget.chapterTitle}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    letterSpacing: 0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Đóng',
            onPressed: () => Navigator.pop(dialogContext),
            icon: const Icon(Icons.close, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages(BuildContext dialogContext) {
    return Container(
      color: const Color(0xFFF8FFFD),
      child: BlocBuilder<AIChatBloc, AIChatState>(
        builder: (context, state) {
          final messages = state.messages;

          if (state is AIChatInitial || messages.isEmpty) {
            return _buildEmptyState(dialogContext);
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return message.isLoading
                  ? _buildLoadingBubble()
                  : _buildMessageBubble(context, message);
            },
          );
        },
      ),
    );
  }

  Widget _buildError() {
    return BlocBuilder<AIChatBloc, AIChatState>(
      builder: (context, state) {
        if (state is! AIChatError) return const SizedBox();

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.08),
            border: Border.all(color: Colors.red.withOpacity(0.35)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.error,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInput(BuildContext dialogContext) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: 'Hỏi AI về nội dung...',
                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.55)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
                ),
              ),
              maxLines: null,
              onSubmitted: (_) => _sendMessage(dialogContext),
            ),
          ),
          const SizedBox(width: 8),
          BlocBuilder<AIChatBloc, AIChatState>(
            builder: (context, state) {
              final isLoading = state is AIChatLoading;
              return InkWell(
                onTap: isLoading ? null : () => _sendMessage(dialogContext),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLoading ? AppColors.greyLight : AppColors.primary,
                  ),
                  child: isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext dialogContext) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chào bạn!',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hỏi AI về nội dung chương này',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildQuickQuestion(dialogContext, 'Tóm tắt chương này'),
                _buildQuickQuestion(dialogContext, 'Giải thích nhân vật'),
                _buildQuickQuestion(dialogContext, 'Chủ đề chính là gì?'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickQuestion(BuildContext dialogContext, String question) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        _controller.text = question;
        _sendMessage(dialogContext);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          border: Border.all(color: AppColors.primary.withOpacity(0.28)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          question,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    final isUser = message.isUser;
    final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.64;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(isUser: false),
            const SizedBox(width: 8),
          ],
          Flexible(
            fit: FlexFit.loose,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser ? AppColors.primary.withOpacity(0.15) : Colors.white,
                  border: Border.all(
                    color: isUser
                        ? AppColors.primary.withOpacity(0.25)
                        : Colors.grey.withOpacity(0.16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: Radius.circular(isUser ? 12 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 12),
                  ),
                ),
                child: Text(
                  _formatMessageText(message.text),
                  textAlign: TextAlign.left,
                  softWrap: true,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    height: 1.45,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(isUser: true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar({required bool isUser}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUser ? AppColors.primary.withOpacity(0.16) : Colors.white,
        border: Border.all(color: AppColors.primary.withOpacity(0.34)),
      ),
      child: Icon(
        isUser ? Icons.person_outline : Icons.smart_toy_outlined,
        color: AppColors.primary,
        size: 18,
      ),
    );
  }

  String _formatMessageText(String text) {
    return text
        .replaceAll(RegExp(r'\r\n?'), '\n')
        .replaceAll(RegExp(r'^\s+', multiLine: true), '')
        .replaceAll(RegExp(r'\n\s*\*\s+'), '\n- ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _buildAvatar(isUser: false),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.withOpacity(0.16)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: List.generate(3, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: AnimatedOpacity(
                    opacity: 0.6,
                    duration: Duration(milliseconds: 300 + (index * 200)),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context) {
    final question = _controller.text.trim();
    if (question.isEmpty) return;

    final bloc = context.read<AIChatBloc>();
    bloc.add(
      SendChatMessage(
        question: question,
        context: bloc.useRAG ? "" : widget.chapterContent,
      ),
    );

    _controller.clear();
  }
}
