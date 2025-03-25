// data/repositories/game_repository_impl.dart
import 'package:contextual/core/constants/app_constants.dart';
import 'package:contextual/core/error/failures.dart';
import 'package:contextual/data/datasources/local/shared_prefs_manager.dart';
import 'package:contextual/data/models/game_state.dart';
import 'package:contextual/domain/entities/guess.dart';
import 'package:contextual/domain/repositories/game_repository.dart';
import 'package:dartz/dartz.dart';

class GameRepositoryImpl implements GameRepository {
  final SharedPrefsManager _localDataSource;

  GameRepositoryImpl({
    required SharedPrefsManager localDataSource,
  }) : _localDataSource = localDataSource;

  @override
  Future<Either<Failure, void>> saveGameState(GameStateModel gameState) async {
    try {
      await _localDataSource.saveGameState(gameState);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GameStateModel?>> getGameState() async {
    try {
      final gameState = await _localDataSource.getGameState();
      return Right(gameState);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GameStateModel>> addGuess(
      String guess,
      double similarity,
      GameStateModel currentState,
      ) async {
    try {
      // Criamos a nova tentativa
      final newGuess = Guess(
        word: guess,
        similarity: similarity,
        timestamp: DateTime.now(),
      );

      // Adicionamos à lista de tentativas
      final updatedGuesses = [...currentState.guesses, newGuess];

      // Verificamos se o jogo foi completado
      final isCompleted = isGameCompleted(updatedGuesses, currentState.targetWord);

      // Atualizamos a melhor pontuação se o jogo foi completado
      int bestScore = currentState.bestScore;
      if (isCompleted) {
        await updateBestScore(updatedGuesses.length);
        bestScore = await _localDataSource.getBestScore();
      }

      // Criamos o novo estado do jogo
      final updatedGameState = GameStateModel(
        targetWord: currentState.targetWord,
        guesses: updatedGuesses,
        isCompleted: isCompleted,
        bestScore: bestScore,
        dailyWordId: currentState.dailyWordId,
        wasShared: currentState.wasShared,
      );

      // Salvamos o estado atualizado
      await _localDataSource.saveGameState(updatedGameState);

      return Right(updatedGameState);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getBestScore() async {
    try {
      final bestScore = await _localDataSource.getBestScore();
      return Right(bestScore);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateBestScore(int score) async {
    try {
      await _localDataSource.saveBestScore(score);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  bool isGameCompleted(List<Guess> guesses, String targetWord) {
    // Verifica se alguma das tentativas corresponde à palavra-alvo
    return guesses.any((guess) =>
    guess.word.toLowerCase() == targetWord.toLowerCase() ||
        guess.similarity >= AppConstants.winThreshold
    );
  }

  @override
  Future<Either<Failure, GameStateModel>> resetGame(String newTargetWord) async {
    try {
      // Criamos o ID para o dia atual
      final today = DateTime.now();
      final dailyWordId = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Obtemos a melhor pontuação
      final bestScore = await _localDataSource.getBestScore();

      // Criamos um novo estado do jogo
      final newGameState = GameStateModel(
        targetWord: newTargetWord,
        guesses: [],
        isCompleted: false,
        bestScore: bestScore,
        dailyWordId: dailyWordId,
        wasShared: false,
      );

      // Salvamos o novo estado
      await _localDataSource.saveGameState(newGameState);

      return Right(newGameState);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markGameAsShared() async {
    try {
      final gameStateResult = await getGameState();

      return gameStateResult.fold(
            (failure) => Left(failure),
            (gameState) async {
          if (gameState == null) {
            return const Left(NotFoundFailure('Estado do jogo não encontrado'));
          }

          final updatedGameState = gameState.copyWith(wasShared: true);

          await _localDataSource.saveGameState(updatedGameState);

          return const Right(null);
        },
      );
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
