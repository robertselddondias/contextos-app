// core/usecases/usecase.dart
import 'package:contextual/core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

/// Interface genérica para todos os Use Cases da aplicação
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use case que não exige parâmetros
class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}
