// data/datasources/remote/google_nlp_service.dart
import 'dart:convert';
import 'dart:math';

import 'package:contextual/core/constants/app_constants.dart';
import 'package:contextual/data/datasources/remote/semantic_context_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:googleapis/language/v1.dart' as language_api;
import 'package:googleapis_auth/auth_io.dart';

abstract class GoogleNlpService {
  Future<double> calculateSimilarity(String word1, String word2);
  Future<void> initialize();
}

class GoogleNlpServiceImpl implements GoogleNlpService {
  final Dio _dio;
  language_api.CloudNaturalLanguageApi? _languageApi;
  bool _isInitializing = false;
  bool _isInitialized = false;

  // Instância do serviço de contexto semântico
  final SemanticContextService _contextService = SemanticContextService();

  GoogleNlpServiceImpl(this._dio);

  @override
  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;

    try {
      // Inicializa o serviço de contexto semântico
      await _contextService.initialize();

      if (AppConstants.useGoogleNlp) {
        await _initializeLanguageApi();
      }

      _isInitialized = true;
    } catch (e) {
      print('Erro na inicialização do serviço NLP: $e');
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _initializeLanguageApi() async {
    if (_languageApi != null) return;

    try {
      // Carrega as credenciais do arquivo JSON
      final String jsonString = await rootBundle.loadString(
          AppConstants.googleCredentialsFilePath
      );

      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final credentials = ServiceAccountCredentials.fromJson(jsonMap);

      // Obtém um cliente autenticado
      final client = await clientViaServiceAccount(
          credentials,
          [language_api.CloudNaturalLanguageApi.cloudLanguageScope]
      );

      // Inicializa a API
      _languageApi = language_api.CloudNaturalLanguageApi(client);
    } catch (e) {
      print('Erro ao inicializar a API de linguagem: $e');
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

      // Importante: para o jogo Contexto, a palavra2 é sempre a palavra-alvo
      // Então vamos usar o sistema de contexto semântico para pontuações mais precisas
      double contextualScore = _contextService.calculateContextualSimilarity(word1, word2);

      // Se tivermos uma boa pontuação do contexto semântico, usamos ela com maior peso
      if (contextualScore > 0.3) {
        // Se a pontuação contextual for significativa, podemos retorná-la diretamente
        // ou combiná-la com a API para resultados ainda melhores
        const useOnlyContextual = false; // Configure conforme necessário

        if (useOnlyContextual) {
          return contextualScore;
        }
      }

      // Tenta usar a API do Google NLP se estiver configurada
      if (AppConstants.useGoogleNlp && _languageApi != null) {
        try {
          // Uso da API Natural Language do Google
          final similarity = await _calculateSimilarityWithGoogleNlp(word1, word2);

          // Combina a pontuação da API com o contexto semântico
          return _blendScores(similarity, contextualScore);
        } catch (e) {
          print('Erro ao usar Google NLP API: $e');
          // Em caso de erro, usamos a pontuação contextual
          return contextualScore;
        }
      }

      // Se não usamos API ou ela falhou, usamos apenas a pontuação contextual
      // Se a pontuação contextual for muito baixa, usamos o cálculo local como fallback
      return contextualScore > 0.1 ? contextualScore : _calculateLocalSimilarity(word1, word2);
    } catch (e) {
      print('Erro geral ao calcular similaridade: $e');
      return _calculateLocalSimilarity(word1, word2);
    }
  }

  /// Combina duas pontuações com pesos
  double _blendScores(double apiScore, double contextScore) {
    // Damos mais peso ao contexto semântico para o jogo Contexto
    const apiWeight = 0.3;
    const contextWeight = 0.7;

    return (apiScore * apiWeight) + (contextScore * contextWeight);
  }

  Future<double> _calculateSimilarityWithGoogleNlp(String word1, String word2) async {
    // Análise para a primeira palavra
    final request1 = language_api.AnalyzeEntitiesRequest()
      ..document = (language_api.Document()
        ..content = word1
        ..type = 'PLAIN_TEXT')
      ..encodingType = 'UTF8';

    // Análise para a segunda palavra
    final request2 = language_api.AnalyzeEntitiesRequest()
      ..document = (language_api.Document()
        ..content = word2
        ..type = 'PLAIN_TEXT')
      ..encodingType = 'UTF8';

    // Executa as análises
    final response1 = await _languageApi!.documents.analyzeEntities(request1);
    final response2 = await _languageApi!.documents.analyzeEntities(request2);

    // Se uma das palavras não tem entidades, tenta análise de sentimento
    if ((response1.entities == null || response1.entities!.isEmpty) ||
        (response2.entities == null || response2.entities!.isEmpty)) {
      return await _calculateSimilarityWithSentiment(word1, word2);
    }

    // Cria vetores de características com base nas entidades
    final vector1 = _createFeatureVector(response1);
    final vector2 = _createFeatureVector(response2);

    // Calcula similaridade de cosseno entre os vetores
    return _calculateCosineSimilarity(vector1, vector2);
  }

  Future<double> _calculateSimilarityWithSentiment(String word1, String word2) async {
    try {
      // Análise de sentimento para as palavras
      final sentimentRequest1 = language_api.AnalyzeSentimentRequest()
        ..document = (language_api.Document()
          ..content = word1
          ..type = 'PLAIN_TEXT')
        ..encodingType = 'UTF8';

      final sentimentRequest2 = language_api.AnalyzeSentimentRequest()
        ..document = (language_api.Document()
          ..content = word2
          ..type = 'PLAIN_TEXT')
        ..encodingType = 'UTF8';

      final sentimentResponse1 = await _languageApi!.documents.analyzeSentiment(sentimentRequest1);
      final sentimentResponse2 = await _languageApi!.documents.analyzeSentiment(sentimentRequest2);

      // Compara sentimentos
      if (sentimentResponse1.documentSentiment != null &&
          sentimentResponse2.documentSentiment != null) {

        final score1 = sentimentResponse1.documentSentiment!.score ?? 0;
        final magnitude1 = sentimentResponse1.documentSentiment!.magnitude ?? 0;

        final score2 = sentimentResponse2.documentSentiment!.score ?? 0;
        final magnitude2 = sentimentResponse2.documentSentiment!.magnitude ?? 0;

        // Cálculo simplificado de similaridade baseado em sentimento
        final scoreDiff = (score1 - score2).abs();
        final magnitudeDiff = (magnitude1 - magnitude2).abs();

        // Normaliza as diferenças
        final similarity = 1 - ((scoreDiff + magnitudeDiff) / 4);

        return similarity.clamp(0.1, 0.9); // Limitamos o intervalo para evitar extremos
      }
    } catch (e) {
      print('Erro na análise de sentimento: $e');
    }

    // Se tudo falhar, voltamos para o método local
    return _calculateLocalSimilarity(word1, word2);
  }

  Map<String, double> _createFeatureVector(language_api.AnalyzeEntitiesResponse response) {
    final vector = <String, double>{};

    // Adiciona entidades ao vetor
    if (response.entities != null) {
      for (final entity in response.entities!) {
        final key = 'entity_${entity.name}';
        vector[key] = entity.salience ?? 0.5;

        // Adiciona tipos de entidade como características adicionais
        if (entity.type != null) {
          final typeKey = 'type_${entity.type}';
          vector[typeKey] = (vector[typeKey] ?? 0.0) + (entity.salience ?? 0.5);
        }
      }
    }

    return vector;
  }

  double _calculateCosineSimilarity(Map<String, double> vec1, Map<String, double> vec2) {
    // Encontre todas as chaves únicas
    final allKeys = {...vec1.keys, ...vec2.keys};

    // Calcule o produto escalar
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (final key in allKeys) {
      final v1 = vec1[key] ?? 0.0;
      final v2 = vec2[key] ?? 0.0;

      dotProduct += v1 * v2;
      norm1 += v1 * v1;
      norm2 += v2 * v2;
    }

    // Evite divisão por zero
    if (norm1 == 0 || norm2 == 0) return 0.1; // Valor baixo mas não zero

    // Calcule a similaridade de cosseno
    final similarity = dotProduct / (sqrt(norm1) * sqrt(norm2));

    // Normalize para o intervalo [0, 1]
    return ((similarity + 1) / 2).clamp(0.01, 0.99);
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

    // Ajuste semântico para relações comuns em português
    // (Exemplos simples, em um app real isto seria mais complexo)
    if (_areRelatedWords(word1, word2)) {
      similarity = (similarity + 0.7) / 2;
    }

    // Limite para não ter similaridade exatamente 1.0 (reservado para palavras idênticas)
    return similarity.clamp(0.01, 0.99);
  }

  /// Verifica se duas palavras têm relação semântica conhecida
  /// (simplificado, em um app real seria uma base de dados maior)
  bool _areRelatedWords(String word1, String word2) {
    final relatedPairs = {
      'gato': ['felino', 'animal', 'cachorro', 'pet', 'animal de estimação'],
      'cachorro': ['canino', 'animal', 'gato', 'pet', 'animal de estimação'],
      'casa': ['lar', 'moradia', 'residência', 'apartamento'],
      'carro': ['veículo', 'automóvel', 'transporte', 'moto'],
      'livro': ['leitura', 'revista', 'publicação', 'texto'],
      'computador': ['tecnologia', 'notebook', 'laptop', 'pc', 'eletrônico'],
      'comida': ['alimento', 'refeição', 'almoço', 'jantar', 'café da manhã'],
      // Palavras relacionadas a esportes
      'esporte': ['futebol', 'basquete', 'vôlei', 'corrida', 'natação', 'atletismo'],
      'futebol': ['bola', 'gol', 'campo', 'jogador', 'time', 'torcida', 'esporte'],
      'basquete': ['cesta', 'quadra', 'jogador', 'time', 'esporte'],
      // Palavras relacionadas a tecnologia
      'tecnologia': ['computador', 'internet', 'software', 'hardware', 'programação'],
      'internet': ['web', 'site', 'rede', 'conexão', 'tecnologia'],
      // Palavras relacionadas a alimentos
      'alimento': ['comida', 'refeição', 'fruta', 'legume', 'proteína'],
      'fruta': ['maçã', 'banana', 'laranja', 'alimento', 'comida'],
    };

    // Verifica em ambas as direções
    if (relatedPairs.containsKey(word1) && relatedPairs[word1]!.contains(word2)) {
      return true;
    }

    if (relatedPairs.containsKey(word2) && relatedPairs[word2]!.contains(word1)) {
      return true;
    }

    return false;
  }
}
