import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_reader/models/chapter_info.dart';
import 'package:smart_reader/models/reading_progess.dart';
import 'package:smart_reader/repositories/book_repository.dart';
import 'package:smart_reader/repositories/user_repository.dart';
import 'package:smart_reader/screens/book_detail/book_detail_screen.dart';
import 'package:smart_reader/screens/book_list/book_list_screen.dart';
import 'package:smart_reader/screens/category/category_screen.dart';
import 'package:smart_reader/screens/category_detail/category_detail_screen.dart';
import 'package:smart_reader/screens/home/bloc/home_bloc.dart';
import 'package:smart_reader/screens/home/bloc/home_event.dart';
import 'package:smart_reader/screens/home/bloc/home_state.dart';
import 'package:smart_reader/screens/author_detail/author_detail_screen.dart';
import 'package:smart_reader/screens/reader/reader_screen.dart';
import 'package:smart_reader/screens/search/search_screen.dart';
import 'package:smart_reader/theme/app_colors.dart';
import 'package:smart_reader/widgets/author_avatar.dart';
import 'package:smart_reader/widgets/continue_reading_card.dart';
import 'package:smart_reader/widgets/footer/footer.dart';
import 'package:smart_reader/widgets/special_card.dart';
import 'package:smart_reader/widgets/top_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _handleContinueReading(
    BuildContext context,
    ReadingProgress item,
  ) async {
    // 1. Hiện Loading để người dùng đợi
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2. Gọi API lấy chi tiết sách để có danh sách chương
      // (Dùng context.read để lấy Repository)
      final bookRepo = context.read<BookRepository>();
      final bookDetails = await bookRepo.fetchBookDetails(item.bookId);

      // 3. Convert danh sách chương từ Book -> ChapterInfo (nếu cần)
      // Giả sử bookDetails.chapters là List<dynamic> hoặc List<Chapter>
      // Bạn cần map nó sang List<ChapterInfo> mà ReaderScreen yêu cầu
      List<ChapterInfo> allChapters = bookDetails.chapters
          .map((c) => ChapterInfo(id: c.id, title: c.title, order: c.order))
          .toList();

      // ✅ Check if chapters exist
      if (allChapters.isEmpty) {
        if (context.mounted) Navigator.pop(context);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("❌ Sách này chưa có chương nào."),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // 4. Tìm vị trí (index) của chương đang đọc dở
      int index = allChapters.indexWhere((c) => c.id == item.chapterId);

      // Nếu không tìm thấy (lỡ chương đó bị xóa), cho về chương 1 (index 0)
      if (index == -1) index = 0;

      // 5. Tắt Loading
      if (context.mounted) Navigator.pop(context);

      // 6. Chuyển sang màn hình đọc
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReaderScreen(
              bookId: item.bookId,
              chapterId: allChapters[index].id, // Đảm bảo lấy ID từ list chuẩn
              bookTitle: item.title,
              chapterTitle: allChapters[index].title,
              allChapters: allChapters,
              currentChapterIndex: index,
            ),
          ),
        ).then((_) {
          // Khi quay lại từ màn hình đọc, reload lại Home để cập nhật tiến độ mới
          final user = FirebaseAuth.instance.currentUser;
          if (user != null && context.mounted) {
            context.read<HomeBloc>().add(LoadHomeDataEvent(userId: user.uid));
          }
        });
      }
    } catch (e) {
      // Tắt loading nếu lỗi
      if (context.mounted) Navigator.pop(context);

      print("Lỗi mở sách: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Không thể mở sách: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc(
        bookRepository: context.read<BookRepository>(),
        userRepository: context.read<UserRepository>(),
      )..add(LoadHomeDataEvent(userId: FirebaseAuth.instance.currentUser?.uid)),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            if (state is HomeLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (state is HomeLoaded) {
              return Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    onPressed: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(builder: (context) => HomeScreen()),
                      // );
                    },
                    icon: const Icon(Icons.book),
                    color: AppColors.primary,
                    iconSize: 24,
                  ),
                  leadingWidth: 40,
                  titleSpacing: 0,
                  title: const Text("SmartBook"),
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.search,
                        color: Colors.black,
                        size: 22,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchScreen(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.notifications,
                        color: Colors.black,
                        size: 22,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
                body: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Today's Pick",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textLight,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "Atomic Habits",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textLight,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        "by James Clear",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.textLight,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.background,
                                          // foregroundColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          "Đọc ngay",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  height: 140,
                                  child: Image.network(
                                    "https://static.oreka.vn/800-800_2a51b6cf-f9d0-4afa-a6c0-8fa6a89986cf.webp",
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Thể loại sách",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textDark,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CategoryScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Xem tất cả",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // SizedBox(height: 5),
                          // Categories Row
                          SizedBox(
                            height: 40,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: state.categories.map((c) {
                                return GestureDetector(
                                  onTap: () {
                                    print(
                                      "=> Category tapped: ${c.categoryName}",
                                    );
                                    context.read<HomeBloc>().add(
                                          CategorySelectedEvent(c),
                                        );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CategoryDetailScreen(category: c),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      c.categoryName,
                                      style: TextStyle(
                                        color: AppColors.textLight,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Tiếp tục đọc",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textDark,
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text(
                                  "Xem tất cả",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height:
                                210, // Tăng lên khoảng 200-220 (150 ảnh + text)
                            child: state.readingProgress.isEmpty
                                ? const Center(
                                    child: Text("Bạn chưa có sách đang đọc dở"),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    scrollDirection: Axis.horizontal,
                                    itemCount: state.readingProgress.length,
                                    itemBuilder: (context, index) {
                                      return ContinueReadingCard(
                                        progress: state.readingProgress[index],
                                        onTap: () {
                                          _handleContinueReading(
                                            context,
                                            state.readingProgress[index],
                                          );
                                        },
                                      );
                                    },
                                  ),
                          ),

                          // SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Tác giả nổi bật",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textDark,
                                ),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: const Text(
                                  "Xem tất cả",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 80,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: state.authors.map((a) {
                                return AuthorAvatar(
                                  name: a.authorName,
                                  avatarUrl: a.avatarUrl,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AuthorDetailScreen(
                                          authorId: a.authorId,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Sách mới",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textDark,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BookListScreen(
                                        title: "Sách mới",
                                        books: state.newBooks,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Xem tất cả",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: state.newBooks.map((c) {
                              return TopCard(
                                bookId: c.bookId,
                                imgUrl: c.imgUrl,
                                title: c.title,
                                author: c.author.authorName,
                                rating: c.rating,
                              );
                            }).toList(),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Sách đặc biệt dành cho bạn",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textDark,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BookListScreen(
                                        title: "Sách đặc biệt",
                                        books: state.specialBooks,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Xem tất cả",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 150,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: state.specialBooks.map((d) {
                                return SpecialCard(
                                  bookId: d.bookId,
                                  imgUrl: d.imgUrl,
                                  title: d.title,
                                  author: d.author.authorName,
                                  rating: d.rating,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            BookDetailScreen(bookId: d.bookId),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } else if (state is HomeError) {
              return Center(child: Text(state.message));
            }
            return const SizedBox.shrink();
          },
        ),
        bottomNavigationBar: CustomFooter(
          selectedIndex: 0,
          onItemSelected: (index) {},
        ),
      ),
    );
  }
}
