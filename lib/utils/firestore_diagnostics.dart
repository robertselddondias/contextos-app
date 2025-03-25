// utils/firestore_diagnostics.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Classe para diagnóstico de problemas com o Firestore
class FirestoreDiagnostics {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton
  static final FirestoreDiagnostics _instance = FirestoreDiagnostics._internal();
  factory FirestoreDiagnostics() => _instance;
  FirestoreDiagnostics._internal();

  /// Executa um diagnóstico completo do Firestore
  Future<Map<String, dynamic>> runDiagnostics() async {
    final results = <String, dynamic>{};

    if (kDebugMode) {
      print('Iniciando diagnóstico do Firestore...');
    }

    try {
      // Verifica a inicialização do Firebase
      results['firebase_initialized'] = Firebase.apps.isNotEmpty;
      if (kDebugMode) {
        print('Firebase inicializado: ${results['firebase_initialized']}');
      }

      if (!results['firebase_initialized']) {
        return results;
      }

      // Verifica a conexão com o Firestore
      try {
        final testDoc = await _firestore.collection('_diagnostics_').doc('test').set({
          'timestamp': FieldValue.serverTimestamp(),
          'client': 'diagnostic_tool'
        });
        results['firestore_connection'] = true;
        if (kDebugMode) {
          print('Conexão com o Firestore: SUCESSO');
        }
      } catch (e) {
        results['firestore_connection'] = false;
        results['firestore_error'] = e.toString();
        if (kDebugMode) {
          print('Conexão com o Firestore: FALHA - $e');
        }
        return results;
      }

      // Verifica as coleções existentes
      final collections = ['categories', 'contexts', 'daily_words', 'user_scores'];
      results['collections'] = {};

      for (final collection in collections) {
        try {
          final snapshot = await _firestore.collection(collection).limit(1).get();
          results['collections'][collection] = {
            'exists': true,
            'empty': snapshot.docs.isEmpty,
            'count': snapshot.docs.isEmpty ? 0 : await _countDocuments(collection),
          };
          if (kDebugMode) {
            print('Coleção "$collection": ${snapshot.docs.isEmpty ? "VAZIA" : "${results['collections'][collection]['count']} documento(s)"}');
          }
        } catch (e) {
          results['collections'][collection] = {
            'exists': false,
            'error': e.toString()
          };
          if (kDebugMode) {
            print('Coleção "$collection": ERRO - $e');
          }
        }
      }

      // Verifica uma categoria específica para diagnóstico detalhado
      try {
        if (results['collections']['categories']['count'] > 0) {
          final categoriesSnapshot = await _firestore.collection('categories').get();
          final sampleCategory = categoriesSnapshot.docs.first.id;
          final categoryData = categoriesSnapshot.docs.first.data();

          results['sample_category'] = {
            'name': sampleCategory,
            'has_words_field': categoryData.containsKey('words'),
            'words_is_array': categoryData.containsKey('words') && categoryData['words'] is List,
            'word_count': categoryData.containsKey('words') && categoryData['words'] is List
                ? (categoryData['words'] as List).length
                : 0,
          };

          if (kDebugMode) {
            print('Categoria de exemplo: "$sampleCategory"');
            print('- Tem campo "words": ${results['sample_category']['has_words_field']}');
            print('- Campo "words" é array: ${results['sample_category']['words_is_array']}');
            print('- Quantidade de palavras: ${results['sample_category']['word_count']}');

            if (results['sample_category']['words_is_array'] && results['sample_category']['word_count'] > 0) {
              final words = List<String>.from(categoryData['words']);
              print('- Primeiras 5 palavras: ${words.take(5).join(", ")}...');
            }
          }
        }
      } catch (e) {
        results['sample_category_error'] = e.toString();
        if (kDebugMode) {
          print('Erro ao analisar categoria de exemplo: $e');
        }
      }

      // Verifica um contexto específico para diagnóstico detalhado
      try {
        if (results['collections']['contexts']['count'] > 0) {
          final contextsSnapshot = await _firestore.collection('contexts').get();
          final sampleContext = contextsSnapshot.docs.first.id;
          final contextData = contextsSnapshot.docs.first.data();

          results['sample_context'] = {
            'name': sampleContext,
            'field_count': contextData.length,
            'sample_words': {},
          };

          // Pega algumas palavras de exemplo e suas pontuações
          int count = 0;
          contextData.forEach((word, value) {
            if (count < 5 && value is num) {
              results['sample_context']['sample_words'][word] = value;
              count++;
            }
          });

          if (kDebugMode) {
            print('Contexto de exemplo: "$sampleContext"');
            print('- Quantidade de campos: ${results['sample_context']['field_count']}');

            if (results['sample_context']['field_count'] > 0) {
              print('- Palavras de exemplo:');
              results['sample_context']['sample_words'].forEach((word, value) {
                print('  - $word: $value');
              });
            }
          }
        }
      } catch (e) {
        results['sample_context_error'] = e.toString();
        if (kDebugMode) {
          print('Erro ao analisar contexto de exemplo: $e');
        }
      }

      // Verifica a permissão de escrita
      try {
        final testDocRef = _firestore.collection('_diagnostics_').doc('write_test');
        await testDocRef.set({'timestamp': FieldValue.serverTimestamp()});
        await testDocRef.delete();
        results['write_permission'] = true;
        if (kDebugMode) {
          print('Permissão de escrita: OK');
        }
      } catch (e) {
        results['write_permission'] = false;
        results['write_error'] = e.toString();
        if (kDebugMode) {
          print('Permissão de escrita: FALHA - $e');
        }
      }

      // Conclui o diagnóstico
      if (kDebugMode) {
        print('Diagnóstico do Firestore concluído.');
      }

      return results;
    } catch (e) {
      results['general_error'] = e.toString();
      if (kDebugMode) {
        print('Erro geral no diagnóstico: $e');
      }
      return results;
    }
  }

