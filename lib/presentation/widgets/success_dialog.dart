import 'dart:math' as Math;

import 'package:confetti/confetti.dart';
import 'package:contextual/core/constants/color_constants.dart';
import 'package:contextual/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SuccessDialog extends StatefulWidget {
  final String targetWord;
  final int attemptCount;
  final int bestScore;
  final VoidCallback onShare;
  final VoidCallback onClose;

  const SuccessDialog({
    super.key,
    required this.targetWord,
    required this.attemptCount,
    required this.bestScore,
    required this.onShare,
    required this.onClose,
  });

  @override
  State<SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<SuccessDialog> with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  bool _isNewRecord = false;
  String _achievementText = '';

  @override
  void initState() {
    super.initState();

    // Configurar o controlador de confete
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    // Iniciar a animação de confete após um pequeno atraso
    Future.delayed(const Duration(milliseconds: 300), () {
      _confettiController.play();
    });

    // Configurar as animações
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Iniciar as animações
    _animationController.forward();

    // Verificar se é um novo recorde
    _isNewRecord = widget.bestScore == 0 || widget.attemptCount < widget.bestScore;

    // Definir texto baseado no desempenho
    if (_isNewRecord) {
      _achievementText = 'Novo recorde pessoal!';
    } else if (widget.attemptCount <= 3) {
      _achievementText = 'Impressionante!';
    } else if (widget.attemptCount <= 5) {
      _achievementText = 'Muito bom!';
    } else if (widget.attemptCount <= 8) {
      _achievementText = 'Bom trabalho!';
    } else {
      _achievementText = 'Você conseguiu!';
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 12,
          backgroundColor: isDarkMode
              ? ColorConstants.darkSurfaceVariant
              : Colors.white,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value * 0.9 + 0.1,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: child,
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(context.responsiveValue(
                small: 16.0,
                medium: 20.0,
                large: 24.0,
              )),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animação de sucesso
                  _buildSuccessAnimation(context),
                  SizedBox(height: context.responsiveSize(16)),

                  // Título com destaque
                  Text(
                    _achievementText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: context.responsiveFontSize(22),
                      color: _isNewRecord
                          ? Colors.amber[700]
                          : ColorConstants.success,
                      shadows: [
                        Shadow(
                          blurRadius: 8.0,
                          color: (_isNewRecord
                              ? Colors.amber : ColorConstants.success).withOpacity(0.3),
                          offset: const Offset(0, 2.0),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.responsiveSize(16)),

                  // A palavra desvendada com destaque visual
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: context.responsiveSize(16),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          ColorConstants.primary.withOpacity(0.7),
                          ColorConstants.primary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ColorConstants.primary.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'A palavra era',
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(14),
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        SizedBox(height: context.responsiveSize(8)),
                        Text(
                          widget.targetWord.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: context.responsiveFontSize(28),
                            color: Colors.white,
                            letterSpacing: 2.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.responsiveSize(24)),

                  // Estatísticas em cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(
                        context,
                        "Tentativas",
                        widget.attemptCount.toString(),
                        Icons.format_list_numbered,
                        ColorConstants.secondary,
                      ),
                      _buildStatCard(
                        context,
                        "Recorde",
                        _isNewRecord ? "NOVO!" : (widget.bestScore > 0 ? widget.bestScore.toString() : "-"),
                        Icons.emoji_events,
                        _isNewRecord ? Colors.amber : ColorConstants.info,
                      ),
                    ],
                  ),
                  SizedBox(height: context.responsiveSize(24)),

                  // Botões de ação
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onClose,
                          icon: Icon(
                            Icons.close,
                            size: context.responsiveSize(18),
                          ),
                          label: Text(
                            'Fechar',
                            style: TextStyle(
                              fontSize: context.responsiveFontSize(14),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: context.responsiveSize(12),
                            ),
                            side: BorderSide(
                              color: ColorConstants.primary,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: context.responsiveSize(12)),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: widget.onShare,
                          icon: Icon(
                            Icons.share,
                            size: context.responsiveSize(18),
                          ),
                          label: Text(
                            'Compartilhar',
                            style: TextStyle(
                              fontSize: context.responsiveFontSize(14),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConstants.success,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: context.responsiveSize(12),
                            ),
                            elevation: 3,
                            shadowColor: ColorConstants.success.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Posicionamento do confetti
        Positioned(
          top: 0,
          left: MediaQuery.of(context).size.width / 2 - 20,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: -Math.pi / 2, // para cima
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.amber,
              Colors.teal,
            ],
            numberOfParticles: 30,
            gravity: 0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessAnimation(BuildContext context) {
    final size = context.responsiveValue(
        small: 100.0,
        medium: 120.0,
        large: 140.0
    );

    try {
      return Lottie.asset(
        _isNewRecord
            ? 'assets/animations/trophy.json'
            : 'assets/animations/success.json',
        width: size,
        height: size,
        fit: BoxFit.contain,
        repeat: _isNewRecord,
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
        large: 120.0
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _isNewRecord
            ? Colors.amber.withOpacity(0.2)
            : ColorConstants.success.withOpacity(0.2),
      ),
      child: Icon(
        _isNewRecord ? Icons.emoji_events : Icons.check_circle,
        color: _isNewRecord ? Colors.amber : ColorConstants.success,
        size: size * 0.6,
      ),
    );
  }

  Widget _buildStatCard(
      BuildContext context,
      String label,
      String value,
      IconData icon,
      Color color
      ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: context.responsiveValue(
        small: 100.0,
        medium: 120.0,
        large: 140.0,
      ),
      padding: EdgeInsets.all(context.responsiveSize(10)),
      decoration: BoxDecoration(
        color: isDarkMode
            ? color.withOpacity(0.15)
            : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: context.responsiveSize(24),
          ),
          SizedBox(height: context.responsiveSize(4)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: context.responsiveFontSize(20),
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: context.responsiveFontSize(12),
              color: isDarkMode
                  ? Colors.white70
                  : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
