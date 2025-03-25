// data/datasources/remote/firebase_nlp_service.dart
import 'dart:math';

import 'package:contextual/data/datasources/remote/firebase_context_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

abstract class NlpService {
  Future<double> calculateSimilarity(String word1, String word2);
  Future<void> initialize();
}

class FirebaseNlpService implements NlpService {
  final Dio _dio;
  bool _isInitializing = false;
  bool _isInitialized = false;

  // Serviço de contexto do Firebase
  late FirebaseContextService _contextService;

  FirebaseNlpService(this._dio) {
    _contextService = GetIt.instance<FirebaseContextService>();
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;

    try {
      // Inicializa o serviço de contexto do Firebase
      await _contextService.initialize();

      _isInitialized = true;

      if (kDebugMode) {
        print('FirebaseNlpService inicializado com sucesso');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro na inicialização do serviço NLP: $e');
      }
    } finally {
      _isInitializing = false;
    }
  }

  @override
  Future<double> calculateSimilarity(String word1, String word2) async {
    try {
      // Assegura que o serviço está inicializado
      if (!_isInitialized) {
        await initialize();
      }

      // Se as palavras são iguais, a similaridade é máxima
      if (word1.toLowerCase() == word2.toLowerCase()) {
        return 1.0;
      }

      // Obtém a similaridade do serviço de contexto
      double contextualScore = _contextService.calculateSimilarity(word1, word2);

      // Se a pontuação contextual for significativa, podemos usá-la diretamente
      if (contextualScore > 0.4) {
        return contextualScore;
      }

      // Caso contrário, combinamos com o cálculo local para dar mais variação
      final localSimilarity = _calculateLocalSimilarity(word1, word2);

      // Combinação ponderada entre similaridade local e contextual
      final combinedScore = (localSimilarity * 0.3) + (contextualScore * 0.7);

      return combinedScore;
    } catch (e) {
      if (kDebugMode) {
        print('Erro geral ao calcular similaridade: $e');
      }
      return _calculateLocalSimilarity(word1, word2);
    }
  }

  /// Calcula uma similaridade local baseada em características das palavras.
  /// Este é um fallback quando a API não está disponível.
  double _calculateLocalSimilarity(String word1, String word2) {
    // Normaliza as palavras
    word1 = word1.toLowerCase().trim();
    word2 = word2.toLowerCase().trim();

    // Se são a mesma palavra, similaridade máxima
    if (word1 == word2) return 1.0;

    // Diferentes fatores para calcular similaridade

    // 1. Similaridade de Jaccard (baseada em caracteres)
    final set1 = word1.split('').toSet();
    final set2 = word2.split('').toSet();

    final union = set1.union(set2);
    final intersection = set1.intersection(set2);

    if (union.isEmpty) return 0.0;

    final charSimilarity = intersection.length / union.length;

    // 2. Similaridade de prefixo
    int prefixLength = 0;
    for (int i = 0; i < min(word1.length, word2.length); i++) {
      if (word1[i] == word2[i]) {
        prefixLength++;
      } else {
        break;
      }
    }

    final prefixSimilarity = prefixLength > 0
        ? prefixLength / max(word1.length, word2.length)
        : 0.0;

    // 3. Similaridade de comprimento
    final lengthSimilarity = 1.0 - ((word1.length - word2.length).abs() /
        max(word1.length, word2.length));

    // 4. Fator aleatório para simular variações semânticas (para palavras fixas,
    // isso dará sempre o mesmo resultado para o mesmo par de palavras)
    final random = Random(
        word1.codeUnits.reduce((a, b) => a + b) +
            word2.codeUnits.reduce((a, b) => a + b)
    );

    final randomFactor = random.nextDouble() * 0.3; // máximo de 30% de variação

    // Combinação de métricas (com pesos)
    const charWeight = 0.4;
    const prefixWeight = 0.3;
    const lengthWeight = 0.2;
    const randomWeight = 0.1;

    double similarity = (charSimilarity * charWeight) +
        (prefixSimilarity * prefixWeight) +
        (lengthSimilarity * lengthWeight) +
        (randomFactor * randomWeight);

    // Ajuste baseado na distância de Levenshtein (edição) - simplificado
    // Se as palavras começam igual mas uma é extensão da outra (ex: "gato" e "gatinho")
    if (word1.startsWith(word2) || word2.startsWith(word1)) {
      similarity = (similarity + 0.8) / 2; // Bonificação para extensões
    }

    // Limite para não ter similaridade exatamente 1.0 (reservado para palavras idênticas)
    return similarity.clamp(0.01, 0.99);
  }

  /// Força uma atualização dos dados e configurações
  Future<void> refreshData() async {
    await _contextService.refresh();
  }
}
