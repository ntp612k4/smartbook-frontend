import 'package:equatable/equatable.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

class NextPageEvent extends OnboardingEvent {}

class PreviousPageEvent extends OnboardingEvent {}

class GoToPageEvent extends OnboardingEvent {
  final int pageIndex;

  const GoToPageEvent(this.pageIndex);

  @override
  List<Object?> get props => [pageIndex];
}

class CompleteOnboardingEvent extends OnboardingEvent {}
