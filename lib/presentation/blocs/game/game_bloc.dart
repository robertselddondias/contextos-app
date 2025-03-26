// presentation/blocs/game/game_bloc.dart
import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contextual/core/constants/app_constants.dart';
import 'package:contextual/data/models/game_state.dart';
import 'package:contextual/domain/entities/guess.dart';
import 'package:contextual/domain/usecases/get_daily_word.dart';
import 'package:contextual/domain/usecases/make_guess.dart';
import 'package:contextual/domain/usecases/save_game_state.dart';
import 'package:contextual/services/premium_banner_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'game_event.dart';
part 'game_state.dart';

class _DailyWordListener {
  StreamSubscription? _dailyWordSubscription;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Function(String) onNewDailyWord;

  _DailyWordListener({required this.onNewDailyWord});

  void startListening() {
    // Obtém a data atual no formato YYYY-MM-DD
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    _dailyWordSubscription = _firestore
        .collection('daily_words')
        .doc(dateStr)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data()!.containsKey('word')) {
        final newWord = snapshot.data()!['word'] as String;
        onNewDailyWord(newWord);
      }
    }, onError: (error) {
      print('Erro no listener de palavra diária: $error');
    });
  }

  void dispose() {
    _dailyWordSubscription?.cancel();
  }
}

class GameBloc extends Bloc<GameEvent, GameState> {
  final GetDailyWord getDailyWord;
  final MakeGuess makeGuess;
  final SaveGameState saveGameState;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  _DailyWordListener? _dailyWordListener;

  GameBloc({
    required this.getDailyWord,
    required this.makeGuess,
    required this.saveGameState,
  }) : super(const GameInitial()) {
    on<GameInitialized>(_onGameInitialized);
    on<GuessSubmitted>(_onGuessSubmitted);
    on<GameReset>(_onGameReset);
    on<GameShared>(_onGameShared);
    on<GameRefreshDaily>(_onGameRefreshDaily);

    _setupDailyWordListener();
  }

  @override
  Future<void> close() {
    _dailyWordListener?.dispose();
    return super.close();
  }

  void _setupDailyWordListener() {
    _dailyWordListener = _DailyWordListener(
      onNewDailyWord: (newWord) {
        // Quando uma nova palavra for detectada, reinicie o jogo
        add(const GameReset());
      },
    );
    _dailyWordListener?.startListening();
  }

  // Método para verificar e atualizar a palavra do dia
  Future<void> _onGameRefreshDaily(
      GameRefreshDaily event,
      Emitter<GameState> emit,
      ) async {
    if (state is GameLoaded) {
      final currentState = state as GameLoaded;

      // Obtém a data atual
      final today = DateTime.now();
      final currentDateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Verifica se o jogo atual é de uma data diferente
      if (currentState.dailyWordId != currentDateStr) {
        emit(const GameLoading());

        try {
          // Buscar nova palavra do dia
          final result = await _fetchNewDailyWord();

          if (result != null) {
            // Salvar o novo estado de jogo nas preferências
            await _saveGameStateToPrefs(result);

            emit(GameLoaded(
              targetWord: result.targetWord,
              guesses: result.guesses,
              isCompleted: result.isCompleted,
              bestScore: result.bestScore,
              dailyWordId: result.dailyWordId,
            ));
          } else {
            // Emite o estado original se algo der errado
            emit(currentState);
          }
        } catch (e) {
          if (kDebugMode) {
            print('Erro ao atualizar palavra do dia: $e');
          }
          emit(GameError(
            message: "Erro ao atualizar palavra do dia: ${e.toString()}",
            previousState: currentState,
          ));
          emit(currentState);
        }
      }
    } else {
      // Se não estiver carregado, inicializa normalmente
      add(const GameInitialized());
    }
  }

