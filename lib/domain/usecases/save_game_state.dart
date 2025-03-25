// domain/usecases/save_game_state.dart
import 'package:contextual/core/error/failures.dart';
import 'package:contextual/domain/repositories/game_repository.dart';
import 'package:contextual/domain/usecases/usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class SaveGameState implements UseCase<void, SaveGameStateParams> {
  final GameRepository _gameRepository;

  SaveGameState({required GameRepository gameRepository})
      : _gameRepository = gameRepository;

  @override
  Future<Either<Failure, void>> call(SaveGameStateParams params) async {
    if (params.wasShared) {
      return _gameRepository.markGameAsShared();
    }

    // Para outras operações de salvamento, podemos adicionar
    // aqui conforme necessário
    return const Right(null);
  }
}

class SaveGameStateParams extends Equatable {
  final bool wasShared;

  const SaveGameStateParams({
    this.wasShared = false,
  });

  @override
  List<Object?> get props => [wasShared];
}
