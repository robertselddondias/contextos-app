// lib/presentation/dialogs/new_word_dialog.dart
import 'package:contextual/core/constants/color_constants.dart';
import 'package:contextual/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class NewWordDialog extends StatelessWidget {
  final VoidCallback onContinue;

  const NewWordDialog({
    Key? key,
    required this.onContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 12,
      backgroundColor: isDarkMode
          ? ColorConstants.darkSurfaceVariant
          : Colors.white,
      child: Container(
        padding: EdgeInsets.all(context.responsiveValue(
          small: 16.0,
          medium: 20.0,
          large: 24.0,
        )),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animação/Ícone
            _buildAnimation(context),
            SizedBox(height: context.responsiveSize(16)),

            // Título
            Text(
              'Nova Palavra do Dia!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: context.responsiveFontSize(22),
                color: ColorConstants.primary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.responsiveSize(16)),

            // Descrição
            Text(
              'Uma nova palavra está disponível para você adivinhar hoje! Prepare-se para um novo desafio.',
              style: TextStyle(
                fontSize: context.responsiveFontSize(15),
                color: isDarkMode
                    ? Colors.white.withOpacity(0.9)
                    : Colors.black.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.responsiveSize(24)),

            // Botão de continuar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: context.responsiveValue(
                      small: 12.0,
                      medium: 16.0,
                      large: 20.0,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'COMEÇAR',
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(16),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimation(BuildContext context) {
    final size = context.responsiveValue(
      small: 100.0,
      medium: 120.0,
      large: 140.0,
    );

    try {
      return Lottie.asset(
        'assets/animations/new_word.json',
        width: size,
        height: size,
        fit: BoxFit.contain,
        repeat: true,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackIcon(context);
        },
      );
    } catch (e) {
      return _buildFallbackIcon(context);
    }
  }

  Widget _buildFallbackIcon(BuildContext context) {
    final size = context.responsiveValue(
      small: 80.0,
      medium: 100.0,
      large: 120.0,
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorConstants.primary.withOpacity(0.2),
      ),
      child: Icon(
        Icons.auto_awesome,
        color: ColorConstants.primary,
        size: size * 0.6,
      ),
    );
  }
}
