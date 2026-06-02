import 'package:equatable/equatable.dart';

abstract class BookDetailEvent extends Equatable {
  const BookDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadBookDetailEvent extends BookDetailEvent {
  final String bookId;

  const LoadBookDetailEvent({required this.bookId});

  @override
  List<Object?> get props => [bookId];
}
