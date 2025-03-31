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
      // Versão mais recente do google_mobile_ads (2024)
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
      // Obtém o tamanho para dispositivos em modo retrato
      final AnchoredAdaptiveBannerAdSize? adaptiveSize =
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
      // Obtém o tamanho para dispositivos em modo paisagem
      final AnchoredAdaptiveBannerAdSize? adaptiveSize =
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

  /// Método seguro para obter tamanho de anúncio adaptativo que verifica contexto
  static Future<AdSize> getSafeAdaptiveBannerSize(BuildContext? context) async {
    if (context == null || !context.mounted) {
      return AdSize.banner;
    }

    try {
      final width = MediaQuery.of(context).size.width.toInt();
      final AnchoredAdaptiveBannerAdSize? adaptiveSize =
      await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
      return adaptiveSize ?? AdSize.banner;
    } catch (e) {
      debugPrint('Erro ao obter tamanho adaptativo seguro: $e');
      return AdSize.banner;
    }
  }
}
