// core/error/failures.dart
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Falha no servidor']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Falha na conexão de rede']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Falha no armazenamento local']);
}

class InvalidInputFailure extends Failure {
  const InvalidInputFailure([super.message = 'Entrada inválida']);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure([super.message = 'Falha na autenticação']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Recurso não encontrado']);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Ocorreu um erro inesperado']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Tempo de conexão esgotado']);
}

class ApiLimitExceededFailure extends Failure {
  const ApiLimitExceededFailure([super.message = 'Limite de requisições da API excedido']);
}
