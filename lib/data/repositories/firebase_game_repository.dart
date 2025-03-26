// Arquivo: lib/data/repositories/firebase_game_repository.dart
// Modificar para buscar a palavra do dia do Firestore em vez de gerá-la localmente

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contextual/core/constants/app_constants.dart';
import 'package:contextual/core/error/failures.dart';
import 'package:contextual/data/models/game_state.dart';
import 'package:contextual/domain/entities/guess.dart';
import 'package:contextual/domain/repositories/game_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseGameRepository implements GameRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SharedPreferences _prefs;

  FirebaseGameRepository(this._prefs);

  @override
  Future<Either<Failure, void>> saveGameState(GameStateModel gameState) async {
    try {
      // Salva o estado localmente
      final jsonString = gameState.toRawJson();
      await _prefs.setString(AppConstants.prefsKeyGameState, jsonString);

      // Também salvamos a data do último jogo
      await _prefs.setString(
        AppConstants.prefsKeyLastPlayed,
        DateTime.now().toString().split(' ')[0],
      );

      // Opcionalmente, salva as estatísticas no Firestore
      if (gameState.isCompleted) {
        try {
          await _firestore.collection(AppConstants.userScoresCollection).add({
            'targetWord': gameState.targetWord,
            'attempts': gameState.guesses.length,
            'completed': gameState.isCompleted,
            'timestamp': FieldValue.serverTimestamp(),
            'anonymousUserId': _getAnonymousUserId(),
          });
        } catch (e) {
          // Ignoramos erros ao salvar estatísticas no Firestore
          print('Erro ao salvar estatísticas: $e');
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GameStateModel?>> getGameState() async {
    try {
      final jsonString = _prefs.getString(AppConstants.prefsKeyGameState);
      if (jsonString == null) return const Right(null);

      try {
        final gameState = GameStateModel.fromRawJson(jsonString);
        return Right(gameState);
      } catch (e) {
        // Em caso de erro de parsing, retornamos null para começar um novo jogo
        return const Right(null);
      }
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
        bestScore = await _prefs.getInt(AppConstants.prefsKeyBestScore) ?? 0;
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
      await _prefs.setString(AppConstants.prefsKeyGameState, updatedGameState.toRawJson());

      return Right(updatedGameState);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getBestScore() async {
    try {
      final bestScore = _prefs.getInt(AppConstants.prefsKeyBestScore) ?? 0;
      return Right(bestScore);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateBestScore(int score) async {
    try {
      final currentBest = _prefs.getInt(AppConstants.prefsKeyBestScore) ?? 0;

      // Salvamos apenas se for melhor que o atual
      if (currentBest == 0 || score < currentBest) {
        await _prefs.setInt(AppConstants.prefsKeyBestScore, score);

        // Opcionalmente, salvamos também no Firestore para rastrear o progresso
        try {
          await _firestore.collection('user_records').add({
            'score': score,
            'previousBest': currentBest,
            'timestamp': FieldValue.serverTimestamp(),
            'anonymousUserId': _getAnonymousUserId(),
          });
        } catch (e) {
          // Ignoramos erros ao salvar no Firestore
          print('Erro ao salvar recorde no Firestore: $e');
        }
      }

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
      // Criamos o ID para o dia atual - IMPORTANTE: sempre usar a data atual
      final today = DateTime.now();
      final dailyWordId = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Obtemos a melhor pontuação
      final bestScore = _prefs.getInt(AppConstants.prefsKeyBestScore) ?? 0;

      // ALTERAÇÃO AQUI: Tentamos buscar a palavra do dia do Firestore
      // em vez de usar a palavra passada como parâmetro
      String targetWord = newTargetWord; // Valor padrão

      try {
        final dailyWordDoc = await _firestore.collection('daily_words').doc(dailyWordId).get();

        if (dailyWordDoc.exists && dailyWordDoc.data()!.containsKey('word')) {
          // Usa a palavra definida pelo Firebase Functions
          targetWord = dailyWordDoc.data()!['word'];
          print('Palavra do dia obtida do Firestore: $targetWord');
        } else {
          // Se não encontrou no Firestore, mantém a palavra padrão
          print('Palavra do dia não encontrada no Firestore, usando palavra padrão');
        }
      } catch (e) {
        print('Erro ao buscar palavra do dia do Firestore: $e');
        // Continua usando a palavra padrão em caso de erro
      }

      // Criamos um novo estado de jogo
      final newGameState = GameStateModel(
        targetWord: targetWord,
        guesses: [],
        isCompleted: false,
        bestScore: bestScore,
        dailyWordId: dailyWordId, // Sempre usa o ID do dia atual
        wasShared: false,
      );

      // Salvamos o novo estado
      await _prefs.setString(AppConstants.prefsKeyGameState, newGameState.toRawJson());

      return Right(newGameState);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markGameAsShared() async {
    try {
      final gameStateJson = _prefs.getString(AppConstants.prefsKeyGameState);

      if (gameStateJson == null) {
        return const Left(NotFoundFailure('Estado do jogo não encontrado'));
      }

      final gameState = GameStateModel.fromRawJson(gameStateJson);
      final updatedGameState = gameState.copyWith(wasShared: true);

      await _prefs.setString(AppConstants.prefsKeyGameState, updatedGameState.toRawJson());

      // Registramos o compartilhamento no Firestore para analytics
      try {
        await _firestore.collection('shares').add({
          'targetWord': gameState.targetWord,
          'attempts': gameState.guesses.length,
          'wasCompleted': gameState.isCompleted,
          'timestamp': FieldValue.serverTimestamp(),
          'anonymousUserId': _getAnonymousUserId(),
        });
      } catch (e) {
        // Ignoramos erros ao salvar no Firestore
        print('Erro ao registrar compartilhamento: $e');
      }

      return const Right(null);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  String _getAnonymousUserId() {
    // Usamos um ID salvo localmente para rastrear o mesmo usuário
    // sem identificá-lo pessoalmente
    String? userId = _prefs.getString('anonymous_user_id');

    if (userId == null) {
      // Cria um ID aleatório baseado no timestamp e um número aleatório
      userId = 'anon_${DateTime.now().millisecondsSinceEpoch}_${(Random().nextDouble() * 1000000).toInt()}';
      _prefs.setString('anonymous_user_id', userId);
    }

    return userId;
  }
}
