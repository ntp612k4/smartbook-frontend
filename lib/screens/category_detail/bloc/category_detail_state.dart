import 'package:equatable/equatable.dart';
import 'package:smart_reader/models/book.dart';
import 'package:smart_reader/models/categories.dart';

abstract class CategoryDetailState extends Equatable {
  const CategoryDetailState();

  @override
  List<Object> get props => [];
}

class CategoryDetailInitial extends CategoryDetailState {}

class CategoryDetailLoading extends CategoryDetailState {}

class CategoryDetailLoaded extends CategoryDetailState {
  final BookCategory category;
  final List<Book> books;

  const CategoryDetailLoaded({required this.category, required this.books});

  @override
  List<Object> get props => [category, books];
}

class CategoryDetailError extends CategoryDetailState {
  final String message;

  const CategoryDetailError(this.message);

  @override
  List<Object> get props => [message];
}
