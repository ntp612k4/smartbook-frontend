import 'package:equatable/equatable.dart';
import 'package:smart_reader/models/author.dart';
import 'package:smart_reader/models/book.dart';
import 'package:smart_reader/models/categories.dart';
import 'package:smart_reader/models/reading_progess.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<ReadingProgress> readingProgress;
  final List<Book> libraryBooks;
  final List<Author> authors;
  final List<Book> newBooks;
  final List<Book> specialBooks;
  final List<BookCategory> categories;
  final BookCategory? selectedCategory;

  const HomeLoaded({
    required this.readingProgress,
    this.libraryBooks = const [],
    required this.authors,
    required this.newBooks,
    required this.specialBooks,
    required this.categories,
    this.selectedCategory,
  });

  @override
  List<Object?> get props => [
        categories,
        readingProgress,
        authors,
        newBooks,
        specialBooks,
        selectedCategory,
      ];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
