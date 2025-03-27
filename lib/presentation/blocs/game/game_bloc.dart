// presentation/blocs/game/game_bloc.dart
import 'dart:async';
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

  // Busca uma palavra de dica relacionada
  String _getHintWord(GameLoaded state) {
    final contextService = FirebaseContextService();

    try {
      // Obtém as relações da palavra-alvo
      final relations = contextService.getWordRelations(state.targetWord.toLowerCase());

      // Se existem relações, retorna a primeira palavra com similaridade alta
      final relatedWords = relations.entries
          .where((entry) => entry.value > 0.6) // Apenas palavras com similaridade acima de 60%
          .map((entry) => entry.key)
          .toList();

      if (relatedWords.isNotEmpty) {
        // Retorna uma palavra aleatória das relações
        final random = Random();
        return relatedWords[random.nextInt(relatedWords.length)];
      }
    } catch (e) {
      print('Erro ao obter palavra de dica: $e');
    }

    // Fallback para dicas genéricas
    final genericHints = [
      'objeto', 'conceito', 'animal', 'lugar', 'ação',
      'sentimento', 'natureza', 'tecnologia', 'pessoa',
    ];

    return genericHints[DateTime.now().microsecondsSinceEpoch % genericHints.length];
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
      print('Erro ao marcar jogo como compartilhado: $e');
    }
  }

  // Atualização diária
  Future<void> _onGameRefreshDaily(
      GameRefreshDaily event,
      Emitter<GameState> emit,
      ) async {
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
      final jsonString = gameState.toRawJson();
      await prefs.setString('game_state', jsonString);

      // Salvamos também a data em que este estado foi salvo
      final dateStr = gameState.dailyWordId;
      await prefs.setString('game_state_date', dateStr);

      if (kDebugMode) {
        print('Estado do jogo salvo com sucesso para data: ${gameState.dailyWordId}, palavra: ${gameState.targetWord}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao salvar estado do jogo: $e');
      }
    }
  }

  Future<GameStateModel?> _loadSavedGameState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gameStateJson = prefs.getString('game_state');
      final savedDate = prefs.getString('game_state_date');

      if (gameStateJson != null) {
        final state = GameStateModel.fromRawJson(gameStateJson);

        // Obter a data atual
        final today = DateTime.now();
        final currentDateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

        // Se o estado salvo NÃO corresponde à data atual, não use
        if (state.dailyWordId != currentDateStr || savedDate != currentDateStr) {
          if (kDebugMode) {
            print('Estado do jogo encontrado, mas a data não corresponde à atual. ' +
                'Data salva: ${state.dailyWordId}, Data atual: $currentDateStr');
          }
          return null;
        }

        if (kDebugMode) {
          print('Estado do jogo carregado com sucesso para hoje. Palavra: ${state.targetWord}');
        }

        return state;
      }

      if (kDebugMode) {
        print('Nenhum estado de jogo encontrado nas preferências');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar estado do jogo: $e');
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

  // Fecha o bloc e cancela listeners
  @override
  Future<void> close() {
    _dailyWordSubscription?.cancel();
    return super.close();
  }
}
