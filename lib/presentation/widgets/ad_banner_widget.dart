// lib/presentation/widgets/ad_banner_widget.dart
import 'package:contextual/services/ad_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBannerWidget extends StatefulWidget {
  final bool isTop;

  const AdBannerWidget({super.key, this.isTop = true});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  final AdManager _adManager = AdManager();
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadBannerAd() async {
    // Cria uma instância do AdManager
    if (!_adManager.isInitialized) {
      await _adManager.initialize();
    }

    // Determina o tamanho do banner
    final AdSize adSize = await _getAdaptiveBannerSize();

    // Carregar o anúncio
    await _adManager.loadBannerAd(size: adSize);

    if (mounted) {
      setState(() {
        _isAdLoaded = _adManager.isBannerAdLoaded;
      });
    }

    // Se o anúncio não carregar, tentar novamente após um tempo
    if (!_isAdLoaded) {
      Future.delayed(const Duration(minutes: 1), () {
        if (mounted) {
          _loadBannerAd();
        }
      });
    }
  }

  Future<AdSize> _getAdaptiveBannerSize() async {
    final width = MediaQuery.of(context).size.width;
    return _adManager.getAdaptiveBannerAdSize(width);
  }

  @override
  Widget build(BuildContext context) {
    // Se não houver anúncio carregado, retorna um espaço reservado
    if (!_isAdLoaded || _adManager.getBannerAd() == null) {
      // Retorna um espaço reservado com a altura de um banner padrão
      // para evitar pulos no layout quando o anúncio carregar
      return Container(
        height: 50, // Altura aproximada de um banner padrão
        alignment: Alignment.center,
        child: widget.isTop
            ? const Text('Carregando anúncio...',
            style: TextStyle(fontSize: 12, color: Colors.grey))
            : const SizedBox.shrink(), // No fundo não mostramos texto
      );
    }

    // Quando o anúncio está carregado, exibe-o com estilo adequado
    return Container(
      alignment: Alignment.center,
      width: MediaQuery.of(context).size.width,
      height: _adManager.getBannerAd()!.size.height.toDouble(),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05), // Fundo sutil para o anúncio
        border: Border(
          bottom: widget.isTop ? BorderSide(color: Colors.grey.withOpacity(0.2), width: 1) : BorderSide.none,
          top: !widget.isTop ? BorderSide(color: Colors.grey.withOpacity(0.2), width: 1) : BorderSide.none,
        ),
      ),
      child: AdWidget(ad: _adManager.getBannerAd()!),
    );
  }
}
