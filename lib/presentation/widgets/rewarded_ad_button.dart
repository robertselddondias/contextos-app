// lib/presentation/widgets/rewarded_ad_button.dart
import 'package:contextual/core/constants/color_constants.dart';
import 'package:contextual/presentation/blocs/game/game_bloc.dart';
import 'package:contextual/services/ad_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RewardedAdButton extends StatefulWidget {
  final String text;
  final String rewardText;
  final IconData icon;
  final VoidCallback onRewarded;
  final bool showLoadingIndicator;

  const RewardedAdButton({
    super.key,
    required this.text,
    required this.rewardText,
    required this.icon,
    required this.onRewarded,
    this.showLoadingIndicator = true,
  });

  @override
  State<RewardedAdButton> createState() => _RewardedAdButtonState();
}

class _RewardedAdButtonState extends State<RewardedAdButton> {
  final AdManager _adManager = AdManager();
  bool _isLoading = false;
  bool _isAdReady = false;

  @override
  void initState() {
    super.initState();
    _initAdManager();
  }

  Future<void> _initAdManager() async {
    if (!_adManager.isInitialized) {
      await _adManager.initialize();
    }
    _checkAdStatus();
  }

  void _checkAdStatus() {
    if (mounted) {
      setState(() {
        _isAdReady = _adManager.isRewardedAdReady;
      });

      debugPrint('RewardedAdButton: Anúncio recompensado está pronto? $_isAdReady');

      // Verifica novamente após um atraso se o anúncio não estiver pronto
      if (!_isAdReady) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _checkAdStatus();
          }
        });
      }
    }
  }

  Future<void> _showRewardedAd() async {
    if (!_isAdReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O anúncio ainda não está pronto. Tente novamente em alguns instantes.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Obtenha o estado atual do jogo antes de mostrar o anúncio (para debug)
    if (kDebugMode) {
      final gameBloc = context.read<GameBloc>();
      if (gameBloc.state is GameLoaded) {
        final currentState = gameBloc.state as GameLoaded;
        print('RewardedAdButton: Estado antes do anúncio - ${currentState.guesses.length} tentativas');
      }
    }

    final bool rewardEarned = await _adManager.showRewardedAd();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isAdReady = _adManager.isRewardedAdReady;
      });

      if (rewardEarned) {
        // Quando a recompensa é ganha, use isAfterAd=true para o refresh
        context.read<GameBloc>().add(const GameRefreshDaily(isAfterAd: true));

        // Agora chame o callback de recompensa
        widget.onRewarded();

        // Exibir mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.rewardText),
            backgroundColor: ColorConstants.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Verifique o estado após o processamento (para debug)
        if (kDebugMode) {
          final gameBloc = context.read<GameBloc>();
          if (gameBloc.state is GameLoaded) {
            final currentState = gameBloc.state as GameLoaded;
            print('RewardedAdButton: Estado após o anúncio - ${currentState.guesses.length} tentativas');
          }
        }
      }
    }

    // Verificar novamente o status do anúncio
    _checkAdStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: _isLoading && widget.showLoadingIndicator
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Icon(widget.icon),
        label: Text(_isLoading && widget.showLoadingIndicator
            ? 'Carregando...'
            : widget.text),
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorConstants.secondary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: Colors.grey,
        ),
        onPressed: (_isAdReady && !_isLoading) ? _showRewardedAd : null,
      ),
    );
  }
}
