import 'package:equatable/equatable.dart';

abstract class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

class OnboardingPageState extends OnboardingState {
  final int currentPage;
  final int totalPages;
  final bool isLastPage;

  const OnboardingPageState({
    required this.currentPage,
    required this.totalPages,
    required this.isLastPage,
  });

  @override
  List<Object?> get props => [currentPage, totalPages, isLastPage];
}

class OnboardingCompleted extends OnboardingState {}
