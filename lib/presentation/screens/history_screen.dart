// presentation/screens/history_screen.dart
import 'package:contextual/core/constants/color_constants.dart';
import 'package:contextual/data/models/game_state.dart';
import 'package:contextual/domain/repositories/game_repository.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  GameStateModel? _currentGame;

  @override
  void initState() {
    super.initState();
    _loadGameState();
  }

  Future<void> _loadGameState() async {
    try {
      final gameRepository = GetIt.I<GameRepository>();
      final result = await gameRepository.getGameState();

      setState(() {
        _isLoading = false;
        result.fold(
              (failure) => _currentGame = null,
              (gameState) => _currentGame = gameState,
        );
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentGame = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildHistoryContent(),
    );
  }

  Widget _buildHistoryContent() {
    if (_currentGame == null) {
      return const Center(
        child: Text('Nenhum histórico disponível'),
      );
    }

    // Ordenamos as tentativas por data (da mais recente para a mais antiga)
    final sortedGuesses = List.from(_currentGame!.guesses)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Column(
      children: [
        // Cabeçalho com informações do jogo atual
        _buildGameHeader(),

        // Lista de tentativas
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sortedGuesses.length,
            itemBuilder: (context, index) {
              final guess = sortedGuesses[index];
              final isExactMatch = guess.word.toLowerCase() == _currentGame!.targetWord.toLowerCase();

              return _buildGuessHistoryItem(
                guess: guess,
                index: index + 1,
                isExactMatch: isExactMatch,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGameHeader() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final lastGuessDate = _currentGame!.guesses.isNotEmpty
        ? dateFormat.format(_currentGame!.guesses.last.timestamp)
        : 'N/A';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Palavra do dia: ${_currentGame!.isCompleted ? _currentGame!.targetWord.toUpperCase() : "???"}',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Data: $lastGuessDate'),
              Text('Tentativas: ${_currentGame!.guesses.length}'),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _currentGame!.isCompleted ? 1.0 :
            (_currentGame!.guesses.isEmpty ? 0.0 :
            _currentGame!.guesses.map((g) => g.similarity).reduce((a, b) => a > b ? a : b)),
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _currentGame!.isCompleted
                  ? ColorConstants.success
                  : ColorConstants.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuessHistoryItem({
    required dynamic guess,
    required int index,
    required bool isExactMatch,
  }) {
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('dd/MM');
    final formattedTime = timeFormat.format(guess.timestamp);
    final formattedDate = dateFormat.format(guess.timestamp);

    final percentFormat = NumberFormat.percentPattern();
    final similarityColor = ColorConstants.getSimilarityColor(guess.similarity);
    final textColor = ColorConstants.getSimilarityTextColor(guess.similarity);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      elevation: isExactMatch ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isExactMatch
            ? const BorderSide(
          color: ColorConstants.success,
          width: 2,
        )
            : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: similarityColor.withOpacity(0.8),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: textColor.withOpacity(0.1),
            child: Text(
              index.toString(),
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            _capitalize(guess.word),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '$formattedTime - $formattedDate',
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              percentFormat.format(guess.similarity),
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