  /// Conta o número de documentos em uma coleção
  Future<int> _countDocuments(String collectionPath) async {
    try {
      // Não existe uma função direta para contar documentos no Firestore
      // Podemos usar um truque agregando em lotes pequenos
      final snapshot = await _firestore.collection(collectionPath).limit(1000).get();
      return snapshot.docs.length;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao contar documentos na coleção $collectionPath: $e');
      }
      return 0;
    }
  }

  /// Verifica se existe pelo menos um documento na coleção
  Future<bool> collectionHasDocuments(String collectionPath) async {
    try {
      final snapshot = await _firestore.collection(collectionPath).limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao verificar documentos na coleção $collectionPath: $e');
      }
      return false;
    }
  }

  /// Verifica se os documentos na coleção têm o formato esperado
  Future<bool> verifyCollectionStructure(String collectionPath, List<String> requiredFields) async {
    try {
      final snapshot = await _firestore.collection(collectionPath).limit(1).get();
      if (snapshot.docs.isEmpty) {
        return false;
      }

      final docData = snapshot.docs.first.data();
      for (final field in requiredFields) {
        if (!docData.containsKey(field)) {
          if (kDebugMode) {
            print('Campo obrigatório "$field" não encontrado na coleção $collectionPath');
          }
          return false;
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao verificar estrutura da coleção $collectionPath: $e');
      }
      return false;
    }
  }

  /// Executa o diagnóstico e fornece recomendações baseadas nos resultados
  Future<String> getDiagnosticReport() async {
    final results = await runDiagnostics();
    final buffer = StringBuffer();

    buffer.writeln('===== RELATÓRIO DE DIAGNÓSTICO DO FIRESTORE =====');
    buffer.writeln('Data: ${DateTime.now()}');
    buffer.writeln();

    // Verifica a inicialização do Firebase
    buffer.writeln('1. INICIALIZAÇÃO DO FIREBASE');
    buffer.writeln('   Status: ${results['firebase_initialized'] ? "OK" : "FALHA"}');
    if (!results['firebase_initialized']) {
      buffer.writeln('   RECOMENDAÇÃO: Verifique se o Firebase foi inicializado corretamente em main.dart');
      return buffer.toString();
    }
    buffer.writeln();

    // Verifica a conexão com o Firestore
    buffer.writeln('2. CONEXÃO COM O FIRESTORE');
    buffer.writeln('   Status: ${results['firestore_connection'] ? "OK" : "FALHA"}');
    if (!results['firestore_connection']) {
      buffer.writeln('   Erro: ${results['firestore_error']}');
      buffer.writeln('   RECOMENDAÇÃO: Verifique sua conexão com a internet e as configurações do Firebase');
      return buffer.toString();
    }
    buffer.writeln();

    // Analisa as coleções
    buffer.writeln('3. COLEÇÕES DO FIRESTORE');

    bool collectionsOk = true;
    List<String> emptyCollections = [];

    results['collections'].forEach((collection, info) {
      buffer.writeln('   $collection: ${info['exists'] ? (info['empty'] ? "VAZIA" : "${info['count']} documento(s)") : "ERRO"}');

      if (info['exists'] && info['empty'] && (collection == 'categories' || collection == 'contexts')) {
        collectionsOk = false;
        emptyCollections.add(collection);
      }
    });

    if (!collectionsOk) {
      buffer.writeln();
      buffer.writeln('   PROBLEMA: As seguintes coleções importantes estão vazias: ${emptyCollections.join(", ")}');
      buffer.writeln('   RECOMENDAÇÃO: Execute FirestoreSeeder().seedFirestore() para preencher os dados iniciais');
    }
    buffer.writeln();

    // Verifica a estrutura das categorias
    if (results.containsKey('sample_category')) {
      buffer.writeln('4. ESTRUTURA DE CATEGORIAS');

      final categoryInfo = results['sample_category'];
      final categoryOk = categoryInfo['has_words_field'] &&
          categoryInfo['words_is_array'] &&
          categoryInfo['word_count'] > 0;

      buffer.writeln('   Categoria de exemplo: ${categoryInfo['name']}');
      buffer.writeln('   Tem campo "words": ${categoryInfo['has_words_field'] ? "SIM" : "NÃO"}');
      buffer.writeln('   Campo "words" é array: ${categoryInfo['words_is_array'] ? "SIM" : "NÃO"}');
      buffer.writeln('   Quantidade de palavras: ${categoryInfo['word_count']}');

      if (!categoryOk) {
        buffer.writeln();
        buffer.writeln('   PROBLEMA: A estrutura das categorias não está no formato esperado');
        buffer.writeln('   RECOMENDAÇÃO: Verifique se as categorias têm o campo "words" com um array de strings');
      }
    }
    buffer.writeln();

    // Verifica a estrutura dos contextos
    if (results.containsKey('sample_context')) {
      buffer.writeln('5. ESTRUTURA DE CONTEXTOS');

      final contextInfo = results['sample_context'];
      final contextOk = contextInfo['field_count'] > 0;

      buffer.writeln('   Contexto de exemplo: ${contextInfo['name']}');
      buffer.writeln('   Quantidade de campos: ${contextInfo['field_count']}');

      if (!contextOk) {
        buffer.writeln();
        buffer.writeln('   PROBLEMA: A estrutura dos contextos não está no formato esperado');
        buffer.writeln('   RECOMENDAÇÃO: Verifique se os contextos têm campos no formato "palavra": valorNumérico');
      }
    }
    buffer.writeln();

    // Verifica permissões de escrita
    buffer.writeln('6. PERMISSÕES DE ESCRITA');
    buffer.writeln('   Status: ${results['write_permission'] ? "OK" : "FALHA"}');
    if (!results['write_permission']) {
      buffer.writeln('   Erro: ${results['write_error']}');
      buffer.writeln('   RECOMENDAÇÃO: Verifique as regras de segurança do Firestore');
    }
    buffer.writeln();

    // Conclusão e recomendações finais
    buffer.writeln('===== CONCLUSÃO =====');

    if (!collectionsOk || results.containsKey('general_error')) {
      buffer.writeln('O diagnóstico encontrou problemas que precisam ser corrigidos.');
      buffer.writeln();
      buffer.writeln('Ações recomendadas:');

      if (emptyCollections.isNotEmpty) {
        buffer.writeln('1. Execute o seguinte código para preencher os dados iniciais:');
        buffer.writeln('   await FirestoreSeeder().seedFirestore();');
      }

      if (results.containsKey('general_error')) {
        buffer.writeln('2. Verifique o erro geral: ${results['general_error']}');
      }
    } else {
      buffer.writeln('Nenhum problema crítico foi detectado no Firestore.');

      // Sugestões de otimização
      buffer.writeln();
      buffer.writeln('Sugestões de otimização:');
      buffer.writeln('1. Configure índices compostos para consultas frequentes.');
      buffer.writeln('2. Implemente cache local para reduzir consultas ao Firestore.');
      buffer.writeln('3. Considere habilitar persistência offline para melhor experiência do usuário.');
    }

    return buffer.toString();
  }

  /// Executa o diagnóstico e tenta corrigir problemas automaticamente
  Future<bool> diagnoseAndFix() async {
    if (kDebugMode) {
      print('Executando diagnóstico e tentando corrigir problemas...');
    }

    final results = await runDiagnostics();

    // Verifica se há problemas críticos
    if (!results['firebase_initialized'] || !results['firestore_connection']) {
      if (kDebugMode) {
        print('Problemas críticos detectados que não podem ser corrigidos automaticamente:');
        if (!results['firebase_initialized']) print('- Firebase não inicializado');
        if (!results['firestore_connection']) print('- Sem conexão com o Firestore');
      }
      return false;
    }

    // Verifica se as coleções essenciais estão vazias
    bool needsSeeding = false;

    if (results['collections']['categories']['empty'] ||
        results['collections']['contexts']['empty']) {
      needsSeeding = true;
      if (kDebugMode) {
        print('Coleções essenciais estão vazias. Recomendação: execute FirestoreSeeder().seedFirestore()');
      }
    }

    return !needsSeeding;
  }
}
