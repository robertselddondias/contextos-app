// Arquivo: lib/data/repositories/firebase_game_repository.dart
// Modificar para buscar a palavra do dia do Firestore em vez de gerá-la localmente

import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contextual/core/constants/app_constants.dart';
import 'package:contextual/core/error/failures.dart';
import 'package:contextual/data/models/game_state.dart';
import 'package:contextual/domain/entities/guess.dart';
import 'package:contextual/domain/repositories/game_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseGameRepository implements GameRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SharedPreferences _prefs;

  FirebaseGameRepository(this._prefs);

  @override
  Future<Either<Failure, void>> saveGameState(GameStateModel gameState) async {
    try {
      // Use o método toJson() antes de codificar
      final jsonString = json.encode(gameState.toJson());

      if (kDebugMode) {
        print('GameRepository: Salvando estado com ${gameState.guesses.length} tentativas');
      }

      await _prefs.setString(AppConstants.prefsKeyGameState, jsonString);
      await _prefs.setString(AppConstants.prefsKeyGameStateDate, gameState.dailyWordId);

      // Restante do código...

      return const Right(null);
    } catch (e) {
      if (kDebugMode) {
        print('GameRepository: Erro ao salvar estado do jogo: $e');
      }
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GameStateModel?>> getGameState() async {
    try {
      // Usa a constante padronizada
      final jsonString = _prefs.getString(AppConstants.prefsKeyGameState);

      if (jsonString == null) {
        if (kDebugMode) {
          print('GameRepository: Nenhum estado de jogo encontrado');
        }
        return const Right(null);
      }

      try {
        Map<String, dynamic> data = json.decode(jsonString);
        final gameState = GameStateModel.fromJson(data);

        // Log para debug
        if (kDebugMode) {
          print('GameRepository: Estado do jogo carregado. Data: ${gameState.dailyWordId}, Palavra: ${gameState.targetWord}');
        }

        return Right(gameState);
      } catch (e) {
        // Em caso de erro de parsing, limpamos o estado corrompido
        if (kDebugMode) {
          print('GameRepository: Erro ao fazer parse do estado do jogo: $e');
        }

        await _prefs.remove(AppConstants.prefsKeyGameState);
        await _prefs.remove(AppConstants.prefsKeyGameStateDate);

        return const Right(null);
      }
    } catch (e) {
      if (kDebugMode) {
        print('GameRepository: Erro ao carregar estado do jogo: $e');
      }
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
      final jsonString = json.encode(updatedGameState.toJson());
      await _prefs.setString(AppConstants.prefsKeyGameState, jsonString);

      return Right(updatedGameState);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getBestScore() async {
    try {
      // Usa a constante padronizada
      final bestScore = _prefs.getInt(AppConstants.prefsKeyBestScore) ?? 0;
      return Right(bestScore);
    } catch (e) {
      if (kDebugMode) {
        print('GameRepository: Erro ao obter melhor pontuação: $e');
      }
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateBestScore(int score) async {
    try {
      // Usa a constante padronizada
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
          if (kDebugMode) {
            print('GameRepository: Erro ao salvar recorde no Firestore: $e');
          }
        }
      }

      return const Right(null);
    } catch (e) {
      if (kDebugMode) {
        print('GameRepository: Erro ao atualizar melhor pontuação: $e');
      }
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

      // Obtém o estado atual salvo
      final savedGameStateJson = _prefs.getString(AppConstants.prefsKeyGameState);
      GameStateModel? savedGameState;

      if (savedGameStateJson != null) {
        final Map<String, dynamic> jsonMap = json.decode(savedGameStateJson) as Map<String, dynamic>;
        savedGameState = GameStateModel.fromJson(jsonMap);
      }

      // Obtemos a melhor pontuação
      final bestScore = _prefs.getInt(AppConstants.prefsKeyBestScore) ?? 0;

      // Tenta obter a palavra do dia do Firestore
      String targetWord = newTargetWord;

      try {
        final dailyWordDoc = await _firestore.collection('daily_words').doc(dailyWordId).get();

        if (dailyWordDoc.exists && dailyWordDoc.data()!.containsKey('word')) {
          targetWord = dailyWordDoc.data()!['word'];
          print('Nova palavra do dia obtida do Firestore: $targetWord');
        }
      } catch (e) {
        print('Erro ao buscar nova palavra do dia: $e');
      }

      // Só cria um novo estado se a palavra for diferente
      if (savedGameState == null || targetWord != savedGameState.targetWord) {
        final newGameState = GameStateModel(
          targetWord: targetWord,
          guesses: [], // Reseta as tentativas somente se palavra mudar
          isCompleted: false,
          bestScore: bestScore,
          dailyWordId: dailyWordId,
          wasShared: false,
        );

        // Salva o novo estado
        await _prefs.setString(AppConstants.prefsKeyGameState, json.encode(newGameState.toJson()));

        return Right(newGameState);
      } else {
        // Mantém o estado atual se a palavra for a mesma
        return Right(savedGameState);
      }
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

      final Map<String, dynamic> jsonMap = json.decode(gameStateJson) as Map<String, dynamic>;
      final gameState = GameStateModel.fromJson(jsonMap);

      final updatedGameState = gameState.copyWith(wasShared: true);

      await _prefs.setString(AppConstants.prefsKeyGameState, json.encode(updatedGameState.toJson()));

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
    String? userId = _prefs.getString(AppConstants.prefsKeyAnonymousUserId);

    if (userId == null) {
      // Cria um ID aleatório baseado no timestamp e um número aleatório
      userId = 'anon_${DateTime.now().millisecondsSinceEpoch}_${(Random().nextDouble() * 1000000).toInt()}';
      _prefs.setString(AppConstants.prefsKeyAnonymousUserId, userId);
    }

    return userId;
  }
}
