// lib/presentation/widgets/new_word_notification.dart
import 'package:contextual/core/constants/color_constants.dart';
import 'package:contextual/presentation/blocs/game/game_bloc.dart';
import 'package:contextual/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Widget que exibe uma notificação quando uma nova palavra do dia está disponível
class NewWordNotification extends StatelessWidget {
  final VoidCallback onRefresh;

  const NewWordNotification({
    Key? key,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(context.responsiveValue(
        small: 12.0,
        medium: 16.0,
        large: 20.0,
      )),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorConstants.primary,
            Color.lerp(ColorConstants.primary, ColorConstants.secondary, 0.6)!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: context.responsiveSize(24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nova palavra disponível!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.responsiveFontSize(16),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Uma nova palavra do dia acaba de ser publicada.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: context.responsiveFontSize(13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // Apenas fecha a notificação sem mudar a palavra
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withOpacity(0.8),
                  ),
                  child: Text(
                    'Depois',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // Fecha a notificação e atualiza para a nova palavra
                    Navigator.of(context).pop();
                    onRefresh();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: ColorConstants.primary,
                  ),
                  child: Text(
                    'Atualizar agora',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(14),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
