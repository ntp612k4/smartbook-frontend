import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadUserProfileEvent extends ProfileEvent {}

class UpdateReadingStatsEvent extends ProfileEvent {
  final int booksRead;
  final int dayStreak;
  final int timeRead;

  UpdateReadingStatsEvent({
    required this.booksRead,
    required this.dayStreak,
    required this.timeRead,
  });

  @override
  List<Object?> get props => [booksRead, dayStreak, timeRead];
}

class UpdateUserInfoEvent extends ProfileEvent {
  final String? displayName;
  final String? photoURL;

  UpdateUserInfoEvent({this.displayName, this.photoURL});

  @override
  List<Object?> get props => [displayName, photoURL];
}

class LogoutUserEvent extends ProfileEvent {}