  // Método auxiliar para salvar o estado do jogo nas preferências
  Future<void> _saveGameStateToPrefs(GameStateModel gameState) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('game_state', gameState.toRawJson());
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao salvar estado do jogo: $e');
      }
    }
  }

  // Método auxiliar para buscar nova palavra do dia
  Future<GameStateModel?> _fetchNewDailyWord() async {
    try {
      // Obter a data atual
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // 1. Tente obter a palavra do dia do Firestore
      final docSnapshot = await _firestore.collection('daily_words').doc(dateStr).get();
      String? targetWord;

      if (docSnapshot.exists && docSnapshot.data()!.containsKey('word')) {
        targetWord = docSnapshot.data()?['word'] as String;
        if (kDebugMode) {
          print('Nova palavra do dia obtida do Firestore: $targetWord');
        }
      }

      // 2. Se não encontrou no Firestore, use um método alternativo para obter uma palavra
      if (targetWord == null) {
        // Fallback para obter palavras aleatórias
        targetWord = await _getRandomWord();

        if (kDebugMode) {
          print('Palavra não encontrada no Firestore, usando palavra aleatória: $targetWord');
        }
      }

      if (targetWord != null) {
        // Obter melhor pontuação
        final bestScore = await _getBestScore();

        // Criar novo estado de jogo
        return GameStateModel(
          targetWord: targetWord,
          guesses: [],
          isCompleted: false,
          bestScore: bestScore,
          dailyWordId: dateStr,
          wasShared: false,
        );
      }

      throw Exception('Não foi possível obter uma palavra válida');
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao obter nova palavra do dia: $e');
      }
      return null;
    }
  }

  // Método para obter uma palavra aleatória (fallback)
  Future<String> _getRandomWord() async {
    try {
      // Tenta obter uma coleção de palavras do Firestore
      final snapshot = await _firestore.collection('words').limit(50).get();

      if (snapshot.docs.isNotEmpty) {
        // Escolhe uma palavra aleatória da coleção
        final random = DateTime.now().millisecondsSinceEpoch % snapshot.docs.length;
        return snapshot.docs[random].id;
      }

      // Se não conseguir obter do Firestore, retorna uma palavra padrão
      return 'palavra';
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao obter palavra aleatória: $e');
      }
      return 'palavra';
    }
  }

  // Método auxiliar para obter a melhor pontuação
  Future<int> _getBestScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('best_score') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Método público para verificar se a palavra do dia precisa ser atualizada
  void checkDailyWordUpdate() {
    add(const GameRefreshDaily());
  }

  Future<void> _onGameInitialized(
      GameInitialized event,
      Emitter<GameState> emit,
      ) async {
    emit(const GameLoading());

    try {
      // Verifica se existe um estado de jogo salvo
      final savedGameStateJson = _prefs.getString(AppConstants.prefsKeyGameState);

      if (savedGameStateJson == null) {
        // Se não há estado salvo, busca uma nova palavra
        final newGameState = await _fetchNewDailyWord();

        if (newGameState != null) {
          await _saveGameStateToPrefs(newGameState);
          emit(GameLoaded(
            targetWord: newGameState.targetWord,
            guesses: newGameState.guesses,
            isCompleted: newGameState.isCompleted,
            bestScore: newGameState.bestScore,
            dailyWordId: newGameState.dailyWordId,
          ));
          return;
        }
      }

      // Carrega o estado salvo
      final savedGameState = GameStateModel.fromRawJson(savedGameStateJson!);

      // Obtém a data atual
      final today = DateTime.now();
      final currentDateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Verifica se a palavra do dia mudou no Firestore
      try {
        final dailyWordDoc = await _firestore.collection('daily_words').doc(currentDateStr).get();

        if (dailyWordDoc.exists && dailyWordDoc.data()!.containsKey('word')) {
          final firestoreWord = dailyWordDoc.data()!['word'] as String;

          // SÓ reseta se a palavra for diferente
          if (firestoreWord != savedGameState.targetWord) {
            final newGameState = await _fetchNewDailyWord();

            if (newGameState != null) {
              await _saveGameStateToPrefs(newGameState);
              emit(GameLoaded(
                targetWord: newGameState.targetWord,
                guesses: newGameState.guesses,
                isCompleted: newGameState.isCompleted,
                bestScore: newGameState.bestScore,
                dailyWordId: newGameState.dailyWordId,
              ));
              return;
            }
          }
        }
      } catch (e) {
        print('Erro ao verificar palavra do dia: $e');
      }

      // Se não houve necessidade de resetar, carrega o estado salvo
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

  // Carrega o estado do jogo salvo nas preferências
  Future<GameStateModel?> _loadSavedGameState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gameStateJson = prefs.getString('game_state');

      if (gameStateJson != null) {
        return GameStateModel.fromRawJson(gameStateJson);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar estado do jogo: $e');
      }
      return null;
    }
  }

  // Processa uma tentativa de adivinhação
  Future<void> _onGuessSubmitted(
      GuessSubmitted event,
      Emitter<GameState> emit,
      ) async {
    if (state is! GameLoaded) return;

    final currentState = state as GameLoaded;
    if (currentState.isCompleted) return;

    // Verificar se a palavra já foi adivinhada
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

    emit(GameLoading(
      previousState: currentState,
    ));

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
          if (gameState.isCompleted && !currentState.isCompleted) {
            // Notifica o serviço de banner que o jogo foi completado
            PremiumBannerService().trackGameSession(gameCompleted: true);
          }
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

  Future<void> _onGameReset(
      GameReset event,
      Emitter<GameState> emit,
      ) async {
    emit(const GameLoading());

    try {
      // Obtém o estado atual antes de tentar resetar
      final currentState = state is GameLoaded
          ? (state as GameLoaded)
          : null;

      // Busca nova palavra do dia
      final newGameState = await _fetchNewDailyWord();

      if (newGameState != null) {
        // Se a nova palavra for diferente da atual, reseta
        if (currentState == null ||
            newGameState.targetWord != currentState.targetWord) {

          await _saveGameStateToPrefs(newGameState);

          emit(GameLoaded(
            targetWord: newGameState.targetWord,
            guesses: [], // IMPORTANTE: Mantém histórico se for o mesmo dia
            isCompleted: newGameState.isCompleted,
            bestScore: newGameState.bestScore,
            dailyWordId: newGameState.dailyWordId,
          ));
        } else {
          // Se for a mesma palavra, mantém o estado atual
          emit(currentState);
        }
      } else {
        emit(const GameError(message: 'Não foi possível reiniciar o jogo'));
      }
    } catch (e) {
      emit(GameError(message: e.toString()));
    }
  }

  Future<bool> _hasNewDailyWord(String currentDailyWordId) async {
    try {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Se o IDs já são diferentes, definitivamente há uma nova palavra
      if (currentDailyWordId != dateStr) return true;

      // Consulta o Firestore para ver se a palavra do dia mudou
      final dailyWordDoc = await _firestore.collection('daily_words').doc(dateStr).get();

      if (dailyWordDoc.exists && dailyWordDoc.data()!.containsKey('word')) {
        final firestoreWord = dailyWordDoc.data()!['word'] as String;

        // Compara a palavra do Firestore com a palavra atual
        return firestoreWord != currentDailyWordId;
      }

      return false;
    } catch (e) {
      print('Erro ao verificar nova palavra do dia: $e');
      return false;
    }
  }

  // Marca o jogo como compartilhado
  Future<void> _onGameShared(
      GameShared event,
      Emitter<GameState> emit,
      ) async {
    if (state is! GameLoaded) return;

    try {
      await saveGameState(const SaveGameStateParams(
        wasShared: true,
      ));
    } catch (e) {
      // Ignoramos erros ao salvar o estado de compartilhamento,
      // pois isso não é crítico para o funcionamento do jogo
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

    // Adicionamos as últimas 5 tentativas (ou todas se houver menos de 5)
    final startIndex = currentState.guesses.length > 5 ? currentState.guesses.length - 5 : 0;
    for (int i = startIndex; i < currentState.guesses.length; i++) {
      final guess = currentState.guesses[i];
      shareText += '${i + 1}. ${guess.word} (${(guess.similarity * 100).toStringAsFixed(0)}%)\n';
    }

    if(Platform.isIOS) {
      shareText += '\nJogue em: https://apps.apple.com/br/app/contextual/id6743683117';
    }

    return shareText;
  }
}
