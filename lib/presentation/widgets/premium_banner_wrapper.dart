// Modificação no PremiumBannerWrapper para mostrar o banner apenas na tela principal

// lib/presentation/widgets/premium_banner_wrapper.dart (modificado)
import 'package:contextual/presentation/widgets/premium_banner_widget.dart';
import 'package:contextual/services/premium_banner_service.dart';
import 'package:flutter/material.dart';

/// Widget que envolve o conteúdo e mostra o banner premium apenas na tela principal do jogo
class PremiumBannerWrapper extends StatefulWidget {
  final Widget child;
  final bool showInScreen; // Nova propriedade para controlar onde o banner aparece

  const PremiumBannerWrapper({
    super.key,
    required this.child,
    this.showInScreen = false, // Por padrão, não mostra o banner
  });

  @override
  State<PremiumBannerWrapper> createState() => _PremiumBannerWrapperState();
}

class _PremiumBannerWrapperState extends State<PremiumBannerWrapper> {
  final PremiumBannerService _bannerService = PremiumBannerService();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (!_initialized) {
      await _bannerService.initialize();
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se não estiver na tela principal, retorna apenas o child sem o banner
    if (!widget.showInScreen) {
      return widget.child;
    }

    // Se estiver na tela principal, mostra o banner
    return Stack(
      children: [
        // Conteúdo principal
        widget.child,

        // Banner premium - ficará em cima do conteúdo principal
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: PremiumBannerWidget(),
        ),
      ],
    );
  }
}
