// presentation/widgets/guess_list.dart
import 'package:contextual/domain/entities/guess.dart';
import 'package:contextual/presentation/widgets/guess_item.dart';
import 'package:flutter/material.dart';

class GuessList extends StatelessWidget {
  final List<Guess> guesses;
  final bool isLoading;

  const GuessList({
    super.key,
    required this.guesses,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (guesses.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Use o tamanho mínimo necessário
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.search,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Digite uma palavra para começar!',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Quanto mais próxima do alvo, maior a porcentagem.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Ordenamos as tentativas por similaridade (da maior para a menor)
    final sortedGuesses = List<Guess>.from(guesses)
      ..sort((a, b) => b.similarity.compareTo(a.similarity));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sortedGuesses.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        // Se estamos carregando e é o último item, mostramos um indicador
        if (isLoading && index == sortedGuesses.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final guess = sortedGuesses[index];
        final rank = index + 1;
        final isExactMatch = guess.similarity >= 0.99;

        return GuessItem(
          guess: guess,
          rank: rank,
          isExactMatch: isExactMatch,
        );
      },
    );
  }
}
