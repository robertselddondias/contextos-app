// data/repositories/word_repository_impl.dart
import 'dart:convert';
import 'dart:math';

import 'package:contextual/core/error/failures.dart';
import 'package:contextual/data/datasources/local/shared_prefs_manager.dart';
import 'package:contextual/data/datasources/remote/google_nlp_service.dart';
import 'package:contextual/domain/entities/word.dart';
import 'package:contextual/domain/repositories/word_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';

class WordRepositoryImpl implements WordRepository {
  final GoogleNlpService _remoteDataSource;
  final SharedPrefsManager _localDataSource;

  List<String> _words = [];
  final _random = Random();

  WordRepositoryImpl({
    required GoogleNlpService remoteDataSource,
    required SharedPrefsManager localDataSource,
  }) : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource {
    _loadWordList();
  }

  Future<void> _loadWordList() async {
    try {
      final String wordsJson = await rootBundle.loadString('assets/words/portuguese_words.json');
      final List<dynamic> wordList = json.decode(wordsJson);
      _words = wordList.cast<String>();
    } catch (e) {
      // Em caso de erro, usar uma lista padrão
      _words = [
        'amor', 'felicidade', 'trabalho', 'família', 'amizade',
        'computador', 'internet', 'telefone', 'viagem', 'comida',
        'escola', 'livro', 'música', 'filme', 'esporte',
        'natureza', 'cidade', 'país', 'política', 'economia',
        'saúde', 'médico', 'hospital', 'remédio', 'exercício',
        'dinheiro', 'banco', 'investimento', 'poupança', 'compra'
      ];
    }
  }

  @override
  Future<Either<Failure, double>> calculateSimilarity(String word1, String word2) async {
    try {
      // Primeiro verificamos se temos a similaridade no cache
      final cachedSimilarity = await _localDataSource.getCachedWordSimilarity(word1, word2);

      if (cachedSimilarity != null) {
        return Right(cachedSimilarity);
      }

      // Se as palavras são iguais, retornamos 1.0 (similaridade máxima)
      if (word1.toLowerCase() == word2.toLowerCase()) {
        await _localDataSource.cacheWordSimilarity(word1, word2, 1.0);
        return const Right(1.0);
      }

      // Caso contrário, calculamos a similaridade usando o serviço NLP
      final similarity = await _remoteDataSource.calculateSimilarity(word1, word2);

      // Salvamos no cache para futuras consultas
      await _localDataSource.cacheWordSimilarity(word1, word2, similarity);

      return Right(similarity);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getDailyWord({bool forceNewWord = false}) async {
    try {
      // Criamos um ID para o dia atual (no formato "YYYY-MM-DD")
      final today = DateTime.now();
      final dailyWordId = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Se não estamos forçando uma nova palavra, tentamos obter a palavra salva para hoje
      if (!forceNewWord) {
        final savedWord = await _localDataSource.getDailyWord(dailyWordId);
        if (savedWord != null) {
          return Right(savedWord);
        }
      }

      // Se não temos uma palavra salva ou estamos forçando uma nova, geramos uma nova
      if (_words.isEmpty) {
        await _loadWordList();
      }

      if (_words.isEmpty) {
        return const Left(CacheFailure('Não foi possível carregar a lista de palavras'));
      }

      // Geramos um número aleatório baseado na data atual para ter consistência
      final seed = today.year * 10000 + today.month * 100 + today.day;
      final random = Random(seed);

      final word = _words[random.nextInt(_words.length)];

      // Salvamos a palavra para hoje
      await _localDataSource.saveDailyWord(word, dailyWordId);

      return Right(word);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isValidWord(String word) async {
    try {
      if (_words.isEmpty) {
        await _loadWordList();
      }

      return Right(_words.contains(word.toLowerCase()));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Word>>> getAvailableWords() async {
    try {
      if (_words.isEmpty) {
        await _loadWordList();
      }

      return Right(_words.map((text) => Word(text: text)).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Word>> getRandomWord() async {
    try {
      if (_words.isEmpty) {
        await _loadWordList();
      }

      if (_words.isEmpty) {
        return const Left(CacheFailure('Não foi possível carregar a lista de palavras'));
      }

      final word = _words[_random.nextInt(_words.length)];

      return Right(Word(text: word));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
