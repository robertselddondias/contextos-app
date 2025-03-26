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
import 'package:contextual/services/game_services.dart';
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
  final GameServicesManager _gameServicesManager = GameServicesManager();
  bool _hasShownSuccessDialog = false;
  bool _isGameCenterAvailable = false;

  @override
  void initState() {
    super.initState();
    _initAds();
    _initGameServices();
  }

  Future<void> _initAds() async {
    await _adManager.initialize();
  }

  Future<void> _initGameServices() async {
    final isInitialized = await _gameServicesManager.initialize();
    if (mounted) {
      setState(() {
        _isGameCenterAvailable = isInitialized && _gameServicesManager.isAvailable;
      });
    }
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

            // Submit score to Game Center/Google Play Games when game is completed
            if (_isGameCenterAvailable) {
              _gameServicesManager.processGameWin(state.guesses.length);
            }

            // Show interstitial ad when game is completed
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

            // Use SafeArea for ensuring content is within safe screen area
            return SafeArea(
              child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      children: [
                        // Banner ad at the top (when game not completed)
                        if (!gameState.isCompleted)
                          const AdBannerWidget(isTop: true),

                        // Game header with game information
                        GameHeader(
                          bestScore: gameState.bestScore,
                          currentAttempts: gameState.guesses.length,
                          isCompleted: gameState.isCompleted,
                        ),

                        // Game Center Ranking Button (positioned below header when game is active)
                        if (_isGameCenterAvailable && !gameState.isCompleted)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: _buildGameCenterButton(),
                          ),

                        // Guess list (takes remaining space)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: GuessList(
                              guesses: gameState.guesses,
                              isLoading: state is GameLoading,
                            ),
                          ),
                        ),

                        // Container for buttons and input with scroll if needed
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: constraints.maxHeight * 0.3, // Limit height
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Rewarded ad button when player is stuck
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
                                        // Logic to provide a hint to the user
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

                                // Input field for new guesses
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

                                // Buttons and ads when game is completed
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
                                        // Game Center Ranking Button (prominent placement when game is completed)
                                        if (_isGameCenterAvailable)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 12.0),
                                            child: _buildGameCenterButton(isLarge: true),
                                          ),

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

                                        // Rewarded ad button
                                        RewardedAdButton(
                                          text: 'Palavra extra',
                                          rewardText: 'Você desbloqueou uma palavra extra para hoje!',
                                          icon: Icons.card_giftcard,
                                          onRewarded: () {
                                            // Logic to unlock extra word
                                            context.read<GameBloc>().add(const GameReset());

                                            // Show success message
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

                                        // Banner ad at the bottom when game is completed
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

          // Fallback for unexpected cases
          return const Center(
            child: Text('Algo deu errado. Tente novamente.'),
          );
        },
      ),
    );
  }

  // Game Center/Google Play Games leaderboard button
  Widget _buildGameCenterButton({bool isLarge = false}) {
    return ElevatedButton.icon(
      onPressed: () {
        _gameServicesManager.showLeaderboard();
      },
      icon: Icon(
        Icons.leaderboard,
        size: isLarge ? 24.0 : 20.0,
        color: Colors.white,
      ),
      label: Text(
        'Ver Ranking Global',
        style: TextStyle(
          fontSize: context.responsiveFontSize(isLarge ? 15 : 13),
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorConstants.info,
        padding: EdgeInsets.symmetric(
          vertical: isLarge ? 12.0 : 8.0,
          horizontal: isLarge ? 20.0 : 16.0,
        ),
        minimumSize: isLarge ? Size(double.infinity, 50) : null,
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
                '4. Se a palavra não estiver no contexto semântico, ela será analisada por similaridade linguística, considerando aspectos como coincidência de letras com a palavra secreta.',
                style: TextStyle(fontSize: context.responsiveFontSize(14), fontWeight: FontWeight.bold),
              ),
              SizedBox(height: context.responsiveSize(8)),
              Text(
                '5. Tente acertar com o menor número possível de tentativas!',
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

  // Helper method to get a hint word for rewarded ad
  String _getHintWord(GameLoaded state) {
    // Sort guesses by similarity (highest to lowest)
    if (state.guesses.isEmpty) {
      return "categoria";
    }

    final sortedGuesses = List<Guess>.from(state.guesses)
      ..sort((a, b) => b.similarity.compareTo(a.similarity));

    // Return the closest word as a hint
    if (sortedGuesses.isNotEmpty && sortedGuesses.first.similarity > 0.5) {
      return sortedGuesses.first.word;
    }

    // List of generic related words if there's no good hint
    final genericHints = [
      'objeto', 'conceito', 'animal', 'lugar', 'ação',
      'sentimento', 'natureza', 'tecnologia', 'pessoa',
    ];

    // Return a generic hint
    return genericHints[DateTime.now().microsecond % genericHints.length];
  }
}
