import 'package:contextual/core/constants/color_constants.dart';
import 'package:contextual/domain/entities/guess.dart';
import 'package:contextual/presentation/blocs/game/game_bloc.dart';
import 'package:contextual/presentation/widgets/ad_banner_widget.dart';
import 'package:contextual/presentation/widgets/game_header.dart';
import 'package:contextual/presentation/widgets/guess_input.dart';
import 'package:contextual/presentation/widgets/guess_list.dart';
import 'package:contextual/presentation/widgets/loading_indicator.dart';
import 'package:contextual/presentation/widgets/rewarded_ad_button.dart';
import 'package:contextual/presentation/widgets/success_dialog.dart';
import 'package:contextual/services/ad_manager.dart';
import 'package:contextual/utils/responsive_utils.dart';
import 'package:contextual/utils/share_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final TextEditingController _guessController = TextEditingController();
  final AdManager _adManager = AdManager();
  bool _hasShownSuccessDialog = false;

  @override
  void initState() {
    super.initState();
    _initAds();
  }

  Future<void> _initAds() async {
    await _adManager.initialize();
  }

  @override
  void dispose() {
    _guessController.dispose();
    _adManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Contextual',
          style: TextStyle(
            fontSize: context.responsiveFontSize(20),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
            iconSize: context.responsiveSize(24),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            iconSize: context.responsiveSize(24),
          ),
        ],
      ),
      body: BlocConsumer<GameBloc, GameState>(
        listener: (context, state) {
          if (state is GameError) {
            _showErrorSnackBar(context, state.message);
          }

          if (state is GameLoaded && state.isCompleted && !_hasShownSuccessDialog) {
            _showSuccessDialog(context, state);
            _hasShownSuccessDialog = true;

            // Mostrar anúncio intersticial quando o jogo for completado
            _adManager.notifyGameCompleted();
          }
        },
        builder: (context, state) {
          if (state is GameInitial) {
            return const LoadingIndicator(message: 'Inicializando jogo...');
          }

          if (state is GameLoading && state.previousState == null) {
            return const LoadingIndicator(message: 'Carregando...');
          }

          if (state is GameLoaded || (state is GameLoading && state.previousState is GameLoaded)) {
            final gameState = state is GameLoaded ? state : (state as GameLoading).previousState as GameLoaded;

            // Use SafeArea para garantir que o conteúdo está dentro da área segura da tela
            return SafeArea(
              child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      children: [
                        // Banner de anúncio no topo
                        if (!gameState.isCompleted)
                          const AdBannerWidget(isTop: true),

                        // Cabeçalho com informações do jogo
                        GameHeader(
                          bestScore: gameState.bestScore,
                          currentAttempts: gameState.guesses.length,
                          isCompleted: gameState.isCompleted,
                        ),

                        // Lista de tentativas
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: GuessList(
                              guesses: gameState.guesses,
                              isLoading: state is GameLoading,
                            ),
                          ),
                        ),

                        // Container para botões e input com scroll se necessário
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: constraints.maxHeight * 0.3, // Limite a altura
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Botão de anúncio recompensado quando o jogador está travado
                                if (!gameState.isCompleted && gameState.guesses.isNotEmpty && gameState.guesses.length >= 5)
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: context.responsiveValue(
                                        small: 12.0,
                                        medium: 16.0,
                                        large: 20.0,
                                      ),
                                      vertical: 4.0,
                                    ),
                                    child: RewardedAdButton(
                                      text: 'Obter uma dica',
                                      rewardText: 'Dica: uma palavra semelhante à palavra-alvo é "${_getHintWord(gameState)}"',
                                      icon: Icons.lightbulb_outline,
                                      onRewarded: () {
                                        // Lógica para conceder uma dica ao usuário
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Dica: Uma palavra próxima é "${_getHintWord(gameState)}"',
                                              style: TextStyle(fontSize: context.responsiveFontSize(14)),
                                            ),
                                            backgroundColor: ColorConstants.info,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                // Campo de entrada para novas tentativas
                                if (!gameState.isCompleted)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: GuessInput(
                                      controller: _guessController,
                                      isLoading: state is GameLoading,
                                      onSubmitted: (guess) {
                                        if (guess.trim().isNotEmpty) {
                                          FocusScope.of(context).unfocus();
                                          context.read<GameBloc>().add(GuessSubmitted(guess.trim()));
                                          _guessController.clear();
                                        }
                                      },
                                    ),
                                  ),

                                // Botões e anúncios quando o jogo é completado
                                if (gameState.isCompleted)
                                  Padding(
                                    padding: EdgeInsets.all(context.responsiveValue(
                                      small: 8.0,
                                      medium: 12.0,
                                      large: 16.0,
                                    )),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () => _shareResults(context, gameState),
                                          icon: Icon(Icons.share, size: context.responsiveSize(18)),
                                          label: Text(
                                            'Compartilhar Resultados',
                                            style: TextStyle(fontSize: context.responsiveFontSize(14)),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: ColorConstants.success,
                                            foregroundColor: Colors.white,
                                            minimumSize: Size(double.infinity, context.responsiveSize(50)),
                                          ),
                                        ),

                                        SizedBox(height: context.responsiveValue(
                                          small: 8.0,
                                          medium: 12.0,
                                          large: 16.0,
                                        )),

                                        // Botão para anúncios recompensados
                                        RewardedAdButton(
                                          text: 'Palavra extra',
                                          rewardText: 'Você desbloqueou uma palavra extra para hoje!',
                                          icon: Icons.card_giftcard,
                                          onRewarded: () {
                                            // Lógica para desbloquear palavra extra
                                            context.read<GameBloc>().add(const GameReset());

                                            // Exibir mensagem de sucesso
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Você desbloqueou uma palavra extra para hoje!',
                                                  style: TextStyle(fontSize: context.responsiveFontSize(14)),
                                                ),
                                                backgroundColor: ColorConstants.success,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          },
                                        ),

                                        // Banner no fundo da tela quando o jogo for completado
                                        SizedBox(height: context.responsiveValue(
                                          small: 8.0,
                                          medium: 12.0,
                                          large: 16.0,
                                        )),
                                        const AdBannerWidget(isTop: false),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }
              ),
            );
          }

          // Fallback para casos inesperados
          return const Center(
            child: Text('Algo deu errado. Tente novamente.'),
          );
        },
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontSize: context.responsiveFontSize(14)),
        ),
        backgroundColor: ColorConstants.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Como Jogar',
          style: TextStyle(
            fontSize: context.responsiveFontSize(18),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tente adivinhar a palavra secreta do dia!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: context.responsiveFontSize(15),
                ),
              ),
              SizedBox(height: context.responsiveSize(16)),
              Text(
                '1. Digite uma palavra e veja quão próxima ela está da palavra-alvo.',
                style: TextStyle(fontSize: context.responsiveFontSize(14)),
              ),
              SizedBox(height: context.responsiveSize(8)),
              Text(
                '2. A porcentagem indica a proximidade semântica entre sua palavra e a palavra-alvo.',
                style: TextStyle(fontSize: context.responsiveFontSize(14)),
              ),
              SizedBox(height: context.responsiveSize(8)),
              Text(
                '3. Use as dicas para se aproximar da palavra certa.',
                style: TextStyle(fontSize: context.responsiveFontSize(14)),
              ),
              SizedBox(height: context.responsiveSize(8)),
              Text(
                '4. Tente acertar com o menor número possível de tentativas!',
                style: TextStyle(fontSize: context.responsiveFontSize(14)),
              ),
              SizedBox(height: context.responsiveSize(16)),
              Text(
                'Exemplo:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: context.responsiveFontSize(15),
                ),
              ),
              SizedBox(height: context.responsiveSize(8)),
              Text(
                'Se a palavra-alvo for "cachorro" e você digitar "gato", a similaridade pode ser cerca de 70%.',
                style: TextStyle(fontSize: context.responsiveFontSize(14)),
              ),
              SizedBox(height: context.responsiveSize(8)),
              Text(
                'Se você digitar "animal", a similaridade pode ser cerca de 50%.',
                style: TextStyle(fontSize: context.responsiveFontSize(14)),
              ),
              SizedBox(height: context.responsiveSize(8)),
              Text(
                'A palavra exata terá 100% de similaridade.',
                style: TextStyle(fontSize: context.responsiveFontSize(14)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(fontSize: context.responsiveFontSize(14)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, GameLoaded state) {
    Future.delayed(const Duration(milliseconds: 500), () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => SuccessDialog(
          targetWord: state.targetWord,
          attemptCount: state.guesses.length,
          bestScore: state.bestScore,
          onShare: () {
            Navigator.of(context).pop();
            _shareResults(context, state);
          },
          onClose: () => Navigator.of(context).pop(),
        ),
      );
    });
  }

  void _shareResults(BuildContext context, GameLoaded state) {
    context.read<GameBloc>().add(const GameShared());

    final shareText = context.read<GameBloc>().generateShareText();

    ShareHelper.shareResults(
      context: context,
      shareText: shareText,
    );
  }

  // Método auxiliar para obter uma dica para o anúncio recompensado
  String _getHintWord(GameLoaded state) {
    // Ordena as tentativas por similaridade (da maior para a menor)
    if (state.guesses.isEmpty) {
      return "categoria";
    }

    final sortedGuesses = List<Guess>.from(state.guesses)
      ..sort((a, b) => b.similarity.compareTo(a.similarity));

    // Retorna a palavra mais próxima como dica
    if (sortedGuesses.isNotEmpty && sortedGuesses.first.similarity > 0.5) {
      return sortedGuesses.first.word;
    }

    // Lista de palavras relacionadas genéricas caso não tenha uma boa dica
    final genericHints = [
      'objeto', 'conceito', 'animal', 'lugar', 'ação',
      'sentimento', 'natureza', 'tecnologia', 'pessoa',
    ];

    // Retorna uma dica genérica
    return genericHints[DateTime.now().microsecond % genericHints.length];
  }
}
