import 'package:equatable/equatable.dart';
import 'package:smart_reader/models/book.dart';
import 'package:smart_reader/models/reivew.dart';

abstract class BookDetailState extends Equatable {
  const BookDetailState();

  @override
  List<Object?> get props => [];
}

class BookDetailInitial extends BookDetailState {}

class BookDetailLoading extends BookDetailState {}

class BookDetailLoaded extends BookDetailState {
  final Book book;
  final List<Review> reviews;

  const BookDetailLoaded({required this.book, this.reviews = const []});

  @override
  List<Object?> get props => [book, reviews];
}

class BookDetailError extends BookDetailState {
  final String message;

  const BookDetailError({required this.message});

  @override
  List<Object?> get props => [message];
}
