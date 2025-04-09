import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'dart:math';
import 'dart:math' as math;

import 'package:get/get.dart';

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

  // Método auxiliar para obter uma dica para o anúncio recompensado
  Future<String?> _getAvailableHintWord(GameLoaded state) async {
    try {
      // Referência ao Firestore
      final firestore = FirebaseFirestore.instance;

      // Busca a palavra na coleção de words para obter suas relações
      final wordDoc = await firestore.collection('words').doc(
          state.targetWord.toLowerCase()).get();

      if (wordDoc.exists && wordDoc.data() != null &&
          wordDoc.data()!.containsKey('relations')) {
        // Obtém as relações da palavra alvo
        final relations = wordDoc.data()!['relations'] as Map<String, dynamic>;

        if (relations.isNotEmpty) {
          // Converte para uma lista de entradas (palavra, similaridade)
          final relationsList = relations.entries.toList();

          // Ordena pela similaridade (do maior para o menor)
          relationsList.sort((a, b) =>
              (b.value as num).compareTo(a.value as num));

          // Filtra para não retornar palavras que o usuário já tentou
          final usedWords = state.guesses
              .map((g) => g.word.toLowerCase())
              .toSet();
          final availableHints = relationsList.where((entry) =>
          !usedWords.contains(entry.key) && (entry.value as num) > 0.6)
              .toList();

          // Se temos dicas disponíveis, retorna uma aleatoriamente entre as top 3
          if (availableHints.isNotEmpty) {
            final random = Random();
            final topIndex = random.nextInt(math.min(3, availableHints.length));
            return availableHints[topIndex].key;
          }
        }
      }

      // Fallback para o método antigo se não conseguir encontrar uma relação
      // Ordena as tentativas por similaridade (da maior para a menor)
      if (state.guesses.isEmpty) {
        return null;
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
      final genericHint = genericHints[DateTime
          .now()
          .microsecond % genericHints.length];

      // Verifica se a dica genérica já foi tentada
      if (state.guesses.any((g) => g.word.toLowerCase() == genericHint)) {
        return null;
      }

      return genericHint;
    } catch (e) {
      print('Erro ao buscar dica: $e');
      // Retorna null em caso de erro
      return null;
    }
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

          if (state is GameLoaded && state.isCompleted &&
              !_hasShownSuccessDialog) {
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

          if (state is GameLoaded ||
              (state is GameLoading && state.previousState is GameLoaded)) {
            final gameState = state is GameLoaded
                ? state
                : (state as GameLoading).previousState as GameLoaded;

            // Usamos LayoutBuilder para garantir layout responsivo
            return LayoutBuilder(
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

                    // Lista de tentativas (com maior prioridade)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: GuessList(
                          guesses: gameState.guesses,
                          isLoading: state is GameLoading,
                        ),
                      ),
                    ),

                    // Container com altura máxima para conteúdo responsivo
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: constraints.maxHeight * 0.35, // Limita a 35% da altura
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FutureBuilder<String?>(
                              future: _getAvailableHintWord(gameState),
                              builder: (context, snapshot) {
                                // Se não há dica disponível, retorna um SizedBox vazio
                                if (!snapshot.hasData ||
                                    snapshot.data == null ||
                                    snapshot.data!.isEmpty ||
                                    !gameState.guesses.isNotEmpty ||
                                    gameState.guesses.length < 5) {
                                  return const SizedBox.shrink();
                                }

                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: ResponsiveContext(context).responsiveValue(
                                      small: 12.0,
                                      medium: 16.0,
                                      large: 20.0,
                                    ),
                                    vertical: 4.0,
                                  ),
                                  child: RewardedAdButton(
                                    text: 'Obter uma dica',
                                    rewardText: 'Carregando sua dica...',
                                    icon: Icons.lightbulb_outline,
                                    onRewarded: () async {
                                      final hintWord = snapshot.data!;

                                      context.read<GameBloc>().add(
                                          GuessSubmitted(hintWord, isHint: true)
                                      );

                                      //context.read<GameBloc>().add(GuessSubmitted(hintWord, isHint: true));
                                      //context.read<GameBloc>().add(const GameRefreshDaily(isAfterAd: true));
                                    },
                                  ),
                                );
                              },
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
                                      context.read<GameBloc>().add(
                                          GuessSubmitted(guess.trim()));
                                      _guessController.clear();
                                    }
                                  },
                                ),
                              ),

                            // Botões e anúncios quando o jogo é completado
                            if (gameState.isCompleted)
                              Padding(
                                padding: EdgeInsets.all(ResponsiveContext(context).responsiveValue(
                                  small: 8.0,
                                  medium: 12.0,
                                  large: 16.0,
                                )),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _shareResults(context, gameState),
                                      icon: Icon(Icons.share,
                                          size: ResponsiveContext(context).responsiveSize(18)),
                                      label: Text(
                                        'Compartilhar Resultados',
                                        style: TextStyle(
                                            fontSize: ResponsiveContext(context).responsiveFontSize(14)),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: ColorConstants.success,
                                        foregroundColor: Colors.white,
                                        minimumSize: Size(double.infinity,
                                            ResponsiveContext(context).responsiveSize(50)),
                                      ),
                                    ),

                                    SizedBox(height: ResponsiveContext(context).responsiveValue(
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
                                        context.read<GameBloc>().add(
                                            const GameReset());

                                        // Exibir mensagem de sucesso
                                        ScaffoldMessenger
                                            .of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Você desbloqueou uma palavra extra para hoje!',
                                              style: TextStyle(fontSize: context
                                                  .responsiveFontSize(14)),
                                            ),
                                            backgroundColor: ColorConstants
                                                .success,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                    ),

                                    // Banner no fundo da tela quando o jogo for completado
                                    SizedBox(height: ResponsiveContext(context).responsiveValue(
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
              },
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
    Get.snackbar(
      'Alerta',
      message,
      backgroundColor: ColorConstants.error,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
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
}
