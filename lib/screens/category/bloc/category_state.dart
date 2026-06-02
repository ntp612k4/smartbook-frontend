import 'package:equatable/equatable.dart';
import 'package:smart_reader/models/book.dart';
import 'package:smart_reader/models/categories.dart';

// Removed abstract class CategoryState to avoid naming conflict.

class CategoryWithBooks {
  final BookCategory category;
  final List<Book> books;

  CategoryWithBooks({required this.category, required this.books});
}

class CategoryState extends Equatable {
  final bool isLoading;
  final List<CategoryWithBooks> categories;
  final String? error;

  const CategoryState({
    this.isLoading = false,
    this.categories = const [],
    this.error,
  });

  CategoryState copyWith({
    bool? isLoading,
    List<CategoryWithBooks>? categories,
    String? error,
  }) {
    return CategoryState(
      isLoading: isLoading ?? this.isLoading,
      categories: categories ?? this.categories,
      error: error,
    );
  }

  @override
  List<Object?> get props => [isLoading, categories, error];
}
