// utils/firestore_seeder.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Classe utilitária para inicializar o Firestore com dados de teste
class FirestoreSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton
  static final FirestoreSeeder _instance = FirestoreSeeder._internal();
  factory FirestoreSeeder() => _instance;
  FirestoreSeeder._internal();

  // Flag para evitar execuções duplicadas
  bool _hasSeeded = false;

  /// Inicializa o banco de dados com categorias e contextos básicos
  Future<void> seedFirestore() async {
    if (_hasSeeded) return;

    try {
      if (kDebugMode) {
        print('Iniciando o preenchimento do Firestore...');
      }

      // Verificar se já existem dados
      final categoriesSnapshot = await _firestore.collection('categories').limit(1).get();

      if (categoriesSnapshot.docs.isEmpty) {
        // Não há dados, vamos preencher
        await _seedCategories();
        await _seedContexts();

        if (kDebugMode) {
          print('Firestore preenchido com dados iniciais com sucesso!');
        }
      } else {
        if (kDebugMode) {
          print('Firestore já contém dados. Pulando o preenchimento inicial.');
        }
      }

      _hasSeeded = true;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao preencher o Firestore: $e');
      }
    }
  }

  /// Preenche a coleção de categorias
  Future<void> _seedCategories() async {
    final categoriesToSeed = {
      'esporte': [
        'futebol', 'basquete', 'vôlei', 'natação', 'tênis',
        'corrida', 'atletismo', 'ginástica', 'handebol', 'ciclismo',
        'surfe', 'golfe', 'boxe', 'judô', 'karatê',
        'esqui', 'snowboard', 'patinação', 'remo', 'canoagem'
      ],
      'tecnologia': [
        'computador', 'internet', 'software', 'hardware', 'smartphone',
        'aplicativo', 'programação', 'rede', 'digital', 'algoritmo',
        'dados', 'nuvem', 'inteligência artificial', 'robô', 'automação',
        'website', 'servidor', 'sistema', 'virtual', 'cibernético'
      ],
      'alimento': [
        'arroz', 'feijão', 'carne', 'frango', 'peixe',
        'salada', 'legume', 'verdura', 'fruta', 'sobremesa',
        'pão', 'bolo', 'doce', 'chocolate', 'café',
        'leite', 'queijo', 'ovo', 'manteiga', 'óleo'
      ],
      'animal': [
        'cachorro', 'gato', 'pássaro', 'peixe', 'leão',
        'tigre', 'elefante', 'macaco', 'cobra', 'girafa',
        'urso', 'lobo', 'raposa', 'coelho', 'tartaruga',
        'abelha', 'aranha', 'borboleta', 'mosca', 'mosquito'
      ],
      'profissão': [
        'médico', 'professor', 'engenheiro', 'advogado', 'programador',
        'arquiteto', 'designer', 'jornalista', 'enfermeiro', 'psicólogo',
        'ator', 'músico', 'escritor', 'artista', 'atleta',
        'empresário', 'bombeiro', 'policial', 'juiz', 'cientista'
      ]
    };

    for (final category in categoriesToSeed.keys) {
      await _firestore.collection('categories').doc(category).set({
        'words': categoriesToSeed[category],
        'description': 'Categoria de $category',
        'difficulty': 2
      });

      if (kDebugMode) {
        print('Categoria "$category" adicionada com ${categoriesToSeed[category]!.length} palavras');
      }
    }
  }

  /// Preenche a coleção de contextos semânticos
  Future<void> _seedContexts() async {
    final contextsToSeed = {
      'esporte': {
        'futebol': 0.95,
        'bola': 0.85,
        'jogador': 0.85,
        'time': 0.80,
        'esporte': 1.0,
        'atleta': 0.85,
        'competição': 0.75,
        'jogo': 0.80,
        'campo': 0.70,
        'torcida': 0.65,
        'gol': 0.85,
        'campeonato': 0.80,
        'medalha': 0.70,
        'vitória': 0.65,
        'troféu': 0.70
      },
      'tecnologia': {
        'computador': 0.95,
        'internet': 0.90,
        'software': 0.85,
        'hardware': 0.85,
        'tecnologia': 1.0,
        'programa': 0.80,
        'digital': 0.75,
        'sistema': 0.70,
        'rede': 0.80,
        'dados': 0.70,
        'código': 0.85,
        'programação': 0.90,
        'algoritmo': 0.85,
        'aplicativo': 0.80,
        'virtual': 0.65
      },
      'alimento': {
        'comida': 0.95,
        'alimento': 1.0,
        'refeição': 0.85,
        'ingrediente': 0.75,
        'culinária': 0.80,
        'sabor': 0.70,
        'receita': 0.75,
        'tempero': 0.65,
        'cozinha': 0.70,
        'fome': 0.60,
        'nutrição': 0.75,
        'dieta': 0.65,
        'proteína': 0.70,
        'carboidrato': 0.65,
        'vitamina': 0.60
      },
      'animal': {
        'bicho': 0.90,
        'animal': 1.0,
        'fauna': 0.85,
        'mamífero': 0.80,
        'selvagem': 0.75,
        'doméstico': 0.70,
        'espécie': 0.65,
        'habitat': 0.60,
        'felino': 0.75,
        'canino': 0.75,
        'predador': 0.70,
        'presa': 0.65,
        'extinção': 0.55,
        'conservação': 0.50,
        'zoológico': 0.60
      },
      'profissão': {
        'trabalho': 0.90,
        'carreira': 0.85,
        'ocupação': 0.90,
        'emprego': 0.85,
        'profissão': 1.0,
        'ofício': 0.85,
        'função': 0.75,
        'cargo': 0.80,
        'especialização': 0.75,
        'formação': 0.70,
        'diploma': 0.65,
        'capacitação': 0.70,
        'salário': 0.65,
        'escritório': 0.60,
        'empresa': 0.60
      }
    };

    for (final context in contextsToSeed.keys) {
      await _firestore.collection('contexts').doc(context).set(contextsToSeed[context]!);

      if (kDebugMode) {
        print('Contexto "$context" adicionado com ${contextsToSeed[context]!.length} palavras relacionadas');
      }
    }
  }

  /// Adiciona uma palavra diária para hoje (útil para testes)
  Future<void> addDailyWordForToday(String word, String category) async {
    try {
      // Obtém a data atual no formato YYYY-MM-DD
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      await _firestore.collection('daily_words').doc(dateStr).set({
        'word': word,
        'category': category,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('Palavra do dia adicionada para $dateStr: $word (categoria: $category)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao adicionar palavra do dia: $e');
      }
    }
  }

  /// Limpa todos os dados (cuidado ao usar)
  Future<void> clearAllData() async {
    if (kDebugMode) {
      print('Atenção: Apagando todos os dados do Firestore!');
    }

    try {
      // Limpa as categorias
      final categoriesSnapshot = await _firestore.collection('categories').get();
      for (final doc in categoriesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Limpa os contextos
      final contextsSnapshot = await _firestore.collection('contexts').get();
      for (final doc in contextsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Limpa as palavras diárias
      final dailyWordsSnapshot = await _firestore.collection('daily_words').get();
      for (final doc in dailyWordsSnapshot.docs) {
        await doc.reference.delete();
      }

      if (kDebugMode) {
        print('Todos os dados foram apagados com sucesso.');
      }

      _hasSeeded = false; // Reseta a flag para permitir um novo seeding
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao limpar dados: $e');
      }
    }
  }
}
