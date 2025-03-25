// part of 'game_bloc.dart'
part of 'game_bloc.dart';

abstract class GameState extends Equatable {
  const GameState();

  @override
  List<Object?> get props => [];
}

class GameInitial extends GameState {
  const GameInitial();
}

class GameLoading extends GameState {
  final GameState? previousState;

  const GameLoading({this.previousState});

  @override
  List<Object?> get props => [previousState];
}

class GameLoaded extends GameState {
  final String targetWord;
  final List<Guess> guesses;
  final bool isCompleted;
  final int bestScore;
  final String dailyWordId;

  const GameLoaded({
    required this.targetWord,
    required this.guesses,
    required this.isCompleted,
    required this.bestScore,
    required this.dailyWordId,
  });

  @override
  List<Object?> get props => [
    targetWord,
    guesses,
    isCompleted,
    bestScore,
    dailyWordId,
  ];

  GameLoaded copyWith({
    String? targetWord,
    List<Guess>? guesses,
    bool? isCompleted,
    int? bestScore,
    String? dailyWordId,
  }) {
    return GameLoaded(
      targetWord: targetWord ?? this.targetWord,
      guesses: guesses ?? this.guesses,
      isCompleted: isCompleted ?? this.isCompleted,
      bestScore: bestScore ?? this.bestScore,
      dailyWordId: dailyWordId ?? this.dailyWordId,
    );
  }
}

class GameError extends GameState {
  final String message;
  final GameState? previousState;

  const GameError({
    required this.message,
    this.previousState,
  });

  @override
  List<Object?> get props => [message, previousState];
}
