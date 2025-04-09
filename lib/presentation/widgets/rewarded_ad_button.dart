// lib/presentation/widgets/rewarded_ad_button.dart
import 'package:contextual/core/constants/color_constants.dart';
import 'package:contextual/services/ad_manager.dart';
import 'package:flutter/material.dart';

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
    _checkAdStatus();
  }

  void _checkAdStatus() {
    if (mounted) {
      setState(() {
        _isAdReady = _adManager.isRewardedAdReady;
      });
    }

    // Verifica novamente após um atraso se o anúncio não estiver pronto
    if (!_isAdReady) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _checkAdStatus();
        }
      });
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

    final bool rewardEarned = await _adManager.showRewardedAd();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isAdReady = _adManager.isRewardedAdReady;
      });

      if (rewardEarned) {
        widget.onRewarded();

        // Exibe uma mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.rewardText),
            backgroundColor: ColorConstants.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    // Verifica novamente o status do anúncio
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
