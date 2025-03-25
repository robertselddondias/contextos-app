// presentation/blocs/game/game_bloc.dart
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:contextual/domain/entities/guess.dart';
import 'package:contextual/domain/usecases/get_daily_word.dart';
import 'package:contextual/domain/usecases/make_guess.dart';
import 'package:contextual/domain/usecases/save_game_state.dart';
import 'package:equatable/equatable.dart';

part 'game_event.dart';
part 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  final GetDailyWord getDailyWord;
  final MakeGuess makeGuess;
  final SaveGameState saveGameState;


  GameBloc({
    required this.getDailyWord,
    required this.makeGuess,
    required this.saveGameState,
  }) : super(const GameInitial()) {
    on<GameInitialized>(_onGameInitialized);
    on<GuessSubmitted>(_onGuessSubmitted);
    on<GameReset>(_onGameReset);
    on<GameShared>(_onGameShared);
  }

  Future<void> _onGameInitialized(
      GameInitialized event,
      Emitter<GameState> emit,
      ) async {
    emit(const GameLoading());

    try {
      final result = await getDailyWord(const GetDailyWordParams());

      result.fold(
            (failure) => emit(GameError(message: failure.message)),
            (gameState) => emit(GameLoaded(
          targetWord: gameState.targetWord,
          guesses: gameState.guesses,
          isCompleted: gameState.isCompleted,
          bestScore: gameState.bestScore,
          dailyWordId: gameState.dailyWordId,
        )),
      );
    } catch (e) {
      emit(GameError(message: e.toString()));
    }
  }

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
            (gameState) => emit(GameLoaded(
          targetWord: gameState.targetWord,
          guesses: gameState.guesses,
          isCompleted: gameState.isCompleted,
          bestScore: gameState.bestScore,
          dailyWordId: gameState.dailyWordId,

        )),
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
      // Reset é usado apenas para testes ou para quando queremos forçar uma
      // nova palavra mesmo no mesmo dia (para desenvolvimento)
      final result = await getDailyWord(const GetDailyWordParams(forceNewWord: true));

      result.fold(
            (failure) => emit(GameError(message: failure.message)),
            (gameState) => emit(GameLoaded(
          targetWord: gameState.targetWord,
          guesses: gameState.guesses,
          isCompleted: gameState.isCompleted,
          bestScore: gameState.bestScore,
          dailyWordId: gameState.dailyWordId,
        )),
      );
    } catch (e) {
      emit(GameError(message: e.toString()));
    }
  }

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

  String generateShareText() {
    if (state is! GameLoaded) return '';

    final currentState = state as GameLoaded;
    final today = DateTime.now();
    final dayNumber = today.difference(DateTime(2023, 1, 1)).inDays;

    String shareText = 'Contexto #$dayNumber\n';

    if (currentState.isCompleted) {
      shareText += 'Encontrei a palavra "${currentState.targetWord.toUpperCase()}" em ${currentState.guesses.length} tentativas!\n\n';
    } else {
      shareText += 'Ainda estou tentando...\n\n';
    }

    // Adicionamos as últimas 5 tentativas (ou todas se houver menos de 5)
    final startIndex = currentState.guesses.length > 5 ? currentState.guesses.length - 5 : 0;
    for (int i = startIndex; i < currentState.guesses.length; i++) {
      final guess = currentState.guesses[i];
      shareText += '${i + 1}. ${guess.word} (${(guess.similarity * 100).toStringAsFixed(0)}%)\n';
    }

    shareText += '\nJogue em: contexto-game.exemplo.com';

    return shareText;
  }
}
