// data/datasources/remote/firebase_context_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Serviço para gerenciar contextos semânticos no Firebase
class FirebaseContextService {
  // Singleton
  static final FirebaseContextService _instance = FirebaseContextService._internal();
  factory FirebaseContextService() => _instance;
  FirebaseContextService._internal();

  // Instância do Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache de palavras e suas relações
  final Map<String, Map<String, double>> _wordRelationsCache = {};

  // Flag para verificar inicialização
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Inicializa o serviço
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Verifica se o Firestore está acessível
      try {
        await _firestore.collection('words').limit(1).get();
        if (kDebugMode) {
          print('Firebase Context Service: Conexão com o Firestore está funcionando');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Firebase Context Service: ERRO NA CONEXÃO COM O FIRESTORE: $e');
        }
        throw Exception('Falha ao conectar ao Firestore: $e');
      }

      // Carrega dados do cache
      await loadWords();

      _isInitialized = true;
      if (kDebugMode) {
        print('Firebase Context Service inicializado com sucesso');
        print('Palavras carregadas: ${_wordRelationsCache.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firebase Context Service: ERRO ao inicializar: $e');
      }
      // Em caso de erro, continua usando o cache vazio
      _isInitialized = true;
    }
  }

  /// Carrega palavras do Firestore
  Future<void> loadWords() async {
    try {
      final snapshot = await _firestore.collection('words').limit(500).get();

      if (kDebugMode) {
        print('Firebase Context Service: Carregando ${snapshot.docs.length} palavras');
      }

      for (final doc in snapshot.docs) {
        final word = doc.id;
        final data = doc.data();

        if (data.containsKey('relations') && data['relations'] is Map) {
          _wordRelationsCache[word] = {};

          // Converte relações para o formato correto
          final relations = data['relations'] as Map<String, dynamic>;
          relations.forEach((relatedWord, value) {
            if (value is num) {
              _wordRelationsCache[word]![relatedWord] = value.toDouble();
            }
          });
        }
      }

      if (kDebugMode) {
        print('Firebase Context Service: ${_wordRelationsCache.length} palavras carregadas');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firebase Context Service: ERRO ao carregar palavras: $e');
      }
    }
  }

  /// Calcula a similaridade entre duas palavras
  double calculateSimilarity(String word1, String word2) {
    if (!_isInitialized) {
      throw Exception('FirebaseContextService não inicializado');
    }

    // Normaliza as palavras
    word1 = word1.toLowerCase().trim();
    word2 = word2.toLowerCase().trim();

    // Se são a mesma palavra, similaridade máxima
    if (word1 == word2) return 1.0;

    // Verifica se há relação direta entre as palavras
    double directScore = 0.0;

    // Verificar relação word1 -> word2
    if (_wordRelationsCache.containsKey(word1) &&
        _wordRelationsCache[word1]!.containsKey(word2)) {
      directScore = _wordRelationsCache[word1]![word2]!;
    }
    // Verificar relação word2 -> word1
    else if (_wordRelationsCache.containsKey(word2) &&
        _wordRelationsCache[word2]!.containsKey(word1)) {
      directScore = _wordRelationsCache[word2]![word1]!;
    }

    // Se encontrou relação direta com score significativo
    if (directScore > 0.1) {
      // Usar o score direto, com uma pequena influência da similaridade básica
      final basicSimilarity = _calculateBasicSimilarity(word1, word2);
      return (directScore * 0.8) + (basicSimilarity * 0.2);
    }

    // Se não há relação direta, usa similaridade básica
    return _calculateBasicSimilarity(word1, word2);
  }

  /// Calcula similaridade básica entre palavras (fallback)
  double _calculateBasicSimilarity(String word1, String word2) {
    // Similaridade de caracteres (Jaccard)
    final set1 = word1.split('').toSet();
    final set2 = word2.split('').toSet();

    final intersection = set1.intersection(set2).length;
    final union = set1.union(set2).length;

    if (union == 0) return 0.0;

    double similarity = intersection / union;

    // Bônus para palavras com prefixo comum
    if (word1.startsWith(word2) || word2.startsWith(word1)) {
      similarity = (similarity + 0.7) / 2;
    }

    return similarity.clamp(0.01, 0.99);
  }

  /// Adiciona ou atualiza uma palavra com suas relações
  Future<bool> saveWordRelations(String word, Map<String, double> relations) async {
    if (!_isInitialized) await initialize();

    try {
      word = word.toLowerCase().trim();

      // Formata dados para o Firestore
      final Map<String, dynamic> data = {
        'relations': {},
        'updatedAt': FieldValue.serverTimestamp()
      };

      // Adiciona relações com valores validados
      relations.forEach((relatedWord, similarity) {
        // Garante que os valores estão dentro do intervalo válido
        final validSimilarity = similarity.clamp(0.01, 0.99);
        data['relations'][relatedWord.toLowerCase().trim()] = validSimilarity;
      });

      // Salva no Firestore
      await _firestore.collection('words').doc(word).set(data, SetOptions(merge: true));

      // Atualiza o cache local
      if (!_wordRelationsCache.containsKey(word)) {
        _wordRelationsCache[word] = {};
      }

      relations.forEach((relatedWord, similarity) {
        _wordRelationsCache[word]![relatedWord.toLowerCase().trim()] = similarity.clamp(0.01, 0.99);
      });

      if (kDebugMode) {
        print('Firebase Context Service: Palavra "$word" salva com ${relations.length} relações');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase Context Service: ERRO ao salvar palavra "$word": $e');
      }
      return false;
    }
  }

  /// Obtém as relações de uma palavra
  Map<String, double> getWordRelations(String word) {
    word = word.toLowerCase().trim();

    if (_wordRelationsCache.containsKey(word)) {
      return Map<String, double>.from(_wordRelationsCache[word]!);
    }

    return {}; // Retorna mapa vazio se não encontrar
  }

  /// Verifica se uma palavra existe no banco de dados
  Future<bool> wordExists(String word) async {
    if (!_isInitialized) await initialize();

    word = word.toLowerCase().trim();

    try {
      // Verifica primeiro no cache
      if (_wordRelationsCache.containsKey(word)) {
        return true;
      }

      // Se não está no cache, verifica no Firestore
      final doc = await _firestore.collection('words').doc(word).get();
      return doc.exists;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase Context Service: ERRO ao verificar existência da palavra "$word": $e');
      }
      return false;
    }
  }

  /// Adiciona uma relação entre duas palavras
  Future<bool> addRelation(String word1, String word2, double similarity) async {
    if (!_isInitialized) await initialize();

    word1 = word1.toLowerCase().trim();
    word2 = word2.toLowerCase().trim();

    // Garante que a similaridade está no intervalo válido
    similarity = similarity.clamp(0.01, 0.99);

    try {
      // 1. Adiciona relação word1 -> word2
      final relationsMap1 = getWordRelations(word1);
      relationsMap1[word2] = similarity;
      await saveWordRelations(word1, relationsMap1);

      // 2. Adiciona relação word2 -> word1 (bidirecional)
      final relationsMap2 = getWordRelations(word2);
      relationsMap2[word1] = similarity;
      await saveWordRelations(word2, relationsMap2);

      if (kDebugMode) {
        print('Firebase Context Service: Relação adicionada entre "$word1" e "$word2" = $similarity');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase Context Service: ERRO ao adicionar relação: $e');
      }
      return false;
    }
  }

  /// Força atualização dos dados
  Future<void> refresh() async {
    _wordRelationsCache.clear();
    _isInitialized = false;
    await initialize();
  }
}
