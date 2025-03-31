// lib/presentation/widgets/premium_banner_wrapper.dart
import 'package:contextual/presentation/widgets/premium_banner_widget.dart';
import 'package:contextual/services/premium_banner_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Widget que envolve o conteúdo e mostra o banner premium quando apropriado,
/// sem interferir com outros elementos da interface como o banner de anúncios
class PremiumBannerWrapper extends StatefulWidget {
  final Widget child;

  const PremiumBannerWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<PremiumBannerWrapper> createState() => _PremiumBannerWrapperState();
}

class _PremiumBannerWrapperState extends State<PremiumBannerWrapper> {
  final PremiumBannerService _bannerService = PremiumBannerService();
  bool _initialized = false;
  bool _showBanner = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (!_initialized) {
      await _bannerService.initialize();

      // Configurar listener para mudanças no estado do banner
      _bannerService.showBannerStream.listen((shouldShow) {
        if (mounted) {
          setState(() {
            _showBanner = shouldShow;
          });
          debugPrint('PremiumBannerWrapper: Banner deveria ser mostrado? $shouldShow');
        }
      });

      // Verificar estado inicial
      if (mounted) {
        setState(() {
          _showBanner = _bannerService.shouldShowBanner;
        });
        debugPrint('PremiumBannerWrapper: Estado inicial do banner: $_showBanner');
      }

      _initialized = true;

      // Para fins de debug - forçar a exibição do banner em desenvolvimento
      if (kDebugMode) {
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            _bannerService.forceShowBanner();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obter dimensões da tela para posicionamento adequado
    final screenSize = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Calcular posição do banner premium para não sobrepor completamente
    // o banner de anúncios que pode estar na parte inferior da tela
    final bottomPosition = bottomPadding + 16.0;

    return Stack(
      children: [
        // Conteúdo principal
        widget.child,

        // Banner premium - posicionado de forma a não interferir com outros elementos
        if (_showBanner)
          Positioned(
            bottom: bottomPosition,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false, // Já estamos ajustando manualmente a posição
              child: PremiumBannerWidget(),
            ),
          ),
      ],
    );
  }
}
