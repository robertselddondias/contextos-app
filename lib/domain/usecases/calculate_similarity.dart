// domain/usecases/calculate_similarity.dart
import 'package:contextual/core/error/failures.dart';
import 'package:contextual/domain/repositories/word_repository.dart';
import 'package:contextual/domain/usecases/usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class CalculateSimilarity implements UseCase<double, CalculateSimilarityParams> {
  final WordRepository _wordRepository;

  CalculateSimilarity({required WordRepository wordRepository})
      : _wordRepository = wordRepository;

  @override
  Future<Either<Failure, double>> call(CalculateSimilarityParams params) async {
    return _wordRepository.calculateSimilarity(params.word1, params.word2);
  }
}

class CalculateSimilarityParams extends Equatable {
  final String word1;
  final String word2;

  const CalculateSimilarityParams({
    required this.word1,
    required this.word2,
  });

  @override
  List<Object?> get props => [word1, word2];
}
