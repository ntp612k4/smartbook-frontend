import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_reader/models/book.dart';
import 'package:smart_reader/models/chapter_info.dart';
import 'package:smart_reader/models/reivew.dart';
import 'package:smart_reader/repositories/book_repository.dart';
import 'package:smart_reader/repositories/user_repository.dart';
import 'package:smart_reader/screens/book_detail/bloc/book_detail_bloc.dart';
import 'package:smart_reader/screens/book_detail/bloc/book_detail_event.dart';
import 'package:smart_reader/screens/book_detail/bloc/book_detail_state.dart';
import 'package:smart_reader/screens/home/bloc/home_bloc.dart';
import 'package:smart_reader/screens/home/bloc/home_event.dart';
import 'package:smart_reader/screens/reader/reader_screen.dart';
import 'package:smart_reader/theme/app_colors.dart';
import 'package:smart_reader/widgets/buttons.dart';
// ... import cÃ¡c file BLoC vÃ  Repository cá»§a báº¡n

class BookDetailScreen extends StatefulWidget {
  final String bookId;

  const BookDetailScreen({super.key, required this.bookId});
  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  bool isAdded = false; // Tráº¡ng thÃ¡i nÃºt báº¥m
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  // Kiá»ƒm tra xem sÃ¡ch Ä‘Ã£ cÃ³ trong thÆ° viá»‡n chÆ°a Ä‘á»ƒ hiá»‡n Ä‘Ãºng mÃ u nÃºt
  void _checkStatus() async {
    if (user != null) {
      final status = await context.read<UserRepository>().checkIsAdded(
            user!.uid,
            widget.bookId,
          );
      setState(() {
        isAdded = status;
      });
    }
  }

