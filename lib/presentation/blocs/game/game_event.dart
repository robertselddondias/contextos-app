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
  final bool isHint;

  const GuessSubmitted(this.guess, {this.isHint = false});

  @override
  List<Object> get props => [guess, isHint];
}

class GameReset extends GameEvent {
  final bool preserveGuesses;

  const GameReset({this.preserveGuesses = false});

  @override
  List<Object> get props => [preserveGuesses];
}

class GameShared extends GameEvent {
  const GameShared();
}

class GameRefreshDaily extends GameEvent {
  const GameRefreshDaily();
}

