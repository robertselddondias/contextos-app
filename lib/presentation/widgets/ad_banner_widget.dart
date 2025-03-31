// lib/presentation/widgets/ad_banner_widget.dart
import 'package:contextual/services/ad_manager.dart';
import 'package:contextual/utils/ad_size_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdBannerWidget extends StatefulWidget {
  final bool isTop;

  const AdBannerWidget({super.key, this.isTop = true});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  final AdManager _adManager = AdManager();
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    // Inicialização segura após o build completo do widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _adManager.initialize();

    if (!mounted) return;

    final isPremium = _adManager.isPremium;

    setState(() {
      _isPremium = isPremium;
    });

    if (!isPremium) {
      // Só carrega o anúncio se não for premium
      _loadBannerAd();
    }
  }

  Future<void> _loadBannerAd() async {
    if (!mounted) return;

    try {
      // Usa o método seguro para obter o tamanho adaptativo
      final adSize = await AdSizeExtension.getSafeAdaptiveBannerSize(context);

      // Configura o banner ad
      _bannerAd = BannerAd(
        adUnitId: _adManager.bannerAdUnitId,
        size: adSize,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() {
                _isAdLoaded = true;
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Falha ao carregar banner ad: ${error.message}');
            ad.dispose();

            if (mounted) {
              setState(() {
                _bannerAd = null;
                _isAdLoaded = false;
              });
            }

            // Tenta recarregar após falha
            Future.delayed(const Duration(minutes: 1), () {
              if (mounted) {
                _loadBannerAd();
              }
            });
          },
        ),
      );

      // Carrega o anúncio
      await _bannerAd?.load();
    } catch (e) {
      debugPrint('Erro ao carregar banner ad: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se for premium, não mostra anúncio
    if (_isPremium) {
      return const SizedBox.shrink();
    }

    // Se o anúncio não estiver carregado, mostra espaço reservado
    if (!_isAdLoaded || _bannerAd == null) {
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
      height: _bannerAd!.size.height.toDouble(),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05), // Fundo sutil para o anúncio
        border: Border(
          bottom: widget.isTop ? BorderSide(color: Colors.grey.withOpacity(0.2), width: 1) : BorderSide.none,
          top: !widget.isTop ? BorderSide(color: Colors.grey.withOpacity(0.2), width: 1) : BorderSide.none,
        ),
      ),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
