// Arquivo: lib/domain/usecases/get_daily_word.dart
// Modificar para buscar a palavra do dia do Firestore em vez de gerá-la localmente

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contextual/core/error/failures.dart';
import 'package:contextual/data/models/game_state.dart';
import 'package:contextual/domain/repositories/game_repository.dart';
import 'package:contextual/domain/repositories/word_repository.dart';
import 'package:contextual/domain/usecases/usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class GetDailyWord implements UseCase<GameStateModel, GetDailyWordParams> {
  final WordRepository _wordRepository;
  final GameRepository _gameRepository;
  final FirebaseFirestore _firestore;

  GetDailyWord({
    required WordRepository wordRepository,
    required GameRepository gameRepository,
    FirebaseFirestore? firestore,
  }) : _wordRepository = wordRepository,
        _gameRepository = gameRepository,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Either<Failure, GameStateModel>> call(GetDailyWordParams params) async {
    try {
      // Primeiro verificamos se já existe um estado de jogo salvo
      if (!params.forceNewWord) {
        final savedGameResult = await _gameRepository.getGameState();

        final hasSavedGame = savedGameResult.fold(
              (failure) => false,
              (gameState) => gameState != null,
        );

        if (hasSavedGame) {
          return savedGameResult.fold(
                (failure) => Left(failure),
                (gameState) => Right(gameState!),
          );
        }
      }

      // Obtém a data atual no formato YYYY-MM-DD
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // ALTERAÇÃO: Primeiro tentamos buscar a palavra do dia do Firestore
      try {
        final dailyWordDoc = await _firestore.collection('daily_words').doc(dateStr).get();

        if (dailyWordDoc.exists && dailyWordDoc.data()!.containsKey('word')) {
          // Palavra encontrada no Firestore, definida pelo Firebase Functions
          final targetWord = dailyWordDoc.data()!['word'] as String;

          // Obtemos a pontuação atual do jogador
          final bestScoreResult = await _gameRepository.getBestScore();

          final bestScore = bestScoreResult.fold(
                (failure) => 0,
                (score) => score,
          );

          // Criamos um novo estado de jogo com a palavra obtida
          final gameStateResult = await _gameRepository.resetGame(targetWord);

          return gameStateResult;
        }
      } catch (e) {
        // Log do erro, mas continuamos o fluxo para o fallback local
        print('Erro ao buscar palavra do dia do Firestore: $e');
      }

      // FALLBACK: Se não encontrou no Firestore, usamos o método local
      // (manteremos o código original como fallback)
      final wordResult = await _wordRepository.getDailyWord(forceNewWord: params.forceNewWord);

      return wordResult.fold(
            (failure) => Left(failure),
            (targetWord) async {
          // Obtemos a pontuação atual do jogador
          final bestScoreResult = await _gameRepository.getBestScore();

          final bestScore = bestScoreResult.fold(
                (failure) => 0,
                (score) => score,
          );

          // Criamos um novo estado de jogo com a palavra obtida
          final gameStateResult = await _gameRepository.resetGame(targetWord);

          return gameStateResult;
        },
      );
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}

class GetDailyWordParams extends Equatable {
  final bool forceNewWord;

  const GetDailyWordParams({
    this.forceNewWord = false,
  });

  @override
  List<Object?> get props => [forceNewWord];
}
