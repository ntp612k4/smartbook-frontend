import 'package:equatable/equatable.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadCategoryEvent extends CategoryEvent {
  const LoadCategoryEvent();
}

class LoadCategoriesEvent extends CategoryEvent {
  const LoadCategoriesEvent();
}
