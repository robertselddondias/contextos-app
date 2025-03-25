// presentation/screens/word_relation_diagnostic_screen.dart
import 'package:contextual/core/init/initialize_firestore.dart';
import 'package:contextual/data/datasources/remote/firebase_context_service.dart';
import 'package:flutter/material.dart';

class WordRelationDiagnosticScreen extends StatefulWidget {
  const WordRelationDiagnosticScreen({super.key});

  @override
  State<WordRelationDiagnosticScreen> createState() => _WordRelationDiagnosticScreenState();
}

class _WordRelationDiagnosticScreenState extends State<WordRelationDiagnosticScreen> {
  final FirebaseContextService _contextService = FirebaseContextService();
  final WordRelationSeeder _seeder = WordRelationSeeder();

  bool _isLoading = false;
  String _statusMessage = 'Inicialize o serviço para começar';

  // Campos para consulta de similaridade
  final TextEditingController _word1Controller = TextEditingController();
  final TextEditingController _word2Controller = TextEditingController();
  double _similarityResult = 0.0;
  bool _hasTestedSimilarity = false;

  // Campos para adicionar relação
  final TextEditingController _addWord1Controller = TextEditingController();
  final TextEditingController _addWord2Controller = TextEditingController();
  final TextEditingController _similarityController = TextEditingController(text: '0.80');

  // Campos para visualizar relações
  final TextEditingController _viewWordController = TextEditingController();
  Map<String, double> _wordRelations = {};
  bool _hasLoadedRelations = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _word1Controller.dispose();
    _word2Controller.dispose();
    _addWord1Controller.dispose();
    _addWord2Controller.dispose();
    _similarityController.dispose();
    _viewWordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico de Relações de Palavras'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status e botões de ação
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: $_statusMessage',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isLoading ? Colors.orange : Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _initializeService,
                            child: const Text('Inicializar Serviço'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _populateBasicWords,
                            child: const Text('Popular Palavras Básicas'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Testar similaridade
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Testar Similaridade Entre Palavras',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _word1Controller,
                            decoration: const InputDecoration(
                              labelText: 'Palavra 1',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _word2Controller,
                            decoration: const InputDecoration(
                              labelText: 'Palavra 2',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _testSimilarity,
                            child: const Text('Calcular Similaridade'),
                          ),
                        ),
                      ],
                    ),
                    if (_hasTestedSimilarity) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Similaridade: ${(_similarityResult * 100).toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _getSimilarityColor(_similarityResult),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Adicionar relação
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Adicionar Relação Entre Palavras',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _addWord1Controller,
                            decoration: const InputDecoration(
                              labelText: 'Palavra 1',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _addWord2Controller,
                            decoration: const InputDecoration(
                              labelText: 'Palavra 2',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _similarityController,
                      decoration: const InputDecoration(
                        labelText: 'Similaridade (0.01 a 0.99)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _addRelation,
                            child: const Text('Adicionar Relação'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Visualizar relações
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Visualizar Relações de uma Palavra',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _viewWordController,
                            decoration: const InputDecoration(
                              labelText: 'Palavra',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _loadWordRelations,
                          child: const Text('Carregar'),
                        ),
                      ],
                    ),
                    if (_hasLoadedRelations) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Relações para "${_viewWordController.text}" (${_wordRelations.length}):',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _wordRelations.isEmpty
                          ? const Text('Nenhuma relação encontrada.')
                          : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _wordRelations.length,
                        itemBuilder: (context, index) {
                          final entry = _wordRelations.entries.elementAt(index);
                          return ListTile(
                            dense: true,
                            title: Text(entry.key),
                            trailing: Text(
                              '${(entry.value * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _getSimilarityColor(entry.value),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Inicializa o serviço
  Future<void> _initializeService() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Inicializando serviço...';
    });

    try {
      await _contextService.initialize();

      setState(() {
        _isLoading = false;
        _statusMessage = 'Serviço inicializado com sucesso';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Erro ao inicializar: $e';
      });
    }
  }

  // Popula palavras básicas
  Future<void> _populateBasicWords() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Populando palavras básicas...';
    });

    try {
      final success = await _seeder.seedBasicWords();

      setState(() {
        _isLoading = false;
        _statusMessage = success
            ? 'Palavras básicas populadas com sucesso'
            : 'Erro ao popular palavras básicas';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Erro ao popular palavras: $e';
      });
    }
  }

  // Testa similaridade entre palavras
  Future<void> _testSimilarity() async {
    if (_word1Controller.text.isEmpty || _word2Controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preencha ambas as palavras'))
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Calculando similaridade...';
    });

    try {
      final similarity = await _seeder.testSimilarity(
          _word1Controller.text,
          _word2Controller.text
      );

      setState(() {
        _isLoading = false;
        _similarityResult = similarity;
        _hasTestedSimilarity = true;
        _statusMessage = 'Similaridade calculada';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Erro ao calcular similaridade: $e';
      });
    }
  }

  // Adiciona relação entre palavras
  Future<void> _addRelation() async {
    if (_addWord1Controller.text.isEmpty || _addWord2Controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preencha ambas as palavras'))
      );
      return;
    }

    try {
      double similarity = double.tryParse(_similarityController.text) ?? 0.8;
      similarity = similarity.clamp(0.01, 0.99);

      setState(() {
        _isLoading = true;
        _statusMessage = 'Adicionando relação...';
      });

      final success = await _contextService.addRelation(
          _addWord1Controller.text,
          _addWord2Controller.text,
          similarity
      );

      setState(() {
        _isLoading = false;
        _statusMessage = success
            ? 'Relação adicionada com sucesso'
            : 'Erro ao adicionar relação';
      });

      if (success) {
        _addWord1Controller.clear();
        _addWord2Controller.clear();
        _similarityController.text = '0.80';
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Erro ao adicionar relação: $e';
      });
    }
  }

  // Carrega relações de uma palavra
  Future<void> _loadWordRelations() async {
    if (_viewWordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Digite uma palavra'))
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Carregando relações...';
    });

    try {
      final relations = _contextService.getWordRelations(_viewWordController.text);

      setState(() {
        _isLoading = false;
        _wordRelations = Map<String, double>.from(relations);
        _hasLoadedRelations = true;
        _statusMessage = 'Relações carregadas';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Erro ao carregar relações: $e';
      });
    }
  }

  // Retorna cor baseada na similaridade
  Color _getSimilarityColor(double similarity) {
    if (similarity >= 0.8) return Colors.green;
    if (similarity >= 0.6) return Colors.teal;
    if (similarity >= 0.4) return Colors.blue;
    if (similarity >= 0.2) return Colors.orange;
    return Colors.red;
  }
}
