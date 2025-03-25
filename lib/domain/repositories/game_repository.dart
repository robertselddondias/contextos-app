// domain/repositories/game_repository.dart
import 'package:contextual/core/error/failures.dart';
import 'package:contextual/data/models/game_state.dart';
import 'package:contextual/domain/entities/guess.dart';
import 'package:dartz/dartz.dart';

abstract class GameRepository {
  /// Salva o estado atual do jogo
  Future<Either<Failure, void>> saveGameState(GameStateModel gameState);

  /// Carrega o estado do jogo salvo
  Future<Either<Failure, GameStateModel?>> getGameState();

  /// Adiciona uma nova tentativa ao jogo
  Future<Either<Failure, GameStateModel>> addGuess(
      String guess,
      double similarity,
      GameStateModel currentState,
      );

  /// Obtém a melhor pontuação do jogador
  Future<Either<Failure, int>> getBestScore();

  /// Atualiza a melhor pontuação do jogador
  Future<Either<Failure, void>> updateBestScore(int score);

  /// Verifica se o jogo está completo
  bool isGameCompleted(List<Guess> guesses, String targetWord);

  /// Reinicia o jogo com uma nova palavra
  Future<Either<Failure, GameStateModel>> resetGame(String newTargetWord);

  /// Marca o jogo como compartilhado
  Future<Either<Failure, void>> markGameAsShared();
}
