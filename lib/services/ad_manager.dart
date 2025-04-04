import 'dart:async';
import 'dart:io';

import 'package:contextual/services/purchase_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gerenciador de anúncios para iOS e Android.
///
/// Esta classe gerencia a inicialização, carregamento e exibição de diferentes formatos de anúncios
/// incluindo banners, intersticiais e anúncios recompensados.
class AdManager with WidgetsBindingObserver {
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
  final bool _useTestAds = kDebugMode;

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

  // Contador de tentativas para carregamento de anúncios
  int _interstitialLoadAttempts = 0;
  int _rewardedLoadAttempts = 0;
  static const int _maxLoadAttempts = 3;

  // IDs de anúncios de teste
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  // IDs de anúncios de produção
  static const String _iosBannerAdUnitId = 'ca-app-pub-4458700759850229/6473230385';
  static const String _androidBannerAdUnitId = 'ca-app-pub-4458700759850229/8802856159';

  static const String _iosInterstitialAdUnitId = 'ca-app-pub-4458700759850229/5755178538';
  static const String _androidInterstitialAdUnitId = 'ca-app-pub-4458700759850229/3047966594';

  static const String _iosRewardedAdUnitId = 'ca-app-pub-4458700759850229/2533985374';
  static const String _androidRewardedAdUnitId = 'ca-app-pub-4458700759850229/3497724431';

  final PurchaseManager _purchaseManager = PurchaseManager();

  // Flag para verificar se a inicialização já foi tentada
  bool _initializationAttempted = false;

  // Flag para rastrear se o observador do ciclo de vida foi registrado
  bool _lifecycleObserverRegistered = false;

  // Getters para IDs de anúncios baseados na plataforma e modo de teste
  String get bannerAdUnitId {
    if (_useTestAds) return _testBannerAdUnitId;
    return Platform.isIOS ? _iosBannerAdUnitId : _androidBannerAdUnitId;
  }

  String get interstitialAdUnitId {
    if (_useTestAds) return _testInterstitialAdUnitId;
    return Platform.isIOS
        ? _iosInterstitialAdUnitId
        : _androidInterstitialAdUnitId;
  }

  String get rewardedAdUnitId {
    if (_useTestAds) return _testRewardedAdUnitId;
    return Platform.isIOS ? _iosRewardedAdUnitId : _androidRewardedAdUnitId;
  }

