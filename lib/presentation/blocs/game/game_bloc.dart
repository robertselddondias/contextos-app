// presentation/blocs/game/game_bloc.dart
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contextual/core/constants/app_constants.dart';
import 'package:contextual/data/models/game_state.dart';
import 'package:contextual/domain/entities/guess.dart';
import 'package:contextual/domain/repositories/game_repository.dart';
import 'package:contextual/domain/repositories/word_repository.dart';
import 'package:contextual/domain/usecases/get_daily_word.dart';
import 'package:contextual/domain/usecases/make_guess.dart';
import 'package:contextual/domain/usecases/save_game_state.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'game_event.dart';
part 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  final GetDailyWord getDailyWord;
  final MakeGuess makeGuess;
  final SaveGameState saveGameState;
  final WordRepository _wordRepository;
  final GameRepository _gameRepository;
  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;

  StreamSubscription? _dailyWordSubscription;

  GameBloc({
    required this.getDailyWord,
    required this.makeGuess,
    required this.saveGameState,
    required WordRepository wordRepository,
    required GameRepository gameRepository,
    FirebaseFirestore? firestore,
    SharedPreferences? prefs,
  })  : _wordRepository = wordRepository,
        _gameRepository = gameRepository,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _prefs = prefs ?? (throw ArgumentError('SharedPreferences must be provided')),
        super(const GameInitial()) {
    on<GameInitialized>(_onGameInitialized);
    on<GuessSubmitted>(_onGuessSubmitted);
    on<GameReset>(_onGameReset);
    on<GameShared>(_onGameShared);
    on<GameRefreshDaily>(_onGameRefreshDaily);

    // Configura o listener de palavra diária
    _setupDailyWordListener();
  }

  // Configura listener para mudanças na palavra diária
  void _setupDailyWordListener() {
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Cancela listener anterior
    _dailyWordSubscription?.cancel();

    _dailyWordSubscription = _firestore
        .collection('daily_words')
        .doc(dateStr)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data()!.containsKey('word')) {
        final firestoreWord = snapshot.data()!['word'] as String;

        // Verifica se o estado atual é GameLoaded
        if (state is GameLoaded) {
          final currentState = state as GameLoaded;

          // Só reseta se a palavra for COMPLETAMENTE diferente
          if (firestoreWord.toLowerCase() != currentState.targetWord.toLowerCase()) {
            print('Nova palavra detectada no Firestore: $firestoreWord');

            add(const GameReset(preserveGuesses: true));
          }
        }
      }
    }, onError: (error) {
      print('Erro no listener de palavra diária: $error');
    });
  }

  // Inicialização do jogo
  Future<void> _onGameInitialized(
      GameInitialized event,
      Emitter<GameState> emit,
      ) async {
    emit(const GameLoading());

    try {
      // Tenta carregar estado salvo
      final savedGameStateJson = _prefs.getString(AppConstants.prefsKeyGameState);

      if (savedGameStateJson == null) {
        // Se não há estado salvo, busca uma nova palavra
        final newGameState = await _fetchNewDailyWord();

        if (newGameState != null) {
          await _saveGameStateToPrefs(newGameState);
          emit(GameLoaded(
            targetWord: newGameState.targetWord,
            guesses: [],
            isCompleted: false,
            bestScore: newGameState.bestScore,
            dailyWordId: newGameState.dailyWordId,
          ));
          return;
        }
      }

      // Carrega estado salvo
      final savedGameState = GameStateModel.fromRawJson(savedGameStateJson!);

      // Verifica palavra atual no Firestore
      final today = DateTime.now();
      final currentDateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      try {
        final dailyWordDoc = await _firestore.collection('daily_words').doc(currentDateStr).get();

        if (dailyWordDoc.exists && dailyWordDoc.data()!.containsKey('word')) {
          final firestoreWord = dailyWordDoc.data()!['word'] as String;

          // Só reseta se a palavra for completamente diferente
          if (firestoreWord.toLowerCase() != savedGameState.targetWord.toLowerCase()) {
            final newGameState = await _fetchNewDailyWord();

            if (newGameState != null) {
              await _saveGameStateToPrefs(newGameState);
              emit(GameLoaded(
                targetWord: newGameState.targetWord,
                guesses: savedGameState.guesses, // PRESERVA histórico de tentativas
                isCompleted: false,
                bestScore: savedGameState.bestScore,
                dailyWordId: newGameState.dailyWordId,
              ));
              return;
            }
          }
        }
      } catch (e) {
        print('Erro ao verificar palavra do dia: $e');
      }

      // Se não houve mudança, emite o estado salvo
      emit(GameLoaded(
        targetWord: savedGameState.targetWord,
        guesses: savedGameState.guesses,
        isCompleted: savedGameState.isCompleted,
        bestScore: savedGameState.bestScore,
        dailyWordId: savedGameState.dailyWordId,
      ));
    } catch (e) {
      emit(GameError(message: e.toString()));
    }
  }

  // Submissão de tentativa
  Future<void> _onGuessSubmitted(
      GuessSubmitted event,
      Emitter<GameState> emit,
      ) async {
    if (state is! GameLoaded) return;

    final currentState = state as GameLoaded;
    if (currentState.isCompleted) return;

    // Verifica se a palavra já foi tentada
    if (currentState.guesses.any(
            (g) => g.word.toLowerCase() == event.guess.toLowerCase()
    )) {
      emit(GameError(
        message: 'Essa palavra já foi tentada',
        previousState: currentState,
      ));
      emit(currentState);
      return;
    }

    emit(GameLoading(previousState: currentState));

    try {
      final result = await makeGuess(MakeGuessParams(
        guess: event.guess,
        targetWord: currentState.targetWord,
        previousGuesses: currentState.guesses,
      ));

      result.fold(
            (failure) {
          emit(GameError(
            message: failure.message,
            previousState: currentState,
          ));
          emit(currentState);
        },
            (gameState) {
          // Salva o novo estado
          _saveGameStateToPrefs(gameState);

          emit(GameLoaded(
            targetWord: gameState.targetWord,
            guesses: gameState.guesses,
            isCompleted: gameState.isCompleted,
            bestScore: gameState.bestScore,
            dailyWordId: gameState.dailyWordId,
          ));
        },
      );
    } catch (e) {
      emit(GameError(
        message: e.toString(),
        previousState: currentState,
      ));
      emit(currentState);
    }
  }

  // Reset do jogo
  Future<void> _onGameReset(
      GameReset event,
      Emitter<GameState> emit,
      ) async {
    emit(const GameLoading());

    try {
      // Obtém o estado atual
      final currentState = state is GameLoaded
          ? (state as GameLoaded)
          : null;

      // Obtém nova palavra do dia
      final newGameState = await _fetchNewDailyWord();

      if (newGameState != null) {
        // Preserva tentativas se solicitado
        final guessesToKeep = event.preserveGuesses && currentState != null
            ? currentState.guesses
            : <Guess>[];

        await _saveGameStateToPrefs(newGameState.copyWith(guesses: guessesToKeep));

        emit(GameLoaded(
          targetWord: newGameState.targetWord,
          guesses: guessesToKeep,
          isCompleted: false,
          bestScore: newGameState.bestScore,
          dailyWordId: newGameState.dailyWordId,
        ));
      } else {
        emit(const GameError(message: 'Não foi possível reiniciar o jogo'));
      }
    } catch (e) {
      emit(GameError(message: e.toString()));
    }
  }

  // Marca o jogo como compartilhado
  Future<void> _onGameShared(
      GameShared event,
      Emitter<GameState> emit,
      ) async {
    if (state is! GameLoaded) return;

    try {
      await saveGameState(const SaveGameStateParams(wasShared: true));
    } catch (e) {
      // Ignora erros de salvamento
      print('Erro ao marcar jogo como compartilhado: $e');
    }
  }

  // Atualização diária
  Future<void> _onGameRefreshDaily(
      GameRefreshDaily event,
      Emitter<GameState> emit,
      ) async {
    if (state is! GameLoaded) return;

    final currentState = state as GameLoaded;

    // Obtém a data atual
    final today = DateTime.now();
    final currentDateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Verifica se o jogo atual é de uma data diferente
    if (currentState.dailyWordId != currentDateStr) {
      add(const GameReset());
    }
  }

  // Busca nova palavra do dia
  Future<GameStateModel?> _fetchNewDailyWord() async {
    try {
      // Obtém a data atual
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // 1. Tenta obter a palavra do dia do Firestore
      final docSnapshot = await _firestore.collection('daily_words').doc(dateStr).get();
      String? targetWord;

      if (docSnapshot.exists && docSnapshot.data()!.containsKey('word')) {
        targetWord = docSnapshot.data()?['word'] as String;
        if (kDebugMode) {
          print('Nova palavra do dia obtida do Firestore: $targetWord');
        }
      }

      // 2. Se não encontrou no Firestore, usa método alternativo
      if (targetWord == null) {
        final wordResult = await _wordRepository.getDailyWord();
        targetWord = wordResult.fold(
                (failure) => null,
                (word) => word
        );
      }

      if (targetWord != null) {
        // Obtém melhor pontuação
        final bestScore = await _gameRepository.getBestScore();

        // Cria novo estado de jogo
        return GameStateModel(
          targetWord: targetWord,
          guesses: [],
          isCompleted: false,
          bestScore: bestScore.fold((l) => 0, (score) => score),
          dailyWordId: dateStr,
          wasShared: false,
        );
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao obter nova palavra do dia: $e');
      }
      return null;
    }
  }

  // Salva o estado do jogo nas preferências
  Future<void> _saveGameStateToPrefs(GameStateModel gameState) async {
    try {
      await _prefs.setString(AppConstants.prefsKeyGameState, gameState.toRawJson());
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao salvar estado do jogo: $e');
      }
    }
  }

  // Gera texto para compartilhamento
  String generateShareText() {
    if (state is! GameLoaded) return '';

    final currentState = state as GameLoaded;
    final today = DateTime.now();
    final dayNumber = today.difference(DateTime(2023, 1, 1)).inDays;

    String shareText = 'Contextual #$dayNumber\n';

    if (currentState.isCompleted) {
      shareText += 'Encontrei a palavra ${currentState.targetWord.toUpperCase()} em ${currentState.guesses.length} tentativas!\n\n';
    } else {
      shareText += 'Ainda estou tentando...\n\n';
    }

    // Adiciona as últimas 5 tentativas
    final startIndex = currentState.guesses.length > 5
        ? currentState.guesses.length - 5
        : 0;

    for (int i = startIndex; i < currentState.guesses.length; i++) {
      final guess = currentState.guesses[i];
      shareText += '${i + 1}. ${guess.word} (${(guess.similarity * 100).toStringAsFixed(0)}%)\n';
    }

    return shareText;
  }

  // Fecha o bloc e cancela listeners
  @override
  Future<void> close() {
    _dailyWordSubscription?.cancel();
    return super.close();
  }
}
