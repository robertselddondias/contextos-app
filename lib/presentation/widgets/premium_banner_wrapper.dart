// lib/presentation/widgets/premium_banner_wrapper.dart
import 'package:contextual/presentation/widgets/premium_banner_widget.dart';
import 'package:contextual/services/premium_banner_service.dart';
import 'package:flutter/material.dart';

/// Widget que envolve o conteúdo e mostra o banner premium quando apropriado
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
