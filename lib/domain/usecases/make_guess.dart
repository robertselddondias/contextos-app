// domain/usecases/make_guess.dart
import 'package:contextual/core/error/failures.dart';
import 'package:contextual/data/models/game_state.dart';
import 'package:contextual/domain/entities/guess.dart';
import 'package:contextual/domain/repositories/game_repository.dart';
import 'package:contextual/domain/usecases/calculate_similarity.dart';
import 'package:contextual/domain/usecases/usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class MakeGuess implements UseCase<GameStateModel, MakeGuessParams> {
  final GameRepository _gameRepository;
  final CalculateSimilarity _calculateSimilarity;

  MakeGuess({
    required GameRepository gameRepository,
    required CalculateSimilarity calculateSimilarity,
  }) : _gameRepository = gameRepository,
        _calculateSimilarity = calculateSimilarity;

  @override
  Future<Either<Failure, GameStateModel>> call(MakeGuessParams params) async {
    try {
      // Verificamos se a palavra já foi tentada
      final isRepeated = params.previousGuesses.any(
              (g) => g.word.toLowerCase() == params.guess.toLowerCase()
      );

      if (isRepeated) {
        return Left(InvalidInputFailure('Essa palavra já foi tentada'));
      }

      // Calculamos a similaridade com a palavra-alvo
      final similarityResult = await _calculateSimilarity(
        CalculateSimilarityParams(
          word1: params.guess,
          word2: params.targetWord,
        ),
      );

      return similarityResult.fold(
            (failure) => Left(failure),
            (similarity) => _gameRepository.addGuess(
          params.guess,
          similarity,
          GameStateModel(
            targetWord: params.targetWord,
            guesses: params.previousGuesses,
            isCompleted: _gameRepository.isGameCompleted(
              params.previousGuesses,
              params.targetWord,
            ),
            bestScore: params.bestScore ?? 0,
            dailyWordId: params.dailyWordId ?? '',
            wasShared: params.wasShared ?? false,
          ),
        ),
      );
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}

class MakeGuessParams extends Equatable {
  final String guess;
  final String targetWord;
  final List<Guess> previousGuesses;
  final int? bestScore;
  final String? dailyWordId;
  final bool? wasShared;

  const MakeGuessParams({
    required this.guess,
    required this.targetWord,
    required this.previousGuesses,
    this.bestScore,
    this.dailyWordId,
    this.wasShared,
  });

  @override
  List<Object?> get props => [
    guess,
    targetWord,
    previousGuesses,
    bestScore,
    dailyWordId,
    wasShared,
  ];
}
