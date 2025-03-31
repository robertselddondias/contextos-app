import 'dart:async';
import 'dart:io';

import 'package:contextual/services/purchase_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gerenciador de anúncios para iOS e Android.
///
/// Esta classe gerencia a inicialização, carregamento e exibição de diferentes formatos de anúncios
/// incluindo banners, intersticiais e anúncios recompensados.
class AdManager {
  // Singleton pattern
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  // Rastreamento de inicialização
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Rastreamento de status premium
  bool _isPremium = false;
  bool get isPremium => _isPremium;

  // Flag de modo de teste (para desenvolvimento)
  final bool _useTestAds = false;

  // Instâncias de anúncios
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  // Estados dos anúncios
  bool _isBannerAdLoaded = false;
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  bool get isInterstitialAdReady => _interstitialAd != null;
  bool get isRewardedAdReady => _rewardedAd != null;

  // Rastreamento de anúncios
  int _interstitialAdCount = 0;
  DateTime? _lastInterstitialShown;
  int _interstitialFrequency = 3; // Mostrar a cada X conclusões de jogo

  // IDs de anúncios de teste
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  // IDs de anúncios de produção
  // Substitua por seus IDs reais de produção
  static const String _iosBannerAdUnitId = 'ca-app-pub-4458700759850229/6473230385';
  static const String _androidBannerAdUnitId = 'ca-app-pub-4458700759850229/8802856159';

  static const String _iosInterstitialAdUnitId = 'ca-app-pub-4458700759850229/5755178538';
  static const String _androidInterstitialAdUnitId = 'ca-app-pub-4458700759850229/3047966594';

  static const String _iosRewardedAdUnitId = 'ca-app-pub-4458700759850229/2533985374';
  static const String _androidRewardedAdUnitId = 'ca-app-pub-4458700759850229/3497724431';

  final PurchaseManager _purchaseManager = PurchaseManager();

  // Getters para IDs de anúncios baseados na plataforma e modo de teste
  String get bannerAdUnitId {
    if (_useTestAds) return _testBannerAdUnitId;
    return Platform.isIOS ? _iosBannerAdUnitId : _androidBannerAdUnitId;
  }

  String get interstitialAdUnitId {
    if (_useTestAds) return _testInterstitialAdUnitId;
    return Platform.isIOS ? _iosInterstitialAdUnitId : _androidInterstitialAdUnitId;
  }

  String get rewardedAdUnitId {
    if (_useTestAds) return _testRewardedAdUnitId;
    return Platform.isIOS ? _iosRewardedAdUnitId : _androidRewardedAdUnitId;
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('AdManager: Já inicializado');
      return;
    }

