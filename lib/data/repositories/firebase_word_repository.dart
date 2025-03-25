// data/repositories/firebase_word_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contextual/core/error/failures.dart';
import 'package:contextual/data/datasources/remote/firebase_nlp_service.dart';
import 'package:contextual/domain/entities/word.dart';
import 'package:contextual/domain/repositories/word_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseWordRepository implements WordRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NlpService _nlpService;

  // Cache de palavras
  List<Word> _cachedWords = [];

  // Cache de palavras usadas recentemente para evitar repetição
  final List<String> _recentlyUsedWords = [];
  static const int _maxRecentWords = 5; // Guarda as últimas 5 palavras para evitar repetição

  // Cache de palavras diárias
  Map<String, String> _cachedDailyWords = {};

  // Chave para armazenar a palavra personalizada do usuário nas preferências
  static const String _userCustomWordKey = 'user_custom_word';
  static const String _userCustomWordDateKey = 'user_custom_word_date';

  FirebaseWordRepository(this._nlpService);

  @override
  Future<Either<Failure, double>> calculateSimilarity(String word1, String word2) async {
    try {
      final similarity = await _nlpService.calculateSimilarity(word1, word2);
      return Right(similarity);
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseWordRepository: Erro ao calcular similaridade: $e');
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getDailyWord({bool forceNewWord = false}) async {
    try {
      // Obtém a data atual no formato YYYY-MM-DD
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Se forceNewWord é true, vamos gerar uma palavra personalizada para este usuário
      if (forceNewWord) {
        if (kDebugMode) {
          print('FirebaseWordRepository: Gerando palavra personalizada para o usuário');
        }

        // Obtém uma palavra aleatória diferente da palavra do dia
        final String? regularDailyWord = await _getRegularDailyWord(dateStr);
        final randomWordResult = await _getRandomWord(excludeWord: regularDailyWord);

        return randomWordResult.fold(
              (failure) => Left(failure),
              (word) async {
            try {
              // Salva a palavra personalizada nas preferências do usuário
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(_userCustomWordKey, word.text);
              await prefs.setString(_userCustomWordDateKey, dateStr);

              // Adiciona à lista de palavras recentes
              _addToRecentWords(word.text);

              if (kDebugMode) {
                print('FirebaseWordRepository: Nova palavra personalizada gerada: ${word.text}');
              }

              return Right(word.text);
            } catch (e) {
              if (kDebugMode) {
                print('FirebaseWordRepository: Erro ao salvar palavra personalizada: $e');
              }
              return Right(word.text);
            }
          },
        );
      }

      // Verificar se o usuário tem uma palavra personalizada para hoje
      final prefs = await SharedPreferences.getInstance();
      final customWordDate = prefs.getString(_userCustomWordDateKey);

      // Se temos uma palavra personalizada para hoje, usamos ela
      if (customWordDate == dateStr) {
        final customWord = prefs.getString(_userCustomWordKey);
        if (customWord != null && customWord.isNotEmpty) {
          if (kDebugMode) {
            print('FirebaseWordRepository: Usando palavra personalizada do usuário: $customWord');
          }
          return Right(customWord);
        }
      } else {
        // Se a data da palavra personalizada for diferente, limpamos ela
        // para que o usuário receba a palavra do dia normal
        if (customWordDate != null) {
          await prefs.remove(_userCustomWordKey);
          await prefs.remove(_userCustomWordDateKey);
        }
      }

      // Verifica cache primeiro para evitar chamadas desnecessárias ao Firestore
      if (_cachedDailyWords.containsKey(dateStr)) {
        return Right(_cachedDailyWords[dateStr]!);
      }

      // Tenta buscar a palavra do dia no Firestore
      final regularWord = await _getRegularDailyWord(dateStr);
      if (regularWord != null) {
        return Right(regularWord);
      }

      // Se não encontrou uma palavra para hoje, gera uma aleatória
      final randomWord = await _getRandomWord();

      // Salva esta palavra como a palavra do dia no Firestore
      return await randomWord.fold(
            (failure) => Left(failure),
            (word) async {
          try {
            await _firestore.collection('daily_words').doc(dateStr).set({
              'word': word.text,
              'timestamp': FieldValue.serverTimestamp(),
            });

            // Atualiza o cache
            _cachedDailyWords[dateStr] = word.text;

            // Adiciona à lista de palavras recentes
            _addToRecentWords(word.text);

            if (kDebugMode) {
              print('FirebaseWordRepository: Nova palavra do dia gerada e salva: ${word.text}');
            }

            return Right(word.text);
          } catch (e) {
            if (kDebugMode) {
              print('FirebaseWordRepository: Erro ao salvar palavra do dia: $e');
            }
            // Mesmo se falhar a persistência, retorna a palavra gerada
            return Right(word.text);
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseWordRepository: Erro ao obter palavra do dia: $e');
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  // Obtém a palavra regular do dia (não personalizada)
  Future<String?> _getRegularDailyWord(String dateStr) async {
    try {
      // Verifica cache primeiro
      if (_cachedDailyWords.containsKey(dateStr)) {
        return _cachedDailyWords[dateStr];
      }

      // Tenta buscar a palavra do dia no Firestore
      final docSnapshot = await _firestore.collection('daily_words').doc(dateStr).get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        if (data.containsKey('word')) {
          final word = data['word'] as String;
          // Atualiza o cache
          _cachedDailyWords[dateStr] = word;

          // Adiciona à lista de palavras recentes
          _addToRecentWords(word);

          if (kDebugMode) {
            print('FirebaseWordRepository: Palavra do dia obtida do Firestore: $word');
          }

          return word;
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseWordRepository: Erro ao obter palavra regular do dia: $e');
      }
      return null;
    }
  }

  // Adiciona uma palavra à lista de palavras recentes
  void _addToRecentWords(String word) {
    // Verifica se a palavra já existe na lista
    if (!_recentlyUsedWords.contains(word)) {
      // Adiciona a palavra à lista
      _recentlyUsedWords.add(word);

      // Limita o tamanho da lista
      if (_recentlyUsedWords.length > _maxRecentWords) {
        _recentlyUsedWords.removeAt(0); // Remove a palavra mais antiga
      }
    }
  }

  @override
  Future<Either<Failure, bool>> isValidWord(String word) async {
    try {
      word = word.toLowerCase().trim();

      // Verifica cache primeiro
      if (_cachedWords.isNotEmpty) {
        bool isValid = _cachedWords.any((w) => w.text.toLowerCase() == word);
        return Right(isValid);
      }

      // Consulta diretamente o Firestore
      final docSnapshot = await _firestore.collection('words').doc(word).get();
      return Right(docSnapshot.exists);
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseWordRepository: Erro ao verificar validade da palavra: $e');
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Word>>> getAvailableWords() async {
    try {
      // Se já temos palavras em cache, retorna o cache
      if (_cachedWords.isNotEmpty) {
        return Right(_cachedWords);
      }

      final words = <Word>[];
      const int maxWordsToLoad = 500; // Limite para não sobrecarregar a memória

      // Busca todas as palavras
      final querySnapshot = await _firestore.collection('words').limit(maxWordsToLoad).get();

      if (kDebugMode) {
        print('FirebaseWordRepository: Obtidas ${querySnapshot.docs.length} palavras do Firestore');
      }

      // Para cada palavra
      for (final doc in querySnapshot.docs) {
        final wordText = doc.id;

        words.add(Word(
          text: wordText,
        ));
      }

      // Atualiza o cache
      _cachedWords = words;

      if (kDebugMode) {
        print('FirebaseWordRepository: Total de palavras carregadas: ${words.length}');
      }

      return Right(words);
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseWordRepository: Erro ao obter palavras disponíveis: $e');
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Word>> getRandomWord() async {
    return _getRandomWord();
  }

  // Método interno para ajudar com obtenção de palavras aleatórias
  Future<Either<Failure, Word>> _getRandomWord({String? excludeWord}) async {
    try {
      // Carrega palavras se o cache estiver vazio
      if (_cachedWords.isEmpty) {
        final wordsResult = await getAvailableWords();
        if (wordsResult.isLeft()) {
          return Left(NotFoundFailure('Não foi possível carregar a lista de palavras'));
        }
      }

      // Se ainda não temos palavras, tentamos buscar do Firestore diretamente
      if (_cachedWords.isEmpty) {
        final wordsSnapshot = await _firestore.collection('words').limit(100).get();

        if (wordsSnapshot.docs.isEmpty) {
          return Left(NotFoundFailure('Nenhuma palavra disponível no Firestore'));
        }

        // Lista de palavras do Firestore
        List<String> availableWords = wordsSnapshot.docs.map((doc) => doc.id).toList();

        // Filtra a lista para remover a palavra a ser excluída
        if (excludeWord != null) {
          availableWords.remove(excludeWord.toLowerCase());
        }

        // Remove palavras recentemente usadas
        for (final recentWord in _recentlyUsedWords) {
          availableWords.remove(recentWord);
        }

        // Verifica se ainda restam palavras disponíveis
        if (availableWords.isEmpty) {
          // Se não houver palavras disponíveis, usamos qualquer uma, menos a palavra excluída
          availableWords = wordsSnapshot.docs.map((doc) => doc.id).toList();
          if (excludeWord != null) {
            availableWords.remove(excludeWord.toLowerCase());
          }

          // Se mesmo assim não tiver palavras, usa qualquer uma
          if (availableWords.isEmpty) {
            availableWords = wordsSnapshot.docs.map((doc) => doc.id).toList();
          }
        }

        // Gera um número aleatório com o timestamp atual para maior aleatoriedade
        final randomSeed = DateTime.now().millisecondsSinceEpoch;
        final random = randomSeed % availableWords.length;
        final wordText = availableWords[random];

        return Right(Word(text: wordText));
      }

      // Cria uma cópia da lista de palavras para não modificar o cache
      final availableWords = List<Word>.from(_cachedWords);

      // Remove a palavra a ser excluída, se necessário
      if (excludeWord != null) {
        availableWords.removeWhere((word) => word.text.toLowerCase() == excludeWord.toLowerCase());
      }

      // Remove palavras recentemente usadas
      for (final recentWord in _recentlyUsedWords) {
        availableWords.removeWhere((word) => word.text.toLowerCase() == recentWord.toLowerCase());
      }

      // Se não restarem palavras após a filtragem, voltamos ao conjunto original
      if (availableWords.isEmpty) {
        availableWords.addAll(_cachedWords);
        if (excludeWord != null) {
          availableWords.removeWhere((word) => word.text.toLowerCase() == excludeWord.toLowerCase());
        }
      }

      // Gera um número aleatório com o timestamp atual para maior aleatoriedade
      final randomSeed = DateTime.now().millisecondsSinceEpoch;
      final random = randomSeed % availableWords.length;

      if (kDebugMode) {
        print('FirebaseWordRepository: Palavra aleatória selecionada: ${availableWords[random].text}');
      }

      return Right(availableWords[random]);
    } catch (e) {
      if (kDebugMode) {
        print('FirebaseWordRepository: Erro ao obter palavra aleatória: $e');
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  // Verifica se o usuário tem uma palavra personalizada para hoje
  Future<bool> hasCustomWordForToday() async {
    try {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final prefs = await SharedPreferences.getInstance();
      final customWordDate = prefs.getString(_userCustomWordDateKey);

      return customWordDate == dateStr && prefs.containsKey(_userCustomWordKey);
    } catch (e) {
      return false;
    }
  }

  // Método para forçar uma atualização do cache
  Future<void> refreshCache() async {
    _cachedWords = [];
    _cachedDailyWords = {};
    await getAvailableWords();
  }
}