  // HÃ m xá»­ lÃ½ khi báº¥m nÃºt
  void _onToggleLibrary() async {
    if (user == null) {
      // Show dialog báº¯t Ä‘Äƒng nháº­p
      return;
    }

    // 1. Gá»i API
    final newStatus = await context.read<UserRepository>().toggleLibrary(
          user!.uid,
          widget.bookId,
        );

    // 2. Cáº­p nháº­t UI nÃºt báº¥m
    setState(() {
      isAdded = newStatus;
    });

    // 3. Quan trá»ng: Reload láº¡i dá»¯ liá»‡u trang Home Ä‘á»ƒ danh sÃ¡ch cáº­p nháº­t
    if (context.mounted) {
      context.read<HomeBloc>().add(LoadHomeDataEvent(userId: user!.uid));
    }

    // 4. ThÃ´ng bÃ¡o nhá»
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus ? "Đã thêm vào thư viện" : "Đã xóa khỏi thư viện",
        ),
      ),
    );
  }

  // --- HÃ€M Má»ž FORM BÃŒNH LUáº¬N (Má»šI) ---
  // Trong class _BookDetailScreenState

  void _showReviewForm(BuildContext context, String bookId) {
    // 1. Láº¥y instance cá»§a Bloc Ä‘ang cháº¡y Tá»ª TRONG SCOPE Cá»¦A BOOKDETAILSCREEN
    final bookDetailBloc = context.read<BookDetailBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (modalContext) {
        // DÃ¹ng modalContext cho Widget con

        // 2. Bá»c Form nháº­p liá»‡u báº±ng BlocProvider.value
        return BlocProvider.value(
          value: bookDetailBloc, // ðŸŽ¯ Truyá»n instance Bloc Ä‘Ã£ láº¥y vÃ o Route má»›i
          child: ReviewInputForm(bookId: bookId),
        );
      },
    ).then((_) {
      // TÃ¹y chá»n: Reload láº¡i dá»¯ liá»‡u trang chi tiáº¿t khi modal Ä‘Ã³ng
      if (context.mounted) {
        // Reload Ä‘á»ƒ cáº­p nháº­t list reviews vÃ  Ä‘iá»ƒm
        bookDetailBloc.add(LoadBookDetailEvent(bookId: widget.bookId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Khá»Ÿi táº¡o BLoC vÃ  táº£i dá»¯ liá»‡u ngay láº­p tá»©c
    return BlocProvider(
      create: (context) => BookDetailBloc(repository: BookRepository())
        ..add(LoadBookDetailEvent(bookId: widget.bookId)),
      child: Scaffold(
        body: BlocBuilder<BookDetailBloc, BookDetailState>(
          builder: (context, state) {
            if (state is BookDetailLoading || state is BookDetailInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is BookDetailLoaded) {
              final book = state.book;
              final reviews = state.reviews;
              return _buildLoadedContent(context, book, reviews);
            }

            if (state is BookDetailError) {
              return Center(child: Text(state.message));
            }

            return const Center(child: Text("Đang tải chi tiết sách..."));
          },
        ),
      ),
    );
  }

  // PhÆ°Æ¡ng thá»©c tÃ¡ch riÃªng Ä‘á»ƒ xÃ¢y dá»±ng UI sau khi táº£i dá»¯ liá»‡u thÃ nh cÃ´ng
  Widget _buildLoadedContent(
      BuildContext context, Book book, List<Review> reviews) {
    // Sá»­ dá»¥ng DefaultTabController Ä‘á»ƒ quáº£n lÃ½ 3 tabs: About, Chapters, Reviews
    return DefaultTabController(
      length: 3,
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverList(
              delegate: SliverChildListDelegate([
                // Äáº·t SafeArea xung quanh CustomHeaderIcons
                SafeArea(
                  bottom: false, // KhÃ´ng Ã¡p dá»¥ng padding dÆ°á»›i
                  child: _buildCustomHeaderIcons(context, book.title),
                ),
              ]),
            ),
            SliverAppBar(
              toolbarHeight: 0,
              pinned: false,
              expandedHeight: 320.0, // Chiá»u cao tá»‘i Ä‘a cá»§a header

              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Padding(
                  padding: const EdgeInsets.only(top: 3, left: 16, right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // _buildCustomHeaderIcons(context, book.title),
                      _buildBookInfo(book), // Chá»©a áº£nh vÃ  chi tiáº¿t sÃ¡ch
                      const SizedBox(height: 20),
                      _buildActionButtons(context, book),
                    ],
                  ),
                ),
              ),

              // TabBar cá»‘ Ä‘á»‹nh
              bottom: const TabBar(
                indicatorColor: AppColors.primary,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textDark,
                tabs: [
                  Tab(text: "Tóm tắt"),
                  Tab(text: "Chương"),
                  Tab(text: "Đánh giá"),
                ],
              ),
            ),
          ];
        },
        // Ná»™i dung cá»§a Tab Bar View
        body: TabBarView(
          children: [
            BookSynopsisTab(book: book),
            BookChaptersTab(book: book, chapters: book.chapters),
            BookReviewsTab(bookId: book.bookId, reviews: reviews),
          ],
        ),
      ),
    );
  }

  // Trong class BookDetailScreen (ThÃªm vÃ o cÃ¹ng nÆ¡i vá»›i cÃ¡c hÃ m _build...)

  Widget _buildCustomHeaderIcons(BuildContext context, String title) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.black),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
  // Trong BookDetailScreen.dart (HÃ m _buildActionButtons)

  Widget _buildActionButtons(BuildContext context, Book book) {
    // Láº¥y tráº¡ng thÃ¡i cá»§a nÃºt Add to Library
    // final bool isAdded = book.isAddedToLibrary;

    return Column(
      children: [
        // HÃ ng 1: Listen Now (ChÃ­nh) vÃ  Read Now (Phá»¥)
        Row(
          children: [
            // 1. Listen Now (NÃºt chÃ­nh)
            ListButtons(
              "Nghe ngay",
              Icons.play_arrow,
              () {},
              isPrimary: true, //nÃºt chÃ­nh
            ),
            const SizedBox(width: 10),
            ListButtons("Đọc ngay", Icons.menu_book, () {
              print('Ä‘ang vÃ o chÆ°Æ¡ng 1 Ä‘á»c');
              //kiem tra xem danh sach co chuong nÃ o ko
              if (book.chapters.isNotEmpty) {
                final firstChapter = book.chapters[0];

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReaderScreen(
                      chapterId: firstChapter.id,
                      chapterTitle: firstChapter.title,
                      bookTitle: book.title,

                      allChapters: book.chapters,
                      currentChapterIndex: 0,
                      bookId: book.bookId, // First chapter has index 0
                    ),
                  ),
                );
              } else {
                // TÃ¹y chá»n: Hiá»ƒn thá»‹ thÃ´ng bÃ¡o náº¿u khÃ´ng cÃ³ chÆ°Æ¡ng
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Sách này hiện chưa có chương nào."),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }),
          ],
        ),

        const SizedBox(height: 10),

        // HÃ ng 2:
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 42, // 
                child: OutlinedButton.icon(
                  onPressed: _onToggleLibrary,

                  icon: Icon(
                    isAdded ? Icons.check : Icons.add,
                    color:
                        isAdded ? AppColors.primary : const Color(0xFF28C7A0),
                  ),

                  // Chá»¯ thay Ä‘á»•i theo tráº¡ng thÃ¡i
                  label: Text(
                    isAdded ? "Đã thêm" : "Thêm thư viện",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isAdded ? AppColors.primary : AppColors.primary,
                    ),
                  ),

                  // Style viá»n
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: isAdded ? AppColors.primary : AppColors.primary,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: () => _showReviewForm(
                      context, book.bookId), // ðŸŽ¯ Gáº®N HÃ€M VÃ€O ÄÃ‚Y
                  icon: Icon(Icons.edit, color: Colors.grey[700]),
                  label: Text("Bình luận",
                      style: TextStyle(color: Colors.grey[700])),
                  style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBookInfo(Book book) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage(book.imgUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  book.author.authorName,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      book.rating.toString(),
                      style: TextStyle(fontSize: 13, color: AppColors.textDark),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.star,
                      size: 15,
                      color: Colors.orangeAccent,
                    ),
                  ],
                ),
                Text(
                  "${book.chapters.length} Chương",
                  style: TextStyle(fontSize: 13, color: AppColors.textDark),
                ),
                // ThÃªm rating vÃ  thá»‘ng kÃª á»Ÿ Ä‘Ã¢y
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Cáº§n táº¡o cÃ¡c file widget nÃ y Ä‘á»ƒ chá»©a ná»™i dung tá»«ng Tab
class BookSynopsisTab extends StatelessWidget {
  final Book book;
  const BookSynopsisTab({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tóm tắt nội dung sách",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(book.description, style: TextStyle(color: Colors.black54)),
          // ... ThÃªm cÃ¡c Tags/Genres táº¡i Ä‘Ã¢y
        ],
      ),
    );
  }
}

