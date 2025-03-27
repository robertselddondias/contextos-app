// presentation/widgets/guess_item.dart
import 'package:contextual/core/constants/color_constants.dart';
import 'package:contextual/domain/entities/guess.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GuessItem extends StatelessWidget {
  final Guess guess;
  final int rank;
  final bool isExactMatch;

  const GuessItem({
    super.key,
    required this.guess,
    required this.rank,
    this.isExactMatch = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Cores base
    final similarityColor = ColorConstants.getSimilarityColor(
      guess.similarity,
      darkMode: isDarkMode,
    );
    final textColor = ColorConstants.getSimilarityTextColor(
      guess.similarity,
      darkMode: isDarkMode,
    );

    // Estilo especial para dicas
    final hintColor = isDarkMode
        ? Colors.purple.shade200
        : Colors.purple.shade100;
    final hintTextColor = isDarkMode
        ? Colors.white
        : Colors.black87;

    final gradient = guess.isHint
        ? LinearGradient(
      colors: [hintColor, hintColor.withOpacity(0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    )
        : ColorConstants.getSimilarityGradient(
      guess.similarity,
      darkMode: isDarkMode,
    );

    final percentFormat = NumberFormat.percentPattern();

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      elevation: isExactMatch ? 4 : 2,
      shadowColor: isExactMatch
          ? ColorConstants.success.withOpacity(0.4)
          : Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isExactMatch || guess.isHint
            ? BorderSide(
          color: guess.isHint
              ? Colors.purple
              : ColorConstants.success,
          width: 2,
        )
            : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: gradient,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (guess.isHint ? hintTextColor : textColor).withOpacity(0.15),
              border: Border.all(
                color: (guess.isHint ? hintTextColor : textColor).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    rank.toString(),
                    style: TextStyle(
                      color: guess.isHint ? hintTextColor : textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (guess.isHint)
                    Icon(
                      Icons.lightbulb,
                      size: 14,
                      color: hintTextColor.withOpacity(0.7),
                    ),
                ],
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  _capitalize(guess.word),
                  style: TextStyle(
                    color: guess.isHint ? hintTextColor : textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (guess.isHint ? hintTextColor : textColor).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (guess.isHint ? hintTextColor : textColor).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  guess.isHint
                      ? 'DICA'
                      : percentFormat.format(guess.similarity),
                  style: TextStyle(
                    color: guess.isHint ? hintTextColor : textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Icon(
                  guess.isHint ? Icons.lightbulb_outline : Icons.access_time,
                  size: 14,
                  color: (guess.isHint ? hintTextColor : textColor).withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  guess.isHint
                      ? 'Palavra sugerida'
                      : _getTimeAgoString(guess.timestamp),
                  style: TextStyle(
                    color: (guess.isHint ? hintTextColor : textColor).withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
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

  String _getTimeAgoString(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'agora mesmo';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min atrás';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} h atrás';
    } else {
      final formatter = DateFormat('dd/MM - HH:mm');
      return formatter.format(timestamp);
    }
  }
}
