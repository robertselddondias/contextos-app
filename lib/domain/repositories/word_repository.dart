// domain/repositories/word_repository.dart
import 'package:contextual/core/error/failures.dart';
import 'package:contextual/domain/entities/word.dart';
import 'package:dartz/dartz.dart';

abstract class WordRepository {
  /// Calcula a similaridade semântica entre duas palavras
  Future<Either<Failure, double>> calculateSimilarity(String word1, String word2);

  /// Obtém a palavra do dia para o jogo
  Future<Either<Failure, String>> getDailyWord({bool forceNewWord = false});

  /// Verifica se uma palavra é válida para o jogo
  Future<Either<Failure, bool>> isValidWord(String word);

  /// Carrega a lista de palavras disponíveis
  Future<Either<Failure, List<Word>>> getAvailableWords();

  /// Obtém uma palavra aleatória
  Future<Either<Failure, Word>> getRandomWord();
}
