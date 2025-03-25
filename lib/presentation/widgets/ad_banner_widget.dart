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

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadBannerAd() async {
    // Cria uma instância do AdManager mas NÃO usa o singleton diretamente
    final adManager = AdManager();

    // Determina o tamanho do banner
    final AdSize adSize = await context.getAdaptiveBannerAdSize();

    // Cria uma nova instância de BannerAd para cada widget
    _bannerAd = BannerAd(
      adUnitId: adManager.bannerAdUnitId,
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
  }

  @override
  Widget build(BuildContext context) {
    // Se não houver anúncio carregado, retorna um espaço reservado
    if (!_isAdLoaded || _bannerAd == null) {
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
