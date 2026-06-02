import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_reader/models/chapter_info.dart';
import 'package:smart_reader/models/highlight.dart';
import 'package:smart_reader/repositories/book_repository.dart';
import 'package:smart_reader/repositories/user_repository.dart';
import 'package:smart_reader/screens/ai_chat/ai_chat_dialog.dart';
import 'package:smart_reader/screens/reader/bloc/reader_bloc.dart';
import 'package:smart_reader/screens/reader/bloc/reader_state.dart';
import 'package:smart_reader/theme/app_colors.dart';

// === 1. WIDGET Vá»Ž (WRAPPER) - NHIá»†M Vá»¤ KHá»žI Táº O BLOC ===
class ReaderScreen extends StatelessWidget {
  final String bookId;
  final String chapterId;
  final String bookTitle;
  final String chapterTitle;
  final List<ChapterInfo> allChapters;
  final int currentChapterIndex;

  const ReaderScreen({
    super.key,
    required this.bookId,
    required this.chapterId,
    required this.bookTitle,
    required this.chapterTitle,
    required this.allChapters,
    required this.currentChapterIndex,
  });

  @override
  Widget build(BuildContext context) {
    // Khá»Ÿi táº¡o BlocProvider á»Ÿ Ä‘Ã¢y
    return BlocProvider(
      create: (context) => ReaderBloc(repository: BookRepository())
        ..add(LoadChapterContentEvent(chapterId: chapterId)),
      // Gá»i Widget con chá»©a giao diá»‡n
      child: ReaderView(
        bookId: bookId,
        chapterId: chapterId,
        bookTitle: bookTitle,
        chapterTitle: chapterTitle,
        allChapters: allChapters,
        currentChapterIndex: currentChapterIndex,
      ),
    );
  }
}

// === 2. WIDGET GIAO DIá»†N & LOGIC (VIEW) ===
class ReaderView extends StatefulWidget {
  final String bookId;
  final String chapterId;
  final String bookTitle;
  final String chapterTitle;
  final List<ChapterInfo> allChapters;
  final int currentChapterIndex;

  const ReaderView({
    super.key,
    required this.bookId,
    required this.chapterId,
    required this.bookTitle,
    required this.chapterTitle,
    required this.allChapters,
    required this.currentChapterIndex,
  });

