import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:contextual/core/constants/color_constants.dart';
import 'package:contextual/presentation/blocs/game/game_bloc.dart';
import 'package:contextual/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Usando animações separadas para melhor controle e evitar erros de inicialização
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Inicializando os controllers separadamente
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Configurando as animações
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeOutBack,
      ),
    );

    // Iniciando as animações
    _fadeController.forward();
    _scaleController.forward();

    // Inicializando o jogo e navegando após um delay
    _initializeGameAndNavigate();
  }

  Future<void> _initializeGameAndNavigate() async {
    // Adicionamos um atraso para permitir que as animações sejam exibidas
    await Future.delayed(const Duration(milliseconds: 3000));

    if (!mounted) return;

    // Inicializamos o jogo
    context.read<GameBloc>().add(const GameInitialized());

    // Navegamos para a tela principal
    Navigator.pushReplacementNamed(context, '/game');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? ColorConstants.darkBackground
          : ColorConstants.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: isDarkMode
                ? [
              Color.lerp(ColorConstants.darkBackground, ColorConstants.primary, 0.1)!,
              ColorConstants.darkBackground,
              Color.lerp(ColorConstants.darkBackground, Colors.black, 0.2)!,
            ]
                : [
              Color.lerp(ColorConstants.background, ColorConstants.primary, 0.05)!,
              ColorConstants.background,
              Color.lerp(ColorConstants.background, Colors.white, 0.5)!,
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo ou ícone do aplicativo
                  Hero(
                    tag: 'app_logo',
                    child: _buildLogo(context, isDarkMode),
                  ),

                  SizedBox(height: context.responsiveSize(32)),

                  // Nome do aplicativo
                  _buildAppName(context, isDarkMode),

                  SizedBox(height: context.responsiveSize(24)),

                  // Texto animado
                  _buildAnimatedSubtitle(context, isDarkMode),

                  SizedBox(height: context.responsiveSize(48)),

                  // Indicador de carregamento
                  SizedBox(
                    width: context.responsiveSize(48),
                    height: context.responsiveSize(48),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ColorConstants.primary,
                      ),
                      strokeWidth: context.responsiveValue(
                        small: 2.5,
                        medium: 3.0,
                        large: 3.5,
                      ),
                      backgroundColor: isDarkMode
                          ? ColorConstants.darkSurfaceVariant
                          : ColorConstants.surfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context, bool isDarkMode) {
    // Tamanho responsivo para o logo
    final logoSize = context.responsiveValue(
      small: 100.0,
      medium: 120.0,
      large: 140.0,
    );

    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        color: ColorConstants.primary,
        borderRadius: BorderRadius.circular(logoSize * 0.25),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.primary.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
        gradient: ColorConstants.primaryGradient,
      ),
      child: Center(
        child: Icon(
          Icons.text_fields_rounded,
          size: logoSize * 0.5,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAppName(BuildContext context, bool isDarkMode) {
    return Text(
      'CONTEXTUAL',
      style: TextStyle(
        fontSize: context.responsiveValue(
          small: 32.0,
          medium: 36.0,
          large: 40.0,
        ),
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
        color: ColorConstants.primary,
      ),
    );
  }

  Widget _buildAnimatedSubtitle(BuildContext context, bool isDarkMode) {
    return DefaultTextStyle(
      style: TextStyle(
        letterSpacing: 1,
        fontSize: context.responsiveFontSize(16),
        color: isDarkMode
            ? Colors.white.withOpacity(0.8)
            : ColorConstants.textSecondary,
      ),
      child: AnimatedTextKit(
        animatedTexts: [
          TypewriterAnimatedText(
            'Encontre a palavra secreta',
            speed: const Duration(milliseconds: 100),
          ),
          TypewriterAnimatedText(
            'Use pistas de similaridade',
            speed: const Duration(milliseconds: 100),
          ),
          TypewriterAnimatedText(
            'Desafie seus amigos',
            speed: const Duration(milliseconds: 100),
          ),
        ],
        isRepeatingAnimation: true,
        repeatForever: true,
        pause: const Duration(milliseconds: 1000),
        displayFullTextOnTap: true,
      ),
    );
  }
}
