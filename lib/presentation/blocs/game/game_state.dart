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

// Modificação para a classe GameLoaded em game_state.dart

// Atualização da classe GameLoaded para incluir a flag de nova palavra disponível
class GameLoaded extends GameState {
  final String targetWord;
  final List<Guess> guesses;
  final bool isCompleted;
  final int bestScore;
  final String dailyWordId;
  final bool hasNewWordAvailable; // Nova flag

  const GameLoaded({
    required this.targetWord,
    required this.guesses,
    required this.isCompleted,
    required this.bestScore,
    required this.dailyWordId,
    this.hasNewWordAvailable = false, // Opcional, com valor padrão falso
  });

  @override
  List<Object?> get props =>
      [
        targetWord,
        guesses,
        isCompleted,
        bestScore,
        dailyWordId,
        hasNewWordAvailable,
      ];

  GameLoaded copyWith({
    String? targetWord,
    List<Guess>? guesses,
    bool? isCompleted,
    int? bestScore,
    String? dailyWordId,
    bool? hasNewWordAvailable,
  }) {
    return GameLoaded(
      targetWord: targetWord ?? this.targetWord,
      guesses: guesses ?? this.guesses,
      isCompleted: isCompleted ?? this.isCompleted,
      bestScore: bestScore ?? this.bestScore,
      dailyWordId: dailyWordId ?? this.dailyWordId,
      hasNewWordAvailable: hasNewWordAvailable ?? this.hasNewWordAvailable,
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