    try {
      // Inicializa o SDK do Mobile Ads
      await MobileAds.instance.initialize();
      debugPrint('AdManager: SDK do Mobile Ads inicializado com sucesso');

      // Inicializa o gerenciador de compras
      await _purchaseManager.initialize();

      // Se o usuário comprou remover anúncios, não inicializamos os anúncios
      _isPremium = _purchaseManager.removeAdsActive;

      // Inscreve-se nas mudanças do estado de compra para atualizar o status premium
      _purchaseManager.purchaseStateStream.listen((isPremiumActive) {
        _isPremium = isPremiumActive;
        debugPrint('AdManager: Status premium atualizado para $_isPremium');
      });

      // Se o usuário é premium, apenas marcamos como inicializado e saímos
      if (_isPremium) {
        _isInitialized = true;
        debugPrint('AdManager: Inicializado no modo premium (anúncios desativados)');
        return;
      }

      // Carrega status premium do usuário
      await _loadPremiumStatus();

      // Pula o carregamento de anúncios se o usuário for premium
      if (_isPremium) {
        _isInitialized = true;
        debugPrint('AdManager: Inicializado no modo premium (anúncios desativados)');
        return;
      }

      // Carrega anúncios intersticial e recompensado
      _loadInterstitialAd();
      _loadRewardedAd();

      // Carrega configurações
      await _loadSettings();

      _isInitialized = true;
      debugPrint('AdManager: Inicializado com sucesso');
    } catch (e) {
      debugPrint('AdManager: Erro durante a inicialização: $e');
      // Marca como inicializado para evitar tentativas repetidas de inicialização
      _isInitialized = true;
    }
  }

  /// Carrega o status premium do usuário a partir das preferências compartilhadas.
  Future<void> _loadPremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool('premium_user') ?? false;
      debugPrint('AdManager: Status premium carregado: $_isPremium');
    } catch (e) {
      debugPrint('AdManager: Erro ao carregar status premium: $e');
      _isPremium = false;
    }
  }

  /// Carrega configurações relacionadas a anúncios das preferências compartilhadas.
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Carrega configuração de frequência de anúncios intersticial
      _interstitialFrequency = prefs.getInt('interstitial_frequency') ?? 3;

      // Carrega contagem de anúncios intersticial
      _interstitialAdCount = prefs.getInt('interstitial_ad_count') ?? 0;

      // Carrega timestamp da última exibição
      final lastShownStr = prefs.getString('last_interstitial_shown');
      if (lastShownStr != null) {
        _lastInterstitialShown = DateTime.parse(lastShownStr);
      }

      debugPrint('AdManager: Configurações carregadas');
    } catch (e) {
      debugPrint('AdManager: Erro ao carregar configurações: $e');
      // Usa padrões se as configurações não puderem ser carregadas
      _interstitialFrequency = 3;
      _interstitialAdCount = 0;
      _lastInterstitialShown = null;
    }
  }

  /// Salva configurações relacionadas a anúncios nas preferências compartilhadas.
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Salva contagem de anúncios intersticial
      await prefs.setInt('interstitial_ad_count', _interstitialAdCount);

      // Salva timestamp da última exibição
      if (_lastInterstitialShown != null) {
        await prefs.setString('last_interstitial_shown', _lastInterstitialShown!.toIso8601String());
      }

      debugPrint('AdManager: Configurações salvas');
    } catch (e) {
      debugPrint('AdManager: Erro ao salvar configurações: $e');
    }
  }

  /// Carrega um anúncio intersticial.
  ///
  /// Este método é chamado automaticamente durante a inicialização e após
  /// a exibição de um anúncio intersticial.
  void _loadInterstitialAd() {
    if (_isPremium) return;
    if (!_isInitialized && !kDebugMode) return;

    try {
      debugPrint('AdManager: Carregando anúncio intersticial com ID: $interstitialAdUnitId');

      InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            debugPrint('AdManager: Anúncio intersticial carregado');

            // Configura callback de conteúdo em tela cheia
            _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                debugPrint('AdManager: Anúncio intersticial mostrou conteúdo em tela cheia');
              },
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('AdManager: Anúncio intersticial descartado');
                ad.dispose();
                _interstitialAd = null;

                // Recarrega anúncio para próximo uso
                _loadInterstitialAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('AdManager: Anúncio intersticial falhou ao mostrar: ${error.message}');
                ad.dispose();
                _interstitialAd = null;

                // Recarrega anúncio para próximo uso
                _loadInterstitialAd();
              },
              onAdImpression: (ad) {
                debugPrint('AdManager: Impressão de anúncio intersticial');
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('AdManager: Anúncio intersticial falhou ao carregar: ${error.message}, código: ${error.code}');
            _interstitialAd = null;

            // Tenta carregar novamente após um atraso
            Future.delayed(const Duration(minutes: 1), _loadInterstitialAd);
          },
        ),
      );

      debugPrint('AdManager: Solicitação de carregamento de anúncio intersticial enviada');
    } catch (e) {
      debugPrint('AdManager: Erro ao carregar anúncio intersticial: $e');
      _interstitialAd = null;
    }
  }

  /// Descarta o anúncio intersticial atual.
  void _disposeInterstitialAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }

  /// Carrega um anúncio recompensado.
  ///
  /// Este método é chamado automaticamente durante a inicialização e após
  /// a exibição de um anúncio recompensado.
  void _loadRewardedAd() {
    if (_isPremium) return;
    if (!_isInitialized && !kDebugMode) return;

    try {
      debugPrint('AdManager: Carregando anúncio recompensado com ID: $rewardedAdUnitId');

      RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            debugPrint('AdManager: Anúncio recompensado carregado');

            // Configura callback de conteúdo em tela cheia
            _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                debugPrint('AdManager: Anúncio recompensado mostrou conteúdo em tela cheia');
              },
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('AdManager: Anúncio recompensado descartado');
                ad.dispose();
                _rewardedAd = null;

                // Recarrega anúncio para próximo uso
                _loadRewardedAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('AdManager: Anúncio recompensado falhou ao mostrar: ${error.message}');
                ad.dispose();
                _rewardedAd = null;

                // Recarrega anúncio para próximo uso
                _loadRewardedAd();
              },
              onAdImpression: (ad) {
                debugPrint('AdManager: Impressão de anúncio recompensado');
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint('AdManager: Anúncio recompensado falhou ao carregar: ${error.message}, código: ${error.code}');
            _rewardedAd = null;

            // Tenta carregar novamente após um atraso
            Future.delayed(const Duration(minutes: 1), _loadRewardedAd);
          },
        ),
      );

      debugPrint('AdManager: Solicitação de carregamento de anúncio recompensado enviada');
    } catch (e) {
      debugPrint('AdManager: Erro ao carregar anúncio recompensado: $e');
      _rewardedAd = null;
    }
  }

  /// Descarta o anúncio recompensado atual.
  void _disposeRewardedAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }

  /// Mostra um anúncio intersticial.
  ///
  /// Retorna true se o anúncio foi mostrado, false caso contrário.
  /// Este método respeita o limite de frequência e garante um tempo mínimo entre anúncios.
  Future<bool> showInterstitial() async {
    if (_isPremium || _interstitialAd == null) return false;

    // Incrementa contador para limite de frequência
    _interstitialAdCount++;
    await _saveSettings();

    // Verifica limite de frequência
    if (_interstitialAdCount % _interstitialFrequency != 0) {
      return false;
    }

    // Verifica tempo mínimo entre anúncios (1 minuto)
    if (_lastInterstitialShown != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastInterstitialShown!);
      if (timeSinceLastAd.inMinutes < 1) {
        return false;
      }
    }

    // Mostra o anúncio
    try {
      await _interstitialAd!.show();
      _lastInterstitialShown = DateTime.now();
      await _saveSettings();
      debugPrint('AdManager: Anúncio intersticial mostrado');
      return true;
    } catch (e) {
      debugPrint('AdManager: Erro ao mostrar anúncio intersticial: $e');
      // Recarrega após erro
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _loadInterstitialAd();
      return false;
    }
  }

  /// Método chamado para notificar o serviço sobre a conclusão de um jogo para cálculos de frequência intersticial.
  ///
  /// Retorna true se um anúncio intersticial foi mostrado, false caso contrário.
  Future<bool> notifyGameCompleted() async {
    if (_isPremium) return false;
    if (!_isInitialized) await initialize();

    return showInterstitial();
  }

  /// Mostra um anúncio recompensado.
  ///
  /// Retorna true se o usuário ganhou a recompensa, false caso contrário.
  /// Opcionalmente aceita um callback para lidar com a recompensa.
  Future<bool> showRewardedAd({Function(RewardItem)? onRewarded}) async {
    if (_isPremium || _rewardedAd == null) return false;

    final completer = Completer<bool>();

    try {
      await _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
        // Chama o callback de recompensa se fornecido
        if (onRewarded != null) {
          onRewarded(reward);
        }

        debugPrint('AdManager: Usuário ganhou recompensa: ${reward.amount} ${reward.type}');
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      });

      // O fullScreenContentCallback lidará com o fechamento e erros do anúncio

    } catch (e) {
      debugPrint('AdManager: Erro ao mostrar anúncio recompensado: $e');

      // Recarrega após erro
      _rewardedAd?.dispose();
      _rewardedAd = null;
      _loadRewardedAd();

      if (!completer.isCompleted) {
        completer.complete(false);
      }
    }

    return completer.future;
  }

  /// Define a frequência de anúncios intersticiais (quantas conclusões de jogo entre anúncios).
  Future<void> setInterstitialFrequency(int frequency) async {
    try {
      if (frequency < 1) frequency = 1;

      _interstitialFrequency = frequency;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('interstitial_frequency', frequency);

      debugPrint('AdManager: Frequência intersticial definida para $frequency');
    } catch (e) {
      debugPrint('AdManager: Erro ao definir frequência intersticial: $e');
    }
  }

  /// Limpa todos os recursos de anúncios.
  ///
  /// Chame este método quando o aplicativo estiver sendo fechado ou quando os anúncios não forem mais necessários.
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    debugPrint('AdManager: Todos os recursos de anúncios foram liberados');
  }
}