  Future<void> initialize() async {
    // Evita múltiplas tentativas de inicialização
    if (_initializationAttempted) {
      debugPrint('AdManager: Inicialização já foi tentada anteriormente');
      return;
    }

    _initializationAttempted = true;

    try {
      // Inicializa o SDK do Mobile Ads com tratamento específico para iOS
      // Para iOS, definimos configurações adicionais
      if (Platform.isIOS) {
        // Configurações específicas para iOS
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(
            tagForChildDirectedTreatment: TagForChildDirectedTreatment
                .unspecified,
            tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
            testDeviceIds: _useTestAds ? ['kGADSimulatorID'] : [],
            // Garante limites de frequência adequados
            maxAdContentRating: MaxAdContentRating.pg,
          ),
        );
        debugPrint('AdManager iOS: Configurações específicas aplicadas');
      }

      final initStatus = await MobileAds.instance.initialize();

      // Verifica status de inicialização específico para iOS
      if (Platform.isIOS) {
        final adapterStatuses = initStatus.adapterStatuses;
        adapterStatuses.forEach((key, status) {
          debugPrint('AdManager iOS: Adaptador $key - ${status.state}, ${status
              .description}');
        });
      }

      debugPrint('AdManager: SDK do Mobile Ads inicializado com sucesso');

      // Tenta inicializar o gerenciador de compras de forma segura
      bool purchaseManagerInitialized = false;
      try {
        await _purchaseManager.initialize();
        purchaseManagerInitialized = true;
      } catch (e) {
        debugPrint('AdManager: Erro ao inicializar gerenciador de compras: $e');
      }

      // Carrega status premium das preferências primeiro como fallback
      await _loadPremiumStatus();

      // Se o gerenciador de compras inicializou, usa seu valor (tem prioridade)
      if (purchaseManagerInitialized) {
        _isPremium = _purchaseManager.removeAdsActive;

        // Inscreve-se nas mudanças do estado de compra para atualizar o status premium
        _purchaseManager.purchaseStateStream.listen((isPremiumActive) {
          _isPremium = isPremiumActive;
          // Quando o usuário se torna premium, descarta os anúncios ativos
          if (_isPremium) {
            _disposeAllAds();
          }
          debugPrint('AdManager: Status premium atualizado para $_isPremium');
        });
      }

      // Se o usuário é premium, apenas marcamos como inicializado e saímos
      if (_isPremium) {
        _isInitialized = true;
        debugPrint(
            'AdManager: Inicializado no modo premium (anúncios desativados)');
        return;
      }

      // Carrega configurações
      await _loadSettings();

      // Carrega anúncios com tratamento específico para iOS
      if (Platform.isIOS) {
        // No iOS, carregamos com um pequeno atraso para garantir que o SDK AdMob esteja completamente pronto
        Future.delayed(const Duration(seconds: 1), () {
          _loadInterstitialAd();
          _loadRewardedAd();
        });
      } else {
        _loadInterstitialAd();
        _loadRewardedAd();
      }

      _isInitialized = true;
      debugPrint('AdManager: Inicializado com sucesso');

      // Configura monitoramento do ciclo de vida do aplicativo
      _setupAppLifecycleMonitoring();
    } catch (e) {
      debugPrint('AdManager: Erro durante a inicialização: $e');
      // Não marca como inicializado em caso de erro crítico
      _isInitialized = false;

      // Tenta novamente em 30 segundos se estiver em ambiente de produção
      if (!kDebugMode) {
        Future.delayed(const Duration(seconds: 30), () {
          _initializationAttempted = false; // Permite uma nova tentativa
          initialize();
        });
      }
    }
  }

  /// Carrega o status premium do usuário a partir das preferências compartilhadas.
  Future<void> _loadPremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool('premium_user') ?? false;
      debugPrint(
          'AdManager: Status premium carregado de preferências: $_isPremium');
    } catch (e) {
      debugPrint('AdManager: Erro ao carregar status premium: $e');
      _isPremium = false;
    }
  }

  /// Salva o status premium do usuário nas preferências compartilhadas.
  Future<void> _savePremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('premium_user', _isPremium);

      // No iOS, às vezes precisamos forçar um flush das configurações
      if (Platform.isIOS) {
        await prefs.reload();
      }

      debugPrint('AdManager: Status premium salvo: $_isPremium');
    } catch (e) {
      debugPrint('AdManager: Erro ao salvar status premium: $e');
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
        try {
          _lastInterstitialShown = DateTime.parse(lastShownStr);
        } catch (e) {
          debugPrint('AdManager: Erro ao analisar data da última exibição: $e');
          _lastInterstitialShown = null;
        }
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
        await prefs.setString('last_interstitial_shown',
            _lastInterstitialShown!.toIso8601String());
      }

      debugPrint('AdManager: Configurações salvas');
    } catch (e) {
      debugPrint('AdManager: Erro ao salvar configurações: $e');
    }
  }

  /// Carrega um anúncio intersticial com tratamento específico para iOS.
  void _loadInterstitialAd() {
    if (_isPremium) return;

    // Verifica se a inicialização foi concluída
    if (!_isInitialized && !kDebugMode) {
      debugPrint(
          'AdManager: Tentativa de carregar intersticial antes da inicialização');
      return;
    }

    // Verifica se já atingiu o número máximo de tentativas
    if (_interstitialLoadAttempts >= _maxLoadAttempts) {
      debugPrint(
          'AdManager: Número máximo de tentativas de carregamento de intersticial atingido');
      // Reseta o contador após um período
      Future.delayed(const Duration(minutes: 5), () {
        _interstitialLoadAttempts = 0;
      });
      return;
    }

    try {
      debugPrint(
          'AdManager: Carregando anúncio intersticial com ID: $interstitialAdUnitId');

      // Incrementa contador de tentativas
      _interstitialLoadAttempts++;

      // Configurações específicas para iOS para evitar timeouts
      var adRequest = const AdRequest();

      // No iOS, usamos um timeout maior para reduzir erros de timeout (código 5)
      if (Platform.isIOS) {
        adRequest = const AdRequest(
          // Não use keywords que possam causar atrasos adicionais
          keywords: [],
          // Não solicite anúncios não personalizados que podem levar mais tempo para carregar
          nonPersonalizedAds: false,
        );
      }

      InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: adRequest,
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _interstitialLoadAttempts = 0; // Reseta contador após sucesso
            debugPrint('AdManager: Anúncio intersticial carregado');

            // Configura callback de conteúdo em tela cheia
            _interstitialAd!.fullScreenContentCallback =
                FullScreenContentCallback(
                  onAdShowedFullScreenContent: (ad) {
                    debugPrint(
                        'AdManager: Anúncio intersticial mostrou conteúdo em tela cheia');
                  },
                  onAdDismissedFullScreenContent: (ad) {
                    debugPrint('AdManager: Anúncio intersticial descartado');
                    ad.dispose();
                    _interstitialAd = null;

                    // Recarrega anúncio para próximo uso com um pequeno atraso no iOS
                    if (Platform.isIOS) {
                      Future.delayed(const Duration(milliseconds: 500),
                          _loadInterstitialAd);
                    } else {
                      _loadInterstitialAd();
                    }
                  },
                  onAdFailedToShowFullScreenContent: (ad, error) {
                    debugPrint(
                        'AdManager: Anúncio intersticial falhou ao mostrar: ${error
                            .message}, código: ${error.code}');
                    ad.dispose();
                    _interstitialAd = null;

                    // Recarrega anúncio com um atraso maior em caso de falha
                    Future.delayed(
                        const Duration(seconds: 5), _loadInterstitialAd);
                  },
                  onAdImpression: (ad) {
                    debugPrint('AdManager: Impressão de anúncio intersticial');
                  },
                );
          },
          onAdFailedToLoad: (error) {
            debugPrint(
                'AdManager: Anúncio intersticial falhou ao carregar: ${error
                    .message}, código: ${error.code}');
            _interstitialAd = null;

            // Tratamento específico para erros do iOS
            if (Platform.isIOS) {
              // Tratamento específico para erro de timeout (código 5)
              if (error.code == 5) {
                debugPrint(
                    'AdManager iOS: Erro de timeout detectado ao carregar anúncio intersticial');

                // Para erros de timeout, podemos tentar com uma estratégia diferente
                // Primeiro, aguardar um tempo mais curto
                final timeoutDelay = _interstitialLoadAttempts <= 1 ? 10 : 30;
                debugPrint(
                    'AdManager iOS: Tentando novamente após timeout em $timeoutDelay segundos...');

                Future.delayed(Duration(seconds: timeoutDelay), () {
                  // Antes de tentar novamente, verificamos a conectividade (indiretamente)
                  if (_isInitialized) {
                    debugPrint('AdManager iOS: Nova tentativa após timeout');
                    _loadInterstitialAd();
                  }
                });
              } else {
                // Atrasos progressivos para outros tipos de erros
                final delay = _interstitialLoadAttempts * 30;
                debugPrint(
                    'AdManager iOS: Tentando novamente em $delay segundos...');
                Future.delayed(Duration(seconds: delay), _loadInterstitialAd);
              }
            } else {
              Future.delayed(const Duration(minutes: 1), _loadInterstitialAd);
            }
          },
        ),
      );

      debugPrint(
          'AdManager: Solicitação de carregamento de anúncio intersticial enviada');
    } catch (e) {
      debugPrint('AdManager: Erro ao carregar anúncio intersticial: $e');
      _interstitialAd = null;

      // Tenta novamente após um atraso
      Future.delayed(const Duration(minutes: 1), _loadInterstitialAd);
    }
  }

  /// Carrega um anúncio recompensado com tratamento específico para iOS.
  void _loadRewardedAd() {
    if (_isPremium) return;

    // Verifica se a inicialização foi concluída
    if (!_isInitialized && !kDebugMode) {
      debugPrint(
          'AdManager: Tentativa de carregar recompensado antes da inicialização');
      return;
    }

    // Verifica se já atingiu o número máximo de tentativas
    if (_rewardedLoadAttempts >= _maxLoadAttempts) {
      debugPrint(
          'AdManager: Número máximo de tentativas de carregamento de recompensado atingido');
      // Reseta o contador após um período
      Future.delayed(const Duration(minutes: 5), () {
        _rewardedLoadAttempts = 0;
      });
      return;
    }

    try {
      debugPrint(
          'AdManager: Carregando anúncio recompensado com ID: $rewardedAdUnitId');

      // Incrementa contador de tentativas
      _rewardedLoadAttempts++;

      // Configurações específicas para iOS para evitar timeouts
      var adRequest = const AdRequest();

      // No iOS, usamos um timeout maior para reduzir erros de timeout (código 5)
      if (Platform.isIOS) {
        adRequest = const AdRequest(
          // Não use keywords que possam causar atrasos adicionais
          keywords: [],
          // Não solicite anúncios não personalizados que podem levar mais tempo para carregar
          nonPersonalizedAds: false,
        );
      }

      RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: adRequest,
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _rewardedLoadAttempts = 0; // Reseta contador após sucesso
            debugPrint('AdManager: Anúncio recompensado carregado');

            // Configura callback de conteúdo em tela cheia
            _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                debugPrint(
                    'AdManager: Anúncio recompensado mostrou conteúdo em tela cheia');
              },
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('AdManager: Anúncio recompensado descartado');
                ad.dispose();
                _rewardedAd = null;

                // Recarrega anúncio para próximo uso com um pequeno atraso no iOS
                if (Platform.isIOS) {
                  Future.delayed(
                      const Duration(milliseconds: 500), _loadRewardedAd);
                } else {
                  _loadRewardedAd();
                }
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint(
                    'AdManager: Anúncio recompensado falhou ao mostrar: ${error
                        .message}, código: ${error.code}');
                ad.dispose();
                _rewardedAd = null;

                // Recarrega anúncio com um atraso maior em caso de falha
                Future.delayed(const Duration(seconds: 5), _loadRewardedAd);
              },
              onAdImpression: (ad) {
                debugPrint('AdManager: Impressão de anúncio recompensado');
              },
            );
          },
          onAdFailedToLoad: (error) {
            debugPrint(
                'AdManager: Anúncio recompensado falhou ao carregar: ${error
                    .message}, código: ${error.code}');
            _rewardedAd = null;

            // Tratamento específico para erros do iOS
            if (Platform.isIOS) {
              // Tratamento específico para erro de timeout (código 5)
              if (error.code == 5) {
                debugPrint(
                    'AdManager iOS: Erro de timeout detectado ao carregar anúncio recompensado');

                // Para erros de timeout, podemos tentar com uma estratégia diferente
                final timeoutDelay = _rewardedLoadAttempts <= 1 ? 10 : 30;
                debugPrint(
                    'AdManager iOS: Tentando novamente após timeout em $timeoutDelay segundos...');

                Future.delayed(Duration(seconds: timeoutDelay), () {
                  if (_isInitialized) {
                    debugPrint('AdManager iOS: Nova tentativa após timeout');
                    _loadRewardedAd();
                  }
                });
              } else {
                // Atrasos progressivos para outros tipos de erros
                final delay = _rewardedLoadAttempts * 30;
                debugPrint(
                    'AdManager iOS: Tentando novamente em $delay segundos...');
                Future.delayed(Duration(seconds: delay), _loadRewardedAd);
              }
            } else {
              Future.delayed(const Duration(minutes: 1), _loadRewardedAd);
            }
          },
        ),
      );

      debugPrint(
          'AdManager: Solicitação de carregamento de anúncio recompensado enviada');
    } catch (e) {
      debugPrint('AdManager: Erro ao carregar anúncio recompensado: $e');
      _rewardedAd = null;

      // Tenta novamente após um atraso
      Future.delayed(const Duration(minutes: 1), _loadRewardedAd);
    }
  }

  /// Mostra um anúncio intersticial com validações robustas para iOS.
  ///
  /// Retorna true se o anúncio foi mostrado, false caso contrário.
  /// Este método respeita o limite de frequência e garante um tempo mínimo entre anúncios.
  Future<bool> showInterstitial() async {
    // Tentativa de inicialização se necessário
    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e) {
        debugPrint(
            'AdManager: Erro ao inicializar durante showInterstitial: $e');
        return false;
      }
    }

    // Não mostra anúncios para usuários premium
    if (_isPremium) return false;

    // Verifica se o anúncio está disponível
    if (_interstitialAd == null) {
      debugPrint(
          'AdManager: Tentativa de mostrar intersticial, mas anúncio não está disponível');
      _loadInterstitialAd(); // Tenta carregar novamente
      return false;
    }

    // Incrementa contador para limite de frequência
    _interstitialAdCount++;
    await _saveSettings();

    // Verifica limite de frequência
    if (_interstitialAdCount % _interstitialFrequency != 0) {
      debugPrint(
          'AdManager: Frequência de anúncios ainda não atingida ($_interstitialAdCount/$_interstitialFrequency)');
      return false;
    }

    // Verifica tempo mínimo entre anúncios (2 minutos para iOS, 1 minuto para outros)
    if (_lastInterstitialShown != null) {
      final timeSinceLastAd = DateTime.now().difference(
          _lastInterstitialShown!);
      final minTimeInMinutes = Platform.isIOS ? 2 : 1;

      if (timeSinceLastAd.inMinutes < minTimeInMinutes) {
        debugPrint(
            'AdManager: Tempo mínimo entre anúncios não atingido (${timeSinceLastAd
                .inSeconds}s)');
        return false;
      }
    }

    // Mostra o anúncio com tratamento robusto de erros
    try {
      final InterstitialAd ad = _interstitialAd!;

      // Referência temporária para evitar problemas de concorrência
      _interstitialAd = null;

      await ad.show();
      _lastInterstitialShown = DateTime.now();
      await _saveSettings();
      debugPrint('AdManager: Anúncio intersticial mostrado com sucesso');
      return true;
    } catch (e) {
      debugPrint('AdManager: Erro ao mostrar anúncio intersticial: $e');

      // Limpa referência em caso de erro
      _interstitialAd?.dispose();
      _interstitialAd = null;

      // Recarrega com um atraso para evitar ciclos de falha
      Future.delayed(const Duration(seconds: 30), _loadInterstitialAd);
      return false;
    }
  }

  /// Método chamado para notificar o serviço sobre a conclusão de um jogo para cálculos de frequência intersticial.
  ///
  /// Retorna true se um anúncio intersticial foi mostrado, false caso contrário.
  Future<bool> notifyGameCompleted() async {
    if (_isPremium) return false;

    // Tentativa de inicialização se necessário
    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e) {
        debugPrint(
            'AdManager: Erro ao inicializar durante notifyGameCompleted: $e');
        return false;
      }
    }

    return showInterstitial();
  }

  /// Mostra um anúncio recompensado com tratamento robusto de erros para iOS.
  ///
  /// Retorna true se o usuário ganhou a recompensa, false caso contrário.
  /// Opcionalmente aceita um callback para lidar com a recompensa.
  Future<bool> showRewardedAd({Function(RewardItem)? onRewarded}) async {
    // Tentativa de inicialização se necessário
    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e) {
        debugPrint('AdManager: Erro ao inicializar durante showRewardedAd: $e');
        return false;
      }
    }

    // Não mostra anúncios para usuários premium
    if (_isPremium) return false;

    // Verifica se o anúncio está disponível
    if (_rewardedAd == null) {
      debugPrint(
          'AdManager: Tentativa de mostrar recompensado, mas anúncio não está disponível');
      _loadRewardedAd(); // Tenta carregar novamente
      return false;
    }

    final completer = Completer<bool>();
    bool hasRewarded = false;

    try {
      final RewardedAd ad = _rewardedAd!;

      // Referência temporária para evitar problemas de concorrência
      _rewardedAd = null;

      await ad.show(onUserEarnedReward: (ad, reward) {
        hasRewarded = true;

        // Chama o callback de recompensa se fornecido
        if (onRewarded != null) {
          onRewarded(reward);
        }

        debugPrint(
            'AdManager: Usuário ganhou recompensa: ${reward.amount} ${reward
                .type}');
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      });

      // Adiciona um timeout para garantir que o completer sempre complete
      Future.delayed(const Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          debugPrint('AdManager: Timeout ao mostrar anúncio recompensado');
          if (hasRewarded) {
            completer.complete(true);
          } else {
            completer.complete(false);
          }
        }
      });
    } catch (e) {
      debugPrint('AdManager: Erro ao mostrar anúncio recompensado: $e');

      // Limpa a referência em caso de erro
      _rewardedAd?.dispose();
      _rewardedAd = null;

      // Recarrega com um atraso para evitar ciclos de falha
      Future.delayed(const Duration(seconds: 30), _loadRewardedAd);

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

  /// Define o status premium do usuário.
  ///
  /// Use este método para sincronizar o status premium quando o usuário compra a remoção de anúncios.
  Future<void> setPremiumStatus(bool isPremium) async {
    _isPremium = isPremium;
    await _savePremiumStatus();

    if (_isPremium) {
      _disposeAllAds();
    } else if (_isInitialized) {
      _loadInterstitialAd();
      _loadRewardedAd();
    }

    debugPrint('AdManager: Status premium atualizado para $_isPremium');
  }

  /// Descarta todos os anúncios ativos.
  void _disposeAllAds() {
    _disposeInterstitialAd();
    _disposeRewardedAd();
    _disposeBannerAd();
  }

  /// Descarta o anúncio intersticial atual.
  void _disposeInterstitialAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }

  /// Descarta o anúncio recompensado atual.
  void _disposeRewardedAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }

  /// Descarta o anúncio banner atual.
  void _disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
  }

  /// Reinicia o AdManager para forçar uma nova inicialização.
  ///
  /// Útil quando ocorrem problemas com anúncios em ambiente de produção.
  Future<void> reset() async {
    debugPrint('AdManager: Iniciando reset...');

    // Libera todos os recursos
    _disposeAllAds();

    // Reseta flags
    _isInitialized = false;
    _initializationAttempted = false;
    _interstitialLoadAttempts = 0;
    _rewardedLoadAttempts = 0;

    // Tenta inicializar novamente
    await initialize();

    debugPrint('AdManager: Reset concluído');
  }

  /// Limpa todos os recursos de anúncios.
  ///
  /// Chame este método quando o aplicativo estiver sendo fechado ou quando os anúncios não forem mais necessários.
  void dispose() {
    _disposeAllAds();

    // Remove o observador do ciclo de vida se estiver registrado
    if (_lifecycleObserverRegistered) {
      WidgetsBinding.instance.removeObserver(this);
      _lifecycleObserverRegistered = false;
      debugPrint('AdManager: Observador de ciclo de vida removido');
    }

    debugPrint('AdManager: Todos os recursos de anúncios foram liberados');
  }

  /// Forçar recarregamento de todos os anúncios
  ///
  /// Útil para situações onde os anúncios podem ter sido impedidos pelo iOS (como limitações de rede)
  Future<void> forceReloadAds() async {
    if (_isPremium) return;

    debugPrint('AdManager: Forçando recarga de anúncios');

    // Limpa anúncios existentes
    _disposeAllAds();

    // Reseta contadores de tentativas
    _interstitialLoadAttempts = 0;
    _rewardedLoadAttempts = 0;

    // Para iOS, podemos fazer algumas ações extras para resolver problemas persistentes
    if (Platform.isIOS) {
      debugPrint(
          'AdManager iOS: Aplicando estratégia de recarga especial para iOS');

      // Em iOS, às vezes é necessário "refrescar" o estado do SDK
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: _useTestAds ? ['kGADSimulatorID'] : [],
        ),
      );

      // Atraso maior para garantir que o sistema de anúncios seja reiniciado
      await Future.delayed(const Duration(seconds: 3));
    } else {
      // Para Android, um atraso menor é suficiente
      await Future.delayed(const Duration(seconds: 1));
    }

    // Recarrega anúncios
    _loadInterstitialAd();
    _loadRewardedAd();

    debugPrint('AdManager: Recarga de anúncios solicitada');
  }

  /// Reporta um erro específico do iOS para depuração
  void reportIOSError(String errorType, String errorDetails) {
    if (Platform.isIOS) {
      debugPrint('AdManager iOS ERROR - $errorType: $errorDetails');

      // Tratamento específico para timeout
      if (errorType.contains('timeout') || errorDetails.contains('timeout')) {
        debugPrint(
            'AdManager iOS: Detectado erro de timeout, iniciando procedimento especial');
        handleIOSTimeout();
        return;
      }

      // Se for um erro relacionado a anúncios, tenta recuperar
      if (errorType.contains('ad') || errorType.contains('Ad')) {
        forceReloadAds();
      }
    }
  }

  /// Método para lidar especificamente com erros de timeout no iOS
  Future<void> handleIOSTimeout() async {
    if (!Platform.isIOS) return;

    debugPrint(
        'AdManager iOS: Iniciando procedimento de recuperação de timeout');

    // Limpa todos os anúncios existentes
    _disposeAllAds();

    // Reseta contadores
    _interstitialLoadAttempts = 0;
    _rewardedLoadAttempts = 0;

    // Força uma atualização da configuração para "resetar" o estado interno do SDK
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
        testDeviceIds: _useTestAds ? ['kGADSimulatorID'] : [],
      ),
    );

    // Aguarda um tempo maior para garantir que o sistema de anúncios esteja pronto
    await Future.delayed(const Duration(seconds: 5));

    // Tenta carregar novamente com um atraso entre as cargas
    _loadInterstitialAd();
    await Future.delayed(const Duration(seconds: 2));
    _loadRewardedAd();

    debugPrint(
        'AdManager iOS: Procedimento de recuperação de timeout concluído');
  }

  /// Realiza diagnóstico completo do sistema de anúncios e tenta corrigir problemas
  /// Retorna um relatório de diagnóstico com status e ações tomadas
  Future<Map<String, dynamic>> runDiagnostics() async {
    final diagnosticReport = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'platform': Platform.isIOS ? 'iOS' : 'Android',
      'isInitialized': _isInitialized,
      'isPremium': _isPremium,
      'isTestMode': _useTestAds,
      'interstitialAdLoaded': _interstitialAd != null,
      'rewardedAdLoaded': _rewardedAd != null,
      'interstitialLoadAttempts': _interstitialLoadAttempts,
      'rewardedLoadAttempts': _rewardedLoadAttempts,
      'actions': <String>[],
    };

    debugPrint('AdManager: Iniciando diagnóstico');

    // Verifica inicialização
    if (!_isInitialized) {
      diagnosticReport['actions'].add('Iniciando inicialização');
      try {
        await initialize();
        diagnosticReport['isInitialized'] = _isInitialized;
      } catch (e) {
        diagnosticReport['initializationError'] = e.toString();
      }
    }

    // Verifica status premium
    if (!_isPremium) {
      // Se não for premium, verifica anúncios
      diagnosticReport['actions'].add('Verificando estado dos anúncios');

      // Verifica intersticial
      if (_interstitialAd == null) {
        diagnosticReport['actions'].add('Recarregando anúncio intersticial');
        _loadInterstitialAd();
      }

      // Verifica recompensa
      if (_rewardedAd == null) {
        diagnosticReport['actions'].add('Recarregando anúncio recompensado');
        _loadRewardedAd();
      }

      // Para iOS, verifica configurações específicas
      if (Platform.isIOS) {
        diagnosticReport['actions'].add(
            'Verificando configurações específicas do iOS');

        // Verifica configurações de rede (iOS pode bloquear anúncios por restrições de rede)
        try {
          // Verificar se o dispositivo tem conectividade fazendo uma tentativa de carga do anúncio
          _interstitialLoadAttempts = 0;
          _rewardedLoadAttempts = 0;
          _loadInterstitialAd();
          diagnosticReport['iosNetworkCheck'] = 'Tentativa de carga iniciada';
        } catch (e) {
          diagnosticReport['iosNetworkError'] = e.toString();
        }
      }
    } else {
      diagnosticReport['actions'].add('Usuário premium, anúncios desativados');
    }

    debugPrint(
        'AdManager: Diagnóstico concluído: ${diagnosticReport['actions'].join(
            ', ')}');
    return diagnosticReport;
  }

  /// Configura monitoramento de ciclo de vida do aplicativo para recarregar anúncios quando necessário
  void _setupAppLifecycleMonitoring() {
    if (!_lifecycleObserverRegistered) {
      WidgetsBinding.instance.addObserver(this);
      _lifecycleObserverRegistered = true;
      debugPrint('AdManager: Observador de ciclo de vida registrado');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('AdManager: Mudança no ciclo de vida do app - $state');

    if (state == AppLifecycleState.resumed) {
      // O app voltou para o primeiro plano - verificar anúncios
      _checkAdsAfterResume();
    } else if (state == AppLifecycleState.paused) {
      // O app foi para segundo plano
      debugPrint('AdManager: App em segundo plano');
    }
  }

  /// Verifica o estado dos anúncios após o app voltar ao primeiro plano
  Future<void> _checkAdsAfterResume() async {
    if (_isPremium) return;
    if (!_isInitialized) return;

    debugPrint(
        'AdManager: Verificando anúncios após retorno ao primeiro plano');

    // Verifica se precisamos recarregar anúncios intersticiais
    if (_interstitialAd == null) {
      debugPrint('AdManager: Recarregando anúncio intersticial após retorno');
      _loadInterstitialAd();
    }

    // Verifica se precisamos recarregar anúncios recompensados
    if (_rewardedAd == null) {
      debugPrint('AdManager: Recarregando anúncio recompensado após retorno');
      _loadRewardedAd();
    }

    // Para iOS, às vezes precisamos verificar se o status premium mudou
    if (Platform.isIOS) {
      try {
        // Verifica se o status premium foi alterado enquanto o app estava em segundo plano
        await _loadPremiumStatus();
        if (_isPremium) {
          _disposeAllAds();
        }
      } catch (e) {
        debugPrint(
            'AdManager: Erro ao verificar status premium após retorno: $e');
      }
    }
  }
}
