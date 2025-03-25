import 'package:contextual/core/constants/color_constants.dart';
import 'package:contextual/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  bool isLastPage = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Área principal do PageView (expansível)
            Expanded(
              child: PageView(
                controller: controller,
                onPageChanged: (index) {
                  setState(() {
                    isLastPage = index == 3;
                  });
                },
                children: [
                  _buildPage(
                    title: 'Bem-vindo ao Contexto',
                    description: 'Um jogo desafiador onde você precisa adivinhar a palavra do dia usando pistas de proximidade semântica.',
                    icon: Icons.lightbulb,
                    iconColor: ColorConstants.primary,
                  ),
                  _buildPage(
                    title: 'Como Jogar',
                    description: 'Digite palavras e receba uma porcentagem que indica o quão próximo você está da palavra secreta.',
                    icon: Icons.keyboard,
                    iconColor: ColorConstants.secondary,
                  ),
                  _buildPage(
                    title: 'Use as Pistas',
                    description: 'Quanto maior a porcentagem, mais próximo você está. Tente encontrar palavras semanticamente similares.',
                    icon: Icons.tips_and_updates,
                    iconColor: Colors.amber,
                  ),
                  _buildPage(
                    title: 'Está Pronto?',
                    description: 'Desafie-se para acertar com o menor número de tentativas possível e compartilhe seus resultados!',
                    icon: Icons.emoji_events,
                    iconColor: ColorConstants.success,
                  ),
                ],
              ),
            ),

            // Área de navegação inferior
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.responsiveValue(
                  small: 16.0,
                  medium: 20.0,
                  large: 24.0,
                ),
                vertical: context.responsiveValue(
                  small: 16.0,
                  medium: 20.0,
                  large: 24.0,
                ),
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: isLastPage
                  ? _buildGetStartedButton()
                  : _buildNavigationControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () => controller.jumpToPage(3),
          child: Text(
            'PULAR',
            style: TextStyle(
              color: ColorConstants.textSecondary,
              fontSize: context.responsiveFontSize(13),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Center(
          child: SmoothPageIndicator(
            controller: controller,
            count: 4,
            effect: WormEffect(
              spacing: context.responsiveValue(
                small: 12.0,
                medium: 16.0,
                large: 20.0,
              ),
              dotHeight: context.responsiveSize(8),
              dotWidth: context.responsiveSize(8),
              dotColor: Colors.grey.shade300,
              activeDotColor: ColorConstants.primary,
            ),
            onDotClicked: (index) => controller.animateToPage(
              index,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            ),
          ),
        ),
        TextButton(
          onPressed: () => controller.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          ),
          child: Text(
            'PRÓXIMO',
            style: TextStyle(
              color: ColorConstants.primary,
              fontSize: context.responsiveFontSize(13),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGetStartedButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: ColorConstants.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.responsiveSize(12)),
          ),
          padding: EdgeInsets.symmetric(
            vertical: context.responsiveValue(
              small: 12.0,
              medium: 16.0,
              large: 20.0,
            ),
          ),
          elevation: 3,
        ),
        onPressed: () async {
          // Salvar que o onboarding foi concluído
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('showedOnboarding', true);

          // Navegar para a tela principal
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/splash');
          }
        },
        child: Text(
          'COMEÇAR A JOGAR',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: context.responsiveFontSize(15),
          ),
        ),
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsiveValue(
          small: 24.0,
          medium: 32.0,
          large: 40.0,
        ),
        vertical: context.responsiveValue(
          small: 16.0,
          medium: 24.0,
          large: 32.0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone com tamanho responsivo
          Container(
            width: context.responsiveValue(
              small: 120.0,
              medium: 150.0,
              large: 180.0,
            ),
            height: context.responsiveValue(
              small: 120.0,
              medium: 150.0,
              large: 180.0,
            ),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: context.responsiveValue(
                small: 60.0,
                medium: 80.0,
                large: 100.0,
              ),
              color: iconColor,
            ),
          ),

          SizedBox(height: context.responsiveSize(40)),

          // Título
          Text(
            title,
            style: TextStyle(
              color: ColorConstants.textPrimary,
              fontSize: context.responsiveFontSize(24),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: context.responsiveSize(20)),

          // Descrição
          Text(
            description,
            style: TextStyle(
              color: ColorConstants.textSecondary,
              fontSize: context.responsiveFontSize(15),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