  @override
  State<ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends State<ReaderView> {
  DateTime? _startTime;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoadingAudio = false;
  bool _isLoadingHighlights = false;
  String? _loadedHighlightsForChapter;
  String _selectedText = '';
  int _selectionStart = -1;
  int _selectionEnd = -1;
  List<Highlight> _highlights = [];

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- LOGIC TTS (TEXT TO SPEECH) ---
  String _stripHtml(String htmlString) {
    htmlString = htmlString.replaceAll(
      RegExp(r'<\s*/?\s*(p|div|br|li|h[1-6])[^>]*>', caseSensitive: false),
      '\n',
    );
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    String text = htmlString.replaceAll(exp, ' ');
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&');
    return text
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n\s*\n+'), '\n\n')
        .trim();
  }

  Future<void> _loadHighlightsIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;
    final marker = '${user?.uid ?? "guest"}:${widget.chapterId}';

    if (user == null || _loadedHighlightsForChapter == marker) return;

    _loadedHighlightsForChapter = marker;
    setState(() => _isLoadingHighlights = true);

    try {
      final repo = context.read<BookRepository>();
      final highlights = await repo.fetchHighlights(
        userId: user.uid,
        bookId: widget.bookId,
        chapterId: widget.chapterId,
      );
      if (mounted) {
        setState(() => _highlights = highlights);
      }
    } catch (e) {
      debugPrint('Load highlights error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingHighlights = false);
    }
  }

  Future<void> _saveSelectedHighlight() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để highlight.')),
      );
      return;
    }

    if (_selectedText.trim().isEmpty || _selectionStart < 0 || _selectionEnd <= _selectionStart) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy bôi đen đoạn muốn highlight trước.')),
      );
      return;
    }

    try {
      final repo = context.read<BookRepository>();
      final highlight = await repo.createHighlight(
        userId: user.uid,
        bookId: widget.bookId,
        chapterId: widget.chapterId,
        selectedText: _selectedText.trim(),
        startOffset: _selectionStart,
        endOffset: _selectionEnd,
      );

      if (mounted) {
        setState(() {
          _highlights = [..._highlights, highlight];
          _selectedText = '';
          _selectionStart = -1;
          _selectionEnd = -1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã highlight đoạn đã chọn.')),
        );
      }
    } catch (e) {
      debugPrint('Create highlight error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể lưu highlight.')),
        );
      }
    }
  }

  Future<void> _deleteHighlight(Highlight highlight) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await context.read<BookRepository>().deleteHighlight(
            userId: user.uid,
            highlightId: highlight.id,
          );
      if (mounted) {
        setState(() {
          _highlights = _highlights.where((item) => item.id != highlight.id).toList();
        });
      }
    } catch (e) {
      debugPrint('Delete highlight error: $e');
    }
  }

  void _showHighlightsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đoạn đã highlight',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (_highlights.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Chưa có highlight nào.')),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _highlights.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = _highlights[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.format_color_fill, color: AppColors.primary),
                          title: Text(
                            item.selectedText,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await _deleteHighlight(item);
                              if (context.mounted) Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  TextSpan _buildHighlightedTextSpan(String text) {
    final ranges = _highlights
        .where((item) => item.startOffset >= 0 && item.endOffset <= text.length)
        .map((item) => (start: item.startOffset, end: item.endOffset))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    final spans = <TextSpan>[];
    var cursor = 0;

    for (final range in ranges) {
      if (range.start < cursor || range.start >= range.end) continue;
      if (range.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, range.start)));
      }
      spans.add(
        TextSpan(
          text: text.substring(range.start, range.end),
          style: const TextStyle(backgroundColor: Color(0xFFFFF59D)),
        ),
      );
      cursor = range.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return TextSpan(children: spans);
  }

  void _handleListenChapter() async {
    final state = context.read<ReaderBloc>().state;
    if (state is! ReaderLoaded) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
      return;
    }

    setState(() => _isLoadingAudio = true);

    try {
      String cleanText = _stripHtml(state.chapter.content);
      if (cleanText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chương này chưa có nội dung để đọc.')),
        );
        return;
      }

      if (cleanText.length > 4000) {
        cleanText = '${cleanText.substring(0, 4000)}...';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chỉ đọc 4000 ký tự đầu.')),
        );
      }

      final repo = context.read<BookRepository>();
      final base64String = await repo.getAudioFromText(cleanText);

      if (base64String != null) {
        final bytes = base64Decode(base64String);
        await _audioPlayer.play(BytesSource(bytes));
        setState(() => _isPlaying = true);

        _audioPlayer.onPlayerComplete.listen((event) {
          if (mounted) setState(() => _isPlaying = false);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi tải âm thanh')),
        );
      }
    } catch (e) {
      debugPrint('TTS error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải âm thanh.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingAudio = false);
    }
  }

  // --- LOGIC AI CHAT ---
  Future<void> _openAIChatDialog(BuildContext context) async {
    final state = context.read<ReaderBloc>().state;
    if (state is! ReaderLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đang tải nội dung, vui lòng chờ...")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AIChatDialog(
        bookId: widget.bookId,
        chapterId: widget.chapterId,
        bookTitle: widget.bookTitle,
        chapterTitle: widget.chapterTitle,
        chapterContent: state.chapter.content,
      ),
    );
  }

  // --- LOGIC THá»NG KÃŠ (STATS) ---
  Future<void> _updateStats() async {
    if (_startTime == null) return;
    final minutes = DateTime.now().difference(_startTime!).inMinutes;

    // Táº¯t kiá»ƒm tra < 1 phÃºt Ä‘á»ƒ test cho dá»…, khi release thÃ¬ má»Ÿ láº¡i
    // if (minutes < 1) return;

    int currentIndex = widget.currentChapterIndex;
    int totalChapters = widget.allChapters.length;
    final isLastChapter = currentIndex == (totalChapters - 1);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await context.read<UserRepository>().updateReadingStats(
            userId: user.uid,
            bookId: widget.bookId,
            minutesRead: minutes,
            isBookFinished: isLastChapter,
          );
    }
  }

  void _saveProgress() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<UserRepository>().saveReadingProgress(
            userId: user.uid,
            bookId: widget.bookId,
            chapterId: widget.chapterId,
          );
    }
  }

  Future<void> _onExit() async {
    await _updateStats();
    _saveProgress();
    if (mounted) Navigator.pop(context);
  }

  void _showSummarySheet(String summary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Cho phÃ©p chá»‰nh chiá»u cao tÃ¹y Ã½
      backgroundColor: Colors.transparent, // Äá»ƒ bo gÃ³c Ä‘áº¹p hÆ¡n
      builder: (context) {
        return Container(
          height:
              MediaQuery.of(context).size.height * 0.7, // Chiáº¿m 70% mÃ n hÃ¬nh
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TiÃªu Ä‘á» ---
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "AI Tóm tắt chương",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const Divider(height: 30),

              // --- Ná»™i dung tÃ³m táº¯t ---
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    summary,
                    style: const TextStyle(
                        fontSize: 16,
                        height: 1.6, // GiÃ£n dÃ²ng cho dá»… Ä‘á»c
                        color: Colors.black87),
                  ),
                ),
              ),

              // --- NÃºt Ä‘Ã³ng ---
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  child: const Text("Đã hiểu"),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _handleSummarize() async {
    // 1. Láº¥y ná»™i dung chÆ°Æ¡ng hiá»‡n táº¡i tá»« Bloc
    final state = context.read<ReaderBloc>().state;
    if (state is! ReaderLoaded) return;

    // 2. Hiá»‡n Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary)),
    );

    try {
      // 3. Lá»c sáº¡ch HTML (DÃ¹ng láº¡i hÃ m _stripHtml báº¡n Ä‘Ã£ viáº¿t á»Ÿ pháº§n TTS)
      String cleanText = _stripHtml(state.chapter.content);

      // Cáº¯t bá»›t náº¿u quÃ¡ dÃ i (Gemini 2.5 Flash xá»­ lÃ½ Ä‘Æ°á»£c ráº¥t nhiá»u, nhÆ°ng cáº¯t cho an toÃ n Ä‘Æ°á»ng truyá»n)
      if (cleanText.length > 20000) {
        cleanText = cleanText.substring(0, 20000);
      }

      // 4. Gá»i Repository
      final repo = context.read<BookRepository>();
      final summary = await repo.summarizeChapter(cleanText);

      // Táº¯t Loading
      if (mounted) Navigator.pop(context);

      if (summary != null) {
        // 5. Hiá»‡n káº¿t quáº£
        if (mounted) _showSummarySheet(summary);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("AI không thể tóm tắt lúc này.")),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Táº¯t loading náº¿u lá»—i
      print("Lỗi tóm tắt: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // KHÃ”NG bá»c BlocProvider á»Ÿ Ä‘Ã¢y ná»¯a
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (didPop) {
          _saveProgress();
          await _updateStats();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(context),
        body: _buildBody(context),
        bottomNavigationBar: _buildBottomCustomNav(context),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: _onExit, // Gá»i hÃ m thoÃ¡t chuáº©n
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.bookTitle,
            style: const TextStyle(
                color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500),
          ),
          Text(
            "Chương ${widget.currentChapterIndex + 1}/${widget.allChapters.length}",
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Highlight',
          icon: Icon(
            Icons.border_color_rounded,
            color: _selectedText.trim().isEmpty ? Colors.black54 : AppColors.primary,
          ),
          onPressed: _saveSelectedHighlight,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black),
          onPressed: _showHighlightsSheet,
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<ReaderBloc, ReaderState>(
      builder: (context, state) {
        if (state is ReaderLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ReaderLoaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadHighlightsIfNeeded();
          });

          final plainText = _stripHtml(state.chapter.content);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  widget.chapterTitle,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 16),
                if (_isLoadingHighlights)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                SelectableText.rich(
                  _buildHighlightedTextSpan(plainText),
                  style: const TextStyle(
                      fontSize: 16, height: 1.6, color: Colors.black87),
                  textAlign: TextAlign.left,
                  onSelectionChanged: (selection, cause) {
                    if (selection.isCollapsed ||
                        selection.start < 0 ||
                        selection.end > plainText.length) {
                      setState(() {
                        _selectedText = '';
                        _selectionStart = -1;
                        _selectionEnd = -1;
                      });
                      return;
                    }

                    setState(() {
                      _selectionStart = selection.start;
                      _selectionEnd = selection.end;
                      _selectedText = plainText.substring(selection.start, selection.end);
                    });
                  },
                ),
                _buildChapterNavigation(context),
              ],
            ),
          );
        }
        if (state is ReaderError) {
          return Center(child: Text(state.message));
        }
        return const Center(child: Text("Đang tải..."));
      },
    );
  }

  Widget _buildBottomCustomNav(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      elevation: 8.0,
      height: 90,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Divider(height: 1.0, thickness: 1.0, color: Colors.grey[300]),
          const SizedBox(height: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // --- NÃšT NGHE SÃCH (ÄÃ£ sá»­a) ---
                  _buildCustomNavItem(
                    icon: _isLoadingAudio
                        ? Icons.hourglass_empty
                        : (_isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled),
                    label: _isLoadingAudio
                        ? "Đang tải..."
                        : (_isPlaying ? "Dừng lại" : "Nghe sách"),
                    iconColor:
                        _isPlaying ? Colors.red : const Color(0xFF28C7A0),
                    bgColor: _isPlaying
                        ? const Color(0xFFFFF0F0)
                        : const Color(0xFFE0F8F3),
                    onTap: _isLoadingAudio ? () {} : _handleListenChapter,
                  ),
                  // -----------------------------
                  _buildCustomNavItem(
                    icon: Icons.description_rounded,
                    label: "Tóm tắt",
                    iconColor: const Color(0xFFF96060),
                    bgColor: const Color(0xFFFFF0F0),
                    onTap: _handleSummarize,
                  ),
                  _buildCustomNavItem(
                    icon: Icons.chat_rounded,
                    label: "AI Chat",
                    iconColor: const Color(0xFFFFA940),
                    bgColor: const Color(0xFFFFF8ED),
                    onTap: () => _openAIChatDialog(context),
                  ),
                  _buildCustomNavItem(
                    icon: Icons.settings_rounded,
                    label: "Cài đặt",
                    iconColor: const Color(0xFF505A66),
                    bgColor: const Color(0xFFF0F2F5),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomNavItem({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildChapterNavigation(BuildContext context) {
    final bool hasPrevious = widget.currentChapterIndex > 0;
    final bool hasNext =
        widget.currentChapterIndex < widget.allChapters.length - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (hasPrevious)
          TextButton(
            onPressed: () {
              final prev = widget.allChapters[widget.currentChapterIndex - 1];
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ReaderScreen(
                    bookId: widget.bookId,
                    chapterId: prev.id,
                    bookTitle: widget.bookTitle,
                    chapterTitle: prev.title,
                    allChapters: widget.allChapters,
                    currentChapterIndex: widget.currentChapterIndex - 1,
                  ),
                ),
              );
            },
            child: const Row(children: [
              Icon(Icons.arrow_back_ios, size: 13, color: Colors.black),
              Text("Chương trước", style: TextStyle(color: Colors.black))
            ]),
          )
        else
          Container(),
        if (hasNext)
          TextButton(
            onPressed: () {
              final next = widget.allChapters[widget.currentChapterIndex + 1];
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ReaderScreen(
                    bookId: widget.bookId,
                    chapterId: next.id,
                    bookTitle: widget.bookTitle,
                    chapterTitle: next.title,
                    allChapters: widget.allChapters,
                    currentChapterIndex: widget.currentChapterIndex + 1,
                  ),
                ),
              );
            },
            child: const Row(children: [
              Text("Chương sau", style: TextStyle(color: Colors.black)),
              Icon(Icons.arrow_forward_ios, size: 13, color: Colors.black)
            ]),
          )
        else
          Container(),
      ],
    );
  }
}
