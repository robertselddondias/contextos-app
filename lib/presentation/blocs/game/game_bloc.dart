// presentation/blocs/game/game_bloc.dart (modificado para usar DailyWordListenerService)
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contextual/core/constants/app_constants.dart';
import 'package:contextual/data/datasources/remote/firebase_context_service.dart';
import 'package:contextual/data/models/game_state.dart';
import 'package:contextual/domain/entities/guess.dart';
import 'package:contextual/domain/repositories/game_repository.dart';
import 'package:contextual/domain/repositories/word_repository.dart';
import 'package:contextual/domain/usecases/get_daily_word.dart';
import 'package:contextual/domain/usecases/make_guess.dart';
import 'package:contextual/domain/usecases/save_game_state.dart';
import 'package:contextual/services/daily_word_listener_service.dart';
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

  // Daily word listener service
  final DailyWordListenerService _dailyWordListener = DailyWordListenerService();

  // Subscriptions
  StreamSubscription? _dailyWordSubscription;
  StreamSubscription? _wordUpdateSubscription;

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
    on<DailyWordChanged>(_onDailyWordChanged);
    on<ClearNewWordDialogFlag>(_onClearNewWordDialogFlag);

    // Initialize the daily word listener
    _initializeDailyWordListener();
  }

  Future<void> _onClearNewWordDialogFlag(
      ClearNewWordDialogFlag event,
      Emitter<GameState> emit,
      ) async {
    // Verifica se o estado atual é GameLoaded
    if (state is GameLoaded) {
      final currentState = state as GameLoaded;

      // Só emite um novo estado se a flag estiver ativa
      if (currentState.hasNewWordAvailable) {
        // Emite o mesmo estado, mas com a flag desativada
        emit(currentState.copyWith(
          hasNewWordAvailable: false,
        ));

        if (kDebugMode) {
          print('GameBloc: Cleared new word dialog flag');
        }
      }
    }
  }

  // Initialize the listener for daily word changes
  Future<void> _initializeDailyWordListener() async {
    try {
      // Initialize the service
      await _dailyWordListener.initialize();

      // Listen for daily word updates
      _wordUpdateSubscription = _dailyWordListener.dailyWordUpdates.listen((newWord) {
        // When a new word is received, trigger an event to update the game
        add(DailyWordChanged(newWord));
      });

      if (kDebugMode) {
        print('GameBloc: Daily word listener initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('GameBloc: Error initializing daily word listener: $e');
      }
    }
  }

  // Configura listener para mudanças na palavra diária (método legado)
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
            if (kDebugMode) {
              print('Nova palavra detectada no Firestore: $firestoreWord');
            }

            // Use the new event to handle the change
            add(DailyWordChanged(firestoreWord));
          }
        }
      }
    }, onError: (error) {
      if (kDebugMode) {
        print('Erro no listener de palavra diária: $error');
      }
    });
  }

  Future<void> _onDailyWordChanged(
      DailyWordChanged event,
      Emitter<GameState> emit
      ) async {
    try {
      if (kDebugMode) {
        print('GameBloc: Processing daily word change to: ${event.newWord}');
      }

      // Get the current state
      if (state is GameLoaded) {
        final currentState = state as GameLoaded;

        // Only update if the word is different
        if (event.newWord.toLowerCase() != currentState.targetWord.toLowerCase()) {
          // Show loading state
          emit(GameLoading(previousState: currentState));

          // Check if the user has already completed the game for today
          if (currentState.isCompleted) {
            // Notify the user that a new word is available via the hasNewWordAvailable flag
            if (kDebugMode) {
              print('GameBloc: Game was completed, notifying user about new word');
            }

            // Emit the same state but with the hasNewWordAvailable flag set to true
            emit(currentState.copyWith(
              hasNewWordAvailable: true,
            ));
          } else {
            // Game was not completed, so we can automatically update to the new word
            if (kDebugMode) {
              print('GameBloc: Game was not completed, automatically updating to new word');
            }

            // Get a fresh state with the new word
            final today = DateTime.now();
            final dailyWordId = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

            // Get best score
            final bestScore = await _getBestScore();

            // Create a new game state model
            final newGameState = GameStateModel(
              targetWord: event.newWord,
              guesses: [], // Start fresh for a new word
              isCompleted: false,
              bestScore: bestScore,
              dailyWordId: dailyWordId,
              wasShared: false,
            );

            // Save to preferences using the repository
            await _gameRepository.saveGameState(newGameState);

            // Emit the new state
            emit(GameLoaded(
              targetWord: event.newWord,
              guesses: [], // Start fresh for a new word
              isCompleted: false,
              bestScore: bestScore,
              dailyWordId: dailyWordId,
            ));
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('GameBloc: Error processing daily word change: $e');
      }

      // If there was an error, keep the current state
      if (state is GameLoaded) {
        emit(state);
      }
    }
  }

  Future<void> _onGameInitialized(
      GameInitialized event,
      Emitter<GameState> emit,
      ) async {
    emit(const GameLoading());

    try {
      // Obter a data atual
      final today = DateTime.now();
      final currentDateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Tenta carregar estado salvo usando o método padronizado
      final savedGameState = await _loadSavedGameState();

      // Se o estado salvo existir e for válido para hoje, use-o
      if (savedGameState != null && savedGameState.dailyWordId == currentDateStr) {
        if (kDebugMode) {
          print('GameBloc: Utilizando estado salvo para hoje. Palavra: ${savedGameState.targetWord}');
        }

        emit(GameLoaded(
          targetWord: savedGameState.targetWord,
          guesses: savedGameState.guesses,
          isCompleted: savedGameState.isCompleted,
          bestScore: savedGameState.bestScore,
          dailyWordId: savedGameState.dailyWordId,
        ));
        return;
      }

      // Se não tem estado salvo válido, verifica a palavra no Firestore
      if (kDebugMode) {
        print('GameBloc: Buscando palavra do dia no Firestore...');
      }

      try {
        final dailyWordDoc = await _firestore.collection(AppConstants.dailyWordCollection).doc(currentDateStr).get();

        if (dailyWordDoc.exists && dailyWordDoc.data()!.containsKey('word')) {
          final firestoreWord = dailyWordDoc.data()!['word'] as String;

          if (kDebugMode) {
            print('GameBloc: Palavra do dia encontrada no Firestore: $firestoreWord');
          }

          // Obter pontuação atual e criar novo estado
          final bestScore = await _getBestScore();
          final newGameState = GameStateModel(
            targetWord: firestoreWord,
            guesses: [],
            isCompleted: false,
            bestScore: bestScore,
            dailyWordId: currentDateStr,
            wasShared: false,
          );

          // Salvar e emitir o novo estado
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
      } catch (e) {
        if (kDebugMode) {
          print('GameBloc: Erro ao verificar palavra do dia no Firestore: $e');
        }
        // Continua para usar o método de fallback
      }

      // FALLBACK: Se não conseguiu do Firestore, usa o método local
      if (kDebugMode) {
        print('GameBloc: Usando método local para obter palavra do dia');
      }

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
      } else {
        emit(const GameError(message: 'Não foi possível iniciar o jogo'));
      }
    } catch (e) {
      if (kDebugMode) {
        print('GameBloc: Erro ao inicializar o jogo: $e');
      }
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
          // Modifica a última tentativa se for uma dica
          final updatedGuesses = gameState.guesses.map((guess) {
            return event.isHint ? guess.copyWith(isHint: true) : guess;
          }).toList();

          // Salva o novo estado
          _saveGameStateToPrefs(gameState.copyWith(guesses: updatedGuesses));

          emit(GameLoaded(
            targetWord: gameState.targetWord,
            guesses: updatedGuesses,
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
      if (kDebugMode) {
        print('Erro ao marcar jogo como compartilhado: $e');
      }
    }
  }

  Future<void> _onGameRefreshDaily(
      GameRefreshDaily event,
      Emitter<GameState> emit
      ) async {
    try {
      // Verificar estado atual antes de fazer mudanças
      if (state is! GameLoaded) {
        if (kDebugMode) {
          print('GameBloc: Não há estado carregado para atualizar');
        }
        return;
      }

      final currentState = state as GameLoaded;

      // Se este refresh é após assistir um anúncio, preserva o estado
      if (event.isAfterAd) {
        if (kDebugMode) {
          print('GameBloc: Refresh após anúncio - preservando estado atual com ${currentState.guesses.length} tentativas');
        }

        // Simplesmente re-emite o estado atual para garantir que não há mudanças
        emit(currentState);
        return;
      }

      // Continua com a lógica normal para verificação diária
      await _dailyWordListener.checkForDateChange();
      final latestWord = await _dailyWordListener.forceCheck();

      // Se não conseguimos obter uma palavra, usa o fallback
      if (latestWord == null) {
        _fallbackDailyRefresh(emit);
        return;
      }

      // Obtém a data atual
      final today = DateTime.now();
      final currentDateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final prefs = await SharedPreferences.getInstance();
      final savedDate = prefs.getString(AppConstants.prefsKeyGameStateDate);

      // Verifica se a data mudou
      if (savedDate != currentDateStr) {
        if (kDebugMode) {
          print('GameBloc: Data mudou - criando novo jogo para hoje');
        }

        // Cria novo estado para o novo dia
        final newGameState = GameStateModel(
          targetWord: latestWord,
          guesses: [], // Começa do zero no novo dia
          isCompleted: false,
          bestScore: currentState.bestScore,
          dailyWordId: currentDateStr,
          wasShared: false,
        );

        // Salva e emite o novo estado
        await _gameRepository.saveGameState(newGameState);
        emit(GameLoaded(
          targetWord: latestWord,
          guesses: [],
          isCompleted: false,
          bestScore: currentState.bestScore,
          dailyWordId: currentDateStr,
        ));
      }
      // Verifica se a palavra mudou ou temos uma flag de nova palavra
      else if (latestWord.toLowerCase() != currentState.targetWord.toLowerCase() ||
          currentState.hasNewWordAvailable) {
        if (kDebugMode) {
          print('GameBloc: Palavra mudou - atualizando para a nova palavra');
        }

        // Atualiza o estado para a nova palavra
        final updatedGameState = GameStateModel(
          targetWord: latestWord,
          guesses: [], // Começa do zero para a nova palavra
          isCompleted: false,
          bestScore: currentState.bestScore,
          dailyWordId: currentDateStr,
          wasShared: false,
        );

        // Salva e emite o novo estado
        await _gameRepository.saveGameState(updatedGameState);
        emit(GameLoaded(
          targetWord: latestWord,
          guesses: [],
          isCompleted: false,
          bestScore: currentState.bestScore,
          dailyWordId: currentDateStr,
          hasNewWordAvailable: false, // Reseta a flag
        ));
      } else {
        if (kDebugMode) {
          print('GameBloc: Refresh diário - nenhuma mudança necessária');
        }

        // Re-emite o estado atual com a flag de nova palavra resetada
        emit(currentState.copyWith(
          hasNewWordAvailable: false,
        ));
      }
    } catch (e) {
      if (kDebugMode) {
        print('GameBloc: Erro no refresh diário: $e');
      }

      // Tenta o método fallback se algo deu errado
      _fallbackDailyRefresh(emit);
    }
  }

  // Original refresh method as fallback
  void _fallbackDailyRefresh(Emitter<GameState> emit) async {
    try {
      // Obter a data atual no formato YYYY-MM-DD
      final today = DateTime.now();
      final currentDateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Obtemos o estado atual do jogo
      final currentStateResult = await _loadSavedGameState();
      final currentState = (state is GameLoaded) ? state as GameLoaded :
      (currentStateResult != null ? GameLoaded(
        targetWord: currentStateResult.targetWord,
        guesses: currentStateResult.guesses,
        isCompleted: currentStateResult.isCompleted,
        bestScore: currentStateResult.bestScore,
        dailyWordId: currentStateResult.dailyWordId,
      ) : null);

      // Mostrar estado de carregamento se já temos um estado atual
      if (currentState != null) {
        emit(GameLoading(previousState: currentState));
      } else {
        emit(const GameLoading());
      }

      // PASSO 1: Verificar se já temos um estado de jogo válido para hoje
      bool needsRefresh = true;

      if (currentState != null) {
        // Verificar se o ID do jogo corresponde à data atual
        if (currentState.dailyWordId == currentDateStr) {
          // Temos um jogo para hoje, mas precisamos verificar se a palavra está correta

          // PASSO 2: Verificar se a palavra em cache corresponde à do Firestore
          try {
            // Buscar a palavra do dia no Firestore
            final docSnapshot = await _firestore.collection('daily_words').doc(currentDateStr).get();

            if (docSnapshot.exists && docSnapshot.data()!.containsKey('word')) {
              final serverWord = docSnapshot.data()!['word'] as String;

              // Comparar com a palavra atual
              if (serverWord.toLowerCase() == currentState.targetWord.toLowerCase()) {
                // A palavra é a mesma, não precisamos atualizar
                needsRefresh = false;

                if (kDebugMode) {
                  print('Palavra em cache corresponde à palavra do servidor para hoje: ${currentState.targetWord}');
                }

                // Apenas emitir o estado atual novamente
                emit(currentState);
              } else {
                // A palavra é diferente, precisamos atualizar
                if (kDebugMode) {
                  print('Palavra em cache (${currentState.targetWord}) é diferente da palavra do servidor ($serverWord). Atualizando...');
                }
              }
            }
          } catch (e) {
            // Em caso de erro na verificação, continuamos para atualizar por segurança
            if (kDebugMode) {
              print('Erro ao verificar a palavra no Firestore: $e');
            }
          }
        }
      }

      // PASSO 3: Se necessário, atualizar o jogo com a nova palavra
      if (needsRefresh) {
        if (kDebugMode) {
          print('Atualizando palavra do dia para: $currentDateStr');
        }

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

          if (kDebugMode) {
            print('Palavra do dia atualizada com sucesso para: ${result.targetWord}');
          }
        } else {
          // Se falhou ao obter uma nova palavra, voltar ao estado anterior se existir
          if (currentState != null) {
            emit(currentState);
          } else {
            emit(const GameError(message: "Não foi possível obter a palavra do dia"));
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao atualizar palavra do dia: $e');
      }

      // Em caso de erro, voltar ao estado anterior se existir
      if (state is GameLoaded) {
        emit(GameError(
          message: "Erro ao atualizar palavra do dia: ${e.toString()}",
          previousState: state as GameLoaded,
        ));
        emit(state);
      } else {
        emit(GameError(message: "Erro ao atualizar palavra do dia: ${e.toString()}"));
      }
    }
  }

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
      if (targetWord == null || targetWord.trim().isEmpty) {
        // Tenta usar o fallback de palavra aleatória na coleção words
        final wordsSnapshot = await _firestore.collection('words').limit(50).get();

        if (wordsSnapshot.docs.isNotEmpty) {
          // Escolhe uma palavra aleatória da coleção
          final random = DateTime.now().millisecondsSinceEpoch % wordsSnapshot.docs.length;
          targetWord = wordsSnapshot.docs[random].id;

          if (kDebugMode) {
            print('Palavra não encontrada para hoje no Firestore, usando palavra aleatória da coleção words: $targetWord');
          }

          // Opcionalmente, salva esta palavra como a do dia (para outros usuários também)
          try {
            await _firestore.collection('daily_words').doc(dateStr).set({
              'word': targetWord,
              'timestamp': FieldValue.serverTimestamp(),
              'auto_generated': true,
            });
          } catch (e) {
            // Ignoramos erros ao tentar salvar
            if (kDebugMode) {
              print('Erro ao salvar palavra aleatória como palavra do dia: $e');
            }
          }
        } else {
          // Se falhar, use palavras básicas como fallback final
          const fallbackWords = ['palavra', 'contexto', 'jogo', 'desafio', 'linguagem'];
          final random = DateTime.now().millisecondsSinceEpoch % fallbackWords.length;
          targetWord = fallbackWords[random];

          if (kDebugMode) {
            print('Nenhuma palavra encontrada no Firestore, usando palavra fallback básica: $targetWord');
          }
        }
      }

      if (targetWord != null) {
        // Obter melhor pontuação
        final bestScore = await _getBestScore();

        // Criar novo estado de jogo
        return GameStateModel(
          targetWord: targetWord,
          guesses: [], // Limpa todas as tentativas anteriores
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

  void clearNewWordDialogFlag() {
    // Dispara o evento para limpar a flag
    add(const ClearNewWordDialogFlag());
  }

  Future<int> _getBestScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('best_score') ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _saveGameStateToPrefs(GameStateModel gameState) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(gameState.toJson());

      if (gameState.dailyWordId.isEmpty) {
        final today = DateTime.now();
        final currentDateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        gameState = gameState.copyWith(dailyWordId: currentDateStr);
      }

      // Usar a constante padronizada
      await prefs.setString(AppConstants.prefsKeyGameState, jsonString);

      // Também salvamos a data em que este estado foi salvo
      await prefs.setString(AppConstants.prefsKeyGameStateDate, gameState.dailyWordId);

      if (kDebugMode) {
        print('GameBloc: Estado do jogo salvo com sucesso. Data: ${gameState.dailyWordId}, Palavra: ${gameState.targetWord}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('GameBloc: Erro ao salvar estado do jogo: $e');
      }
    }
  }

  Future<GameStateModel?> _loadSavedGameState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Usar a constante padronizada
      final gameStateJson = prefs.getString(AppConstants.prefsKeyGameState);
      final savedDate = prefs.getString(AppConstants.prefsKeyGameStateDate);

      if (gameStateJson != null) {
        Map<String, dynamic> jsonP = json.decode(gameStateJson);
        var state = GameStateModel.fromJson(jsonP);

        // Obter a data atual
        final today = DateTime.now();
        final currentDateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        // Se o estado salvo NÃO corresponde à data atual, não use
        if (savedDate != currentDateStr) {
          if (kDebugMode) {
            print('GameBloc: Estado do jogo encontrado, mas a data não corresponde à atual. ' +
                'Data salva: ${state.dailyWordId}, Data atual: $currentDateStr');
          }
          return null;
        }

        if (state.dailyWordId.isEmpty) {
          print('GameBloc: Estado do jogo encontrado, mas sem data válida');
          // Definir a data corretamente antes de retornar
          state = state.copyWith(dailyWordId: currentDateStr);
          // Salvar o estado com a data corrigida
          await _saveGameStateToPrefs(state);
        }

        if (kDebugMode) {
          print('GameBloc: Estado do jogo carregado com sucesso para hoje. Palavra: ${state.targetWord}');
        }

        return state;
      }

      if (kDebugMode) {
        print('GameBloc: Nenhum estado de jogo encontrado nas preferências');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('GameBloc: Erro ao carregar estado do jogo: $e');
      }
      return null;
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
    }  else {
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

  // Notifica quando o app volta ao primeiro plano
  void onAppResume() {
    // Usa o serviço de listener para verificar mudanças na palavra do dia
    _dailyWordListener.onAppResume();
  }

  // Fecha o bloc e cancela listeners
  @override
  Future<void> close() {
    _dailyWordSubscription?.cancel();
    _wordUpdateSubscription?.cancel();
    _dailyWordListener.dispose();
    return super.close();
  }
}
