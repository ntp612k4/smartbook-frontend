import 'package:equatable/equatable.dart';
import '../../../models/categories.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadHomeDataEvent extends HomeEvent {
  final String? userId; // Thêm biến này

  const LoadHomeDataEvent({this.userId});

  @override
  List<Object> get props => [userId ?? ''];
}

class CategorySelectedEvent extends HomeEvent {
  final BookCategory category;

  const CategorySelectedEvent(this.category);

  @override
  List<Object?> get props => [category];
}
