import 'package:equatable/equatable.dart';
import 'package:smart_reader/models/categories.dart';

abstract class CategoryDetailEvent extends Equatable {
  const CategoryDetailEvent();

  @override
  List<Object> get props => [];
}

class LoadCategoryBooksEvent extends CategoryDetailEvent {
  final BookCategory category;

  const LoadCategoryBooksEvent(this.category);

  @override
  List<Object> get props => [category];
}
