// part of 'game_bloc.dart'
part of 'game_bloc.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object> get props => [];
}

class GameInitialized extends GameEvent {
  const GameInitialized();
}

class GuessSubmitted extends GameEvent {
  final String guess;

  const GuessSubmitted(this.guess);

  @override
  List<Object> get props => [guess];
}

class GameReset extends GameEvent {
  const GameReset();
}

class GameShared extends GameEvent {
  const GameShared();
}

// Adicionar este novo evento
class GameRefreshDaily extends GameEvent {
  const GameRefreshDaily();
}