class BookChaptersTab extends StatelessWidget {
  final Book book;
  final List<ChapterInfo> chapters;
  const BookChaptersTab({
    super.key,
    required this.book,
    required this.chapters,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        return ListTile(
          title: Text(chapter.title),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReaderScreen(
                  bookId: book.bookId,
                  // 1. ThÃ´ng tin chÆ°Æ¡ng hiá»‡n táº¡i
                  chapterId: chapter.id,
                  chapterTitle: chapter.title,
                  bookTitle: book.title,

                  // 2. ThÃ´ng tin Ä‘á»ƒ láº­t trang
                  allChapters: book.chapters,
                  currentChapterIndex: index,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ===========================================
// WIDGET CON: TAB VÃ€ FORM (THÃŠM VÃ€O CUá»I FILE)
// ===========================================

// A. BookReviewsTab (Hiá»ƒn thá»‹ danh sÃ¡ch)
class BookReviewsTab extends StatelessWidget {
  final String bookId;
  final List<Review> reviews;

  const BookReviewsTab(
      {super.key, required this.bookId, required this.reviews});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // NÃšT Má»ž FORM BÃŒNH LUáº¬N
        Padding(
          padding: const EdgeInsets.all(10),
          child: ElevatedButton.icon(
            onPressed: () {
              // Gá»i hÃ m má»Ÿ form tá»« State cha
              (context.findAncestorStateOfType<_BookDetailScreenState>()
                      as _BookDetailScreenState)
                  ._showReviewForm(context, bookId);
            },
            icon: const Icon(Icons.comment, color: Colors.white),
            label: const Text("Viết bình luận của bạn",
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                backgroundColor: AppColors.primary),
          ),
        ),

        // DANH SÃCH BÃŒNH LUáº¬N
        Expanded(
          child: reviews.isEmpty
              ? const Center(child: Text("Chưa có bình luận nào."))
              : ListView.builder(
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return ListTile(
                      // 1. AVATAR
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary.withOpacity(0.14),
                        backgroundImage: review.userPhoto.isNotEmpty
                            ? NetworkImage(review.userPhoto)
                            : null,
                        child: review.userPhoto.isEmpty
                            ? Text(
                                review.userName.isNotEmpty
                                    ? review.userName.substring(0, 1).toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),

                      // 2. TÃŠN USER
                      title: Text(
                        review.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(review.comment),
                      trailing:
                          Text(review.createdAt.toString().substring(0, 10)),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// B. ReviewInputForm (Form Nháº­p liá»‡u - Dáº¡ng BottomSheet)
class ReviewInputForm extends StatefulWidget {
  final String bookId;

  const ReviewInputForm({super.key, required this.bookId});

  @override
  State<ReviewInputForm> createState() => _ReviewInputFormState();
}

class _ReviewInputFormState extends State<ReviewInputForm> {
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() async {
    final user = FirebaseAuth.instance.currentUser;
    final commentText = _commentController.text.trim();

    if (user == null || _isSubmitting || commentText.isEmpty) {
      if (commentText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Vui lòng nhập nội dung bình luận.")));
      }
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = context.read<BookRepository>();

      // 1. Gá»­i bÃ¬nh luáº­n (Comment Only)
      await repo.submitReview(
        userId: user.uid,
        bookId: widget.bookId,
        comment: commentText,
        userName: user.displayName ?? '',
        userPhoto: user.photoURL ?? '',
      );

      // 2. ThÃ´ng bÃ¡o thÃ nh cÃ´ng vÃ  reload
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Bình luận của bạn đã được gửi!")));

        // ðŸŽ¯ RELOAD BLOC: Táº£i láº¡i chi tiáº¿t sÃ¡ch Ä‘á»ƒ list reviews Ä‘Æ°á»£c cáº­p nháº­t
        context
            .read<BookDetailBloc>()
            .add(LoadBookDetailEvent(bookId: widget.bookId));

        Navigator.pop(context); // ÄÃ³ng BottomSheet
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi: Không thể gửi bình luận: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 16,
          right: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Viết bình luận",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Ã” nháº­p comment
          TextField(
            controller: _commentController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Cảm nhận của bạn về cuốn sách...",
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitComment,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: AppColors.primary),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text("Gửi bình luận",
                      style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
