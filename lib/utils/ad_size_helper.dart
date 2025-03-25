// lib/utils/ad_size_helper.dart
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

extension AdSizeExtension on BuildContext {
  /// Retorna um tamanho de anúncio adaptativo baseado na largura da tela atual
  /// e na orientação atual do dispositivo
  Future<AdSize> getAdaptiveBannerAdSize() async {
    // Obtém a largura da tela
    final width = MediaQuery.of(this).size.width.toInt();

    try {
      // Obtém o tamanho adaptativo para a orientação atual (compatível com versão 5.3.1)
      final AnchoredAdaptiveBannerAdSize? adaptiveSize =
      await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

      // Verifica se o tamanho adaptativo é válido
      if (adaptiveSize != null) {
        return adaptiveSize;
      }
    } catch (e) {
      debugPrint('Erro ao obter tamanho adaptativo: $e');
    }

    // Fallback para o banner padrão em caso de erro
    return AdSize.banner;
  }

  /// Retorna um tamanho adaptativo para orientação retrato
  Future<AdSize> getPortraitBannerAdSize() async {
    final width = MediaQuery.of(this).size.width.toInt();

    try {
      final AdSize? adaptiveSize =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

      if (adaptiveSize != null) {
        return adaptiveSize;
      }
    } catch (e) {
      debugPrint('Erro ao obter tamanho adaptativo para retrato: $e');
    }

    return AdSize.banner;
  }

  /// Retorna um tamanho adaptativo para orientação paisagem
  Future<AdSize> getLandscapeBannerAdSize() async {
    final width = MediaQuery.of(this).size.width.toInt();

    try {
      final AdSize? adaptiveSize =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

      if (adaptiveSize != null) {
        return adaptiveSize;
      }
    } catch (e) {
      debugPrint('Erro ao obter tamanho adaptativo para paisagem: $e');
    }

    return AdSize.banner;
  }

  /// Retorna um tamanho de anúncio padrão (método sincronizado)
  AdSize getStandardBannerAdSize() {
    // Para banners normais, usamos o tamanho padrão
    return AdSize.banner;
  }
}
