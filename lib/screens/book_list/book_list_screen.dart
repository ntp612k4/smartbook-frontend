import 'package:flutter/material.dart';
import 'package:smart_reader/models/book.dart';
import 'package:smart_reader/screens/book_detail/book_detail_screen.dart';
import 'package:smart_reader/theme/app_colors.dart';
import 'package:smart_reader/widgets/list_card.dart';

class BookListScreen extends StatelessWidget {
  final String title;
  final List<Book> books;

  BookListScreen({required this.title, required this.books});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 20,
        leading: IconButton(
          padding: const EdgeInsets.only(left: 12),
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookDetailScreen(bookId: book.bookId),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: ListCard(
                imgUrl: book.imgUrl,
                title: book.title,
                author: book.author.authorName,
                description: book.description,
                // Thêm onTap để chuyển đến màn hình chi tiết sách
              ),
            ),
          );
        },
      ),
    );
  }
}
