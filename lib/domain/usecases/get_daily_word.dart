// Arquivo: lib/domain/usecases/get_daily_word.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contextual/core/error/failures.dart';
import 'package:contextual/data/models/game_state.dart';
import 'package:contextual/domain/repositories/game_repository.dart';
import 'package:contextual/domain/repositories/word_repository.dart';
import 'package:contextual/domain/usecases/usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

// Esta classe foi movida para fora da classe GetDailyWord
class GetDailyWordParams extends Equatable {
  final bool forceNewWord;

  const GetDailyWordParams({
    this.forceNewWord = false,
  });

  @override
  List<Object?> get props => [forceNewWord];
}

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
      // Obtém a data atual no formato YYYY-MM-DD
      final today = DateTime.now();
      final currentDateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Primeiro verificamos se já existe um estado de jogo salvo
      if (!params.forceNewWord) {
        final savedGameResult = await _gameRepository.getGameState();

        final savedGame = savedGameResult.fold(
              (failure) => null,
              (gameState) => gameState,
        );

        // Verificar se o jogo salvo existe e se a palavra é do dia atual
        if (savedGame != null) {
          // Verificar se o ID da palavra diária corresponde ao dia atual
          if (savedGame.dailyWordId == currentDateStr) {
            // O jogo está atualizado, podemos usá-lo
            return Right(savedGame);
          } else {
            // A data mudou, precisamos buscar a nova palavra do dia
            print('A data mudou desde o último jogo. Buscando nova palavra do dia...');
            // Continuamos o fluxo para buscar a nova palavra
          }
        }
      }

      // Tentamos buscar a palavra do dia do Firestore
      try {
        final dailyWordDoc = await _firestore.collection('daily_words').doc(currentDateStr).get();

        if (dailyWordDoc.exists && dailyWordDoc.data()!.containsKey('word')) {
          // Palavra encontrada no Firestore, definida pelo Firebase Functions
          final targetWord = dailyWordDoc.data()!['word'] as String;
          print('Nova palavra do dia obtida do Firestore: $targetWord');

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
