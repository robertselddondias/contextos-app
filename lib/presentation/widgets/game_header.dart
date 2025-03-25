// presentation/widgets/game_header.dart
import 'package:contextual/core/constants/color_constants.dart';
import 'package:flutter/material.dart';

class GameHeader extends StatelessWidget {
  final int bestScore;
  final int currentAttempts;
  final bool isCompleted;

  const GameHeader({
    super.key,
    required this.bestScore,
    required this.currentAttempts,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? ColorConstants.darkSurfaceVariant
            : ColorConstants.surfaceVariant,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Mensagem principal
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isCompleted
                  ? ColorConstants.success.withOpacity(0.1)
                  : ColorConstants.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCompleted
                    ? ColorConstants.success.withOpacity(0.3)
                    : ColorConstants.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.lightbulb,
                  size: 20,
                  color: isCompleted
                      ? ColorConstants.success
                      : ColorConstants.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isCompleted
                      ? 'Palavra encontrada!'
                      : 'Encontre a palavra do dia',
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? ColorConstants.success
                        : ColorConstants.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Estatísticas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatistic(
                context,
                'Recorde',
                bestScore > 0 ? bestScore.toString() : "-",
                Icons.emoji_events,
                Colors.amber,
                isDarkMode,
              ),
              _buildDivider(isDarkMode),
              _buildStatistic(
                context,
                'Tentativas',
                currentAttempts.toString(),
                Icons.format_list_numbered,
                isCompleted
                    ? ColorConstants.success
                    : ColorConstants.secondary,
                isDarkMode,
              ),
              _buildDivider(isDarkMode),
              _buildStatistic(
                context,
                'Status',
                isCompleted ? 'Completo' : 'Em progresso',
                isCompleted ? Icons.task_alt : Icons.hourglass_top,
                isCompleted
                    ? ColorConstants.success
                    : ColorConstants.info,
                isDarkMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatistic(
      BuildContext context,
      String label,
      String value,
      IconData icon,
      Color color,
      bool isDarkMode,
      ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : ColorConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            color: isDarkMode
                ? Colors.white.withOpacity(0.7)
                : ColorConstants.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Container(
      height: 40,
      width: 1,
      color: isDarkMode
          ? Colors.white.withOpacity(0.1)
          : Colors.black.withOpacity(0.1),
    );
  }
}
