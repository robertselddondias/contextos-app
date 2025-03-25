// core/error/failures.dart
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Falha no servidor']) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Falha na conexão de rede']) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Falha no armazenamento local']) : super(message);
}

class InvalidInputFailure extends Failure {
  const InvalidInputFailure([String message = 'Entrada inválida']) : super(message);
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure([String message = 'Falha na autenticação']) : super(message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([String message = 'Recurso não encontrado']) : super(message);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([String message = 'Ocorreu um erro inesperado']) : super(message);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([String message = 'Tempo de conexão esgotado']) : super(message);
}

class ApiLimitExceededFailure extends Failure {
  const ApiLimitExceededFailure([String message = 'Limite de requisições da API excedido']) : super(message);
}
