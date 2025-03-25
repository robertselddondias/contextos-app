// data/datasources/remote/semantic_context_service.dart
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

/// Serviço responsável por gerenciar os contextos semânticos das palavras
class SemanticContextService {
  // Singleton
  static final SemanticContextService _instance = SemanticContextService._internal();
  factory SemanticContextService() => _instance;
  SemanticContextService._internal();

  // Mapa de contextos - cada palavra-chave mapeia para um conjunto de palavras relacionadas
  Map<String, Map<String, double>> _contextMap = {};

  // Conjuntos de palavras por categoria
  Map<String, Set<String>> _categoryWords = {};

  // Categorias possíveis
  final List<String> _categories = [
    'esporte', 'tecnologia', 'alimento', 'animal', 'profissão',
    'objeto', 'lugar', 'sentimento', 'corpo', 'natureza', 'arte',
    'transporte', 'educação', 'família', 'saúde'
  ];

  // Flag para verificar se foi inicializado
  bool _isInitialized = false;

  // Inicialização
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadContextData();
      await _loadCategoryData();
      _isInitialized = true;
    } catch (e) {
      print('Erro ao inicializar o serviço de contexto: $e');
      _initializeBasicContexts();
      _initializeBasicCategories();
      _isInitialized = true;
    }
  }

  // Carrega dados de contexto do arquivo JSON
  Future<void> _loadContextData() async {
    try {
      final String jsonData = await rootBundle.loadString('assets/words/word_contexts.json');
      final Map<String, dynamic> data = json.decode(jsonData);

      data.forEach((key, value) {
        if (value is Map) {
          _contextMap[key] = Map<String, double>.from(
              value.map((k, v) => MapEntry(k, v is num ? v.toDouble() : 0.5))
          );
        }
      });
    } catch (e) {
      print('Erro ao carregar dados de contexto: $e');
      // Inicializa com alguns exemplos básicos
      _initializeBasicContexts();
    }
  }

  // Carrega palavras por categoria
  Future<void> _loadCategoryData() async {
    try {
      final String jsonData = await rootBundle.loadString('assets/words/word_categories.json');
      final Map<String, dynamic> data = json.decode(jsonData);

      data.forEach((category, words) {
        if (words is List) {
          _categoryWords[category] = Set<String>.from(words.map((w) => w as String));
        }
      });
    } catch (e) {
      print('Erro ao carregar categorias: $e');
      // Inicializa algumas categorias básicas
      _initializeBasicCategories();
    }
  }

  // Inicializa contextos básicos caso o arquivo não esteja disponível
  void _initializeBasicContexts() {
    print('Inicializando contextos básicos');

    // Contexto para "esporte"
    _contextMap['esporte'] = {
      'futebol': 0.9, 'bola': 0.8, 'tênis': 0.85, 'atleta': 0.9, 'corrida': 0.8,
      'treino': 0.7, 'competição': 0.85, 'jogo': 0.8, 'equipe': 0.75, 'time': 0.75,
      'clube': 0.7, 'torcida': 0.65, 'olimpíada': 0.8, 'medalha': 0.7, 'técnico': 0.75,
      'arbitragem': 0.7, 'campeonato': 0.85, 'quadra': 0.7, 'campo': 0.7, 'ginástica': 0.8,
      'natação': 0.8, 'basquete': 0.85, 'vôlei': 0.85, 'golfe': 0.8, 'maratona': 0.8
    };

    // Contexto para "tecnologia"
    _contextMap['tecnologia'] = {
      'computador': 0.9, 'internet': 0.85, 'software': 0.9, 'hardware': 0.9, 'programa': 0.8,
      'aplicativo': 0.85, 'celular': 0.8, 'smartphone': 0.85, 'rede': 0.8, 'digital': 0.8,
      'inteligência': 0.75, 'artificial': 0.75, 'robô': 0.8, 'sistema': 0.7, 'dados': 0.8,
      'algoritmo': 0.9, 'programação': 0.9, 'inovação': 0.75, 'virtual': 0.8, 'eletrônico': 0.85
    };

    // Contexto para "alimento"
    _contextMap['alimento'] = {
      'comida': 0.9, 'refeição': 0.85, 'nutrição': 0.8, 'fruta': 0.8, 'verdura': 0.8,
      'carne': 0.85, 'peixe': 0.8, 'grão': 0.75, 'cereal': 0.8, 'pão': 0.8,
      'arroz': 0.8, 'feijão': 0.8, 'massa': 0.75, 'macarrão': 0.75, 'sopa': 0.7,
      'sobremesa': 0.7, 'bebida': 0.7, 'saudável': 0.6, 'gostoso': 0.6, 'sabor': 0.75
    };

    // Contexto para "animal"
    _contextMap['animal'] = {
      'cachorro': 0.9, 'gato': 0.9, 'peixe': 0.85, 'pássaro': 0.85, 'ave': 0.8,
      'mamífero': 0.8, 'réptil': 0.8, 'inseto': 0.75, 'selvagem': 0.7, 'doméstico': 0.7,
      'felino': 0.85, 'canino': 0.85, 'aquático': 0.7, 'terrestre': 0.7, 'voador': 0.7,
      'leão': 0.8, 'tigre': 0.8, 'elefante': 0.8, 'girafa': 0.8, 'macaco': 0.8
    };
  }

  // Inicializa categorias básicas
  void _initializeBasicCategories() {
    print('Inicializando categorias básicas');

    _categoryWords = {
      'esporte': {
        'futebol', 'tênis', 'basquete', 'vôlei', 'natação', 'corrida', 'atletismo',
        'golfe', 'surfe', 'esqui', 'boxe', 'judô', 'ginástica', 'ciclismo', 'handebol'
      },
      'tecnologia': {
        'computador', 'internet', 'software', 'hardware', 'aplicativo', 'celular',
        'smartphone', 'algoritmo', 'rede', 'programação', 'robô', 'sistema', 'digital'
      },
      'alimento': {
        'arroz', 'feijão', 'carne', 'salada', 'fruta', 'verdura', 'legume', 'pão',
        'leite', 'queijo', 'ovo', 'massa', 'sopa', 'sobremesa', 'bebida', 'água'
      },
      'animal': {
        'cachorro', 'gato', 'pássaro', 'peixe', 'leão', 'tigre', 'elefante', 'girafa',
        'macaco', 'urso', 'cobra', 'tartaruga', 'inseto', 'aranha', 'borboleta', 'abelha'
      }
    };
  }

  /// Determina a categoria mais provável de uma palavra
  String detectCategory(String word) {
    if (!_isInitialized) {
      print('AVISO: SemanticContextService não inicializado');
      _initializeBasicContexts();
      _initializeBasicCategories();
      _isInitialized = true;
    }

    word = word.toLowerCase();

    // Verifica se a palavra está diretamente em alguma categoria
    for (final category in _categoryWords.keys) {
      if (_categoryWords[category]!.contains(word)) {
        return category;
      }
    }

    // Verifica se a palavra é uma categoria em si
    if (_categories.contains(word)) {
      return word;
    }

    // Verifica se há um contexto específico para esta palavra
    if (_contextMap.containsKey(word)) {
      return word;
    }

    // Caso contrário, tenta inferir baseado em correspondências parciais
    String bestCategory = 'geral';
    double highestScore = 0;

    for (final category in _categories) {
      if (_categoryWords.containsKey(category)) {
        // Calcula um score baseado na similaridade de caracteres e padrões
        double score = _calculateBasicSimilarity(word, category);

        // Verifica se a palavra tem alguma relação conhecida com palavras desta categoria
        for (final categoryWord in _categoryWords[category]!) {
          double wordSim = _calculateBasicSimilarity(word, categoryWord);
          if (wordSim > 0.7) {
            score += wordSim * 0.5; // Booster para palavras relacionadas
          }
        }

        if (score > highestScore) {
          highestScore = score;
          bestCategory = category;
        }
      }
    }

    return bestCategory;
  }

  /// Calcula similaridade contextual entre duas palavras
  double calculateContextualSimilarity(String word, String targetWord) {
    if (!_isInitialized) {
      print('AVISO: SemanticContextService não inicializado');
      _initializeBasicContexts();
      _initializeBasicCategories();
      _isInitialized = true;
    }

    // Se as palavras são iguais, similaridade máxima
    if (word.toLowerCase() == targetWord.toLowerCase()) {
      return 1.0;
    }

    word = word.toLowerCase();
    targetWord = targetWord.toLowerCase();

    // Determina o contexto/categoria da palavra-alvo
    final targetCategory = detectCategory(targetWord);

    // 1. Verifica se ambas as palavras estão na mesma categoria
    bool sameCategory = false;
    if (_categoryWords.containsKey(targetCategory)) {
      sameCategory = _categoryWords[targetCategory]!.contains(word);
    }

    // 2. Verifica contexto específico
    double contextScore = 0.0;
    if (_contextMap.containsKey(targetCategory)) {
      contextScore = _contextMap[targetCategory]![word] ?? 0.0;
    }

    // 3. Calcula similaridade básica
    double basicSimilarity = _calculateBasicSimilarity(word, targetWord);

    // 4. Calcula pontuação final com pesos
    double finalScore;

    if (contextScore > 0) {
      // Se temos uma pontuação de contexto definida, damos muito peso a ela
      finalScore = (contextScore * 0.7) + (basicSimilarity * 0.3);
    } else if (sameCategory) {
      // Se estão na mesma categoria, mas sem pontuação específica, aumentamos a similaridade
      finalScore = basicSimilarity * 1.5;
      if (finalScore > 0.95) finalScore = 0.95; // Cap para não ser igual a palavras idênticas
    } else {
      // Caso normal, usamos a similaridade básica
      finalScore = basicSimilarity;
    }

    return finalScore.clamp(0.01, 0.99);
  }

  /// Calcula similaridade básica entre palavras
  double _calculateBasicSimilarity(String word1, String word2) {
    // Normaliza as palavras
    word1 = word1.toLowerCase().trim();
    word2 = word2.toLowerCase().trim();

    // Se são a mesma palavra, similaridade máxima
    if (word1 == word2) return 1.0;

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

    // Combinação de métricas (com pesos)
    const charWeight = 0.5;
    const prefixWeight = 0.3;
    const lengthWeight = 0.2;

    return (charSimilarity * charWeight) +
        (prefixSimilarity * prefixWeight) +
        (lengthSimilarity * lengthWeight);
  }

  /// Adiciona ou atualiza uma relação de contexto
  void updateContextRelation(String category, String word, double score) {
    if (!_contextMap.containsKey(category)) {
      _contextMap[category] = {};
    }

    _contextMap[category]![word] = score.clamp(0.0, 1.0);
  }

  /// Adiciona uma palavra a uma categoria
  void addWordToCategory(String category, String word) {
    if (!_categoryWords.containsKey(category)) {
      _categoryWords[category] = {};
    }

    _categoryWords[category]!.add(word.toLowerCase());
  }

  /// Verifica se a categoria existe
  bool hasCategory(String category) {
    return _categoryWords.containsKey(category.toLowerCase());
  }

  /// Obtém todas as categorias disponíveis
  List<String> getAvailableCategories() {
    return _categoryWords.keys.toList();
  }

  /// Obtém todas as palavras de uma categoria
  List<String> getWordsInCategory(String category) {
    if (!_categoryWords.containsKey(category)) {
      return [];
    }

    return _categoryWords[category]!.toList();
  }

  /// Obtém o mapa de contexto para uma categoria
  Map<String, double> getContextMap(String category) {
    return _contextMap[category] ?? {};
  }

  /// Imprime informações de diagnóstico sobre o serviço
  void printDiagnostics() {
    print('=== SemanticContextService Diagnóstico ===');
    print('Inicializado: $_isInitialized');
    print('Categorias: ${_categoryWords.keys.join(', ')}');
    print('Contextos: ${_contextMap.keys.join(', ')}');
    print('Palavras em "esporte": ${_categoryWords['esporte']?.take(10).join(', ') ?? 'N/A'}...');
    print('Palavras em "tecnologia": ${_categoryWords['tecnologia']?.take(10).join(', ') ?? 'N/A'}...');
    print('================================');
  }
}
