import 'package:equatable/equatable.dart';
import 'package:quiz/data/models/match_room_model.dart';

abstract class MatchState extends Equatable {
  const MatchState();

  @override
  List<Object?> get props => [];
}

class MatchInitial extends MatchState {}

class MatchLoading extends MatchState {}

class MatchPracticeStarted extends MatchState {
  final String category;
  final String difficulty;
  final int amount;

  MatchPracticeStarted({
    required this.category,
    required this.difficulty,
    required this.amount,
  });

  @override
  List<Object?> get props => [category, difficulty, amount];
}

class MatchLoaded extends MatchState {
  final MatchRoom matchRoom;

  const MatchLoaded(this.matchRoom);

  @override
  List<Object?> get props => [matchRoom];
}

class MatchJoined extends MatchState {
  final MatchRoom matchRoom;

  const MatchJoined(this.matchRoom);

  @override
  List<Object?> get props => [matchRoom];
}

class MatchFinished extends MatchState {
  final MatchRoom matchRoom;

  const MatchFinished(this.matchRoom);

  @override
  List<Object?> get props => [matchRoom];
}

class MatchError extends MatchState {
  final String message;

  const MatchError(this.message);

  @override
  List<Object?> get props => [message];
}

/// ✅ Add this missing state
class MatchSubmitted extends MatchState {
  const MatchSubmitted();
}
