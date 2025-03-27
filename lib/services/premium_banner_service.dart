// lib/services/premium_banner_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contextual/services/purchase_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço para gerenciar a exibição do banner premium
class PremiumBannerService {
  // Singleton
  static final PremiumBannerService _instance = PremiumBannerService._internal();
  factory PremiumBannerService() => _instance;
  PremiumBannerService._internal();

  // Constantes
  static const String _prefKeyLastShown = 'premium_banner_last_shown';
  static const String _prefKeyShowCount = 'premium_banner_show_count';
  static const String _configCollection = 'app_config';
  static const String _bannerConfigDoc = 'premium_banner';

  // Configurações padrão (fallback) caso não consiga buscar do Firebase
  static const int _defaultMinIntervalHours = 24; // Intervalo mínimo entre exibições
  static const int _defaultMinGameSessions = 3; // Sessões mínimas antes de mostrar
  static const int _defaultMaxShowsPerUser = 8; // Máximo de exibições por usuário

  // Estado interno
  bool _isInitialized = false;
  Map<String, dynamic> _config = {};
  final PurchaseManager _purchaseManager = PurchaseManager();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Armazena se o banner deve ser mostrado
  bool _shouldShowBanner = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get shouldShowBanner => _shouldShowBanner;

  // Stream para notificar mudanças nas configurações
  final StreamController<bool> _showBannerController = StreamController<bool>.broadcast();
  Stream<bool> get showBannerStream => _showBannerController.stream;

  /// Inicializa o serviço e carrega configurações
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Inicializa o PurchaseManager
      await _purchaseManager.initialize();

      // Se usuário já é premium, não mostramos o banner
      if (_purchaseManager.removeAdsActive) {
        _shouldShowBanner = false;
        _showBannerController.add(false);
        _isInitialized = true;
        return;
      }

      // Carrega configurações do Firebase
      await _loadConfigFromFirebase();

      // Verifica condições para mostrar o banner
      await _checkShouldShowBanner();

      // Escutar mudanças nas compras para atualizar o estado do banner
      _purchaseManager.purchaseStateStream.listen((isPremium) {
        if (isPremium) {
          _shouldShowBanner = false;
          _showBannerController.add(false);
        }
      });

      _isInitialized = true;

      if (kDebugMode) {
        print('PremiumBannerService inicializado: exibir banner = $_shouldShowBanner');
        print('Configuração: $_config');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao inicializar PremiumBannerService: $e');
      }

      // Mesmo com erro, marcamos como inicializado
      _isInitialized = true;
    }
  }

  /// Carrega configurações do Firebase
  Future<void> _loadConfigFromFirebase() async {
    try {
      final docSnapshot = await _firestore
          .collection(_configCollection)
          .doc(_bannerConfigDoc)
          .get();

      if (docSnapshot.exists) {
        _config = docSnapshot.data() ?? {};

        if (kDebugMode) {
          print('Configurações do banner premium carregadas do Firebase');
        }
      } else {
        _config = _getDefaultConfig();

        if (kDebugMode) {
          print('Configurações padrão do banner premium carregadas (Firebase não disponível)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar configurações do Firebase: $e');
      }

      // Usa configurações padrão em caso de erro
      _config = _getDefaultConfig();
    }
  }

  /// Retorna configurações padrão
  Map<String, dynamic> _getDefaultConfig() {
    return {
      'active': true,
      'min_interval_hours': _defaultMinIntervalHours,
      'min_game_sessions': _defaultMinGameSessions,
      'max_shows_per_user': _defaultMaxShowsPerUser,
      'show_after_game_complete': true,
      'primary_message': 'Remova os anúncios',
      'secondary_message': 'Jogue sem interrupções por apenas R\$19,90'
    };
  }

  /// Verifica se o banner deve ser mostrado com base nas configurações
  Future<void> _checkShouldShowBanner() async {
    // Se o banner não está ativo nas configurações, não mostramos
    if (_config['active'] != true) {
      _shouldShowBanner = false;
      _showBannerController.add(false);
      return;
    }

    // Se o usuário já é premium, não mostramos o banner
    if (_purchaseManager.removeAdsActive) {
      _shouldShowBanner = false;
      _showBannerController.add(false);
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    // Verifica o número de exibições
    final showCount = prefs.getInt(_prefKeyShowCount) ?? 0;
    final maxShows = _config['max_shows_per_user'] ?? _defaultMaxShowsPerUser;

    if (showCount >= maxShows) {
      _shouldShowBanner = false;
      _showBannerController.add(false);
      return;
    }

    // Verifica o intervalo desde a última exibição
    final lastShownStr = prefs.getString(_prefKeyLastShown);
    final minIntervalHours = _config['min_interval_hours'] ?? _defaultMinIntervalHours;

    if (lastShownStr != null) {
      final lastShown = DateTime.parse(lastShownStr);
      final now = DateTime.now();
      final hoursSinceLastShown = now.difference(lastShown).inHours;

      if (hoursSinceLastShown < minIntervalHours) {
        _shouldShowBanner = false;
        _showBannerController.add(false);
        return;
      }
    }

    // Se chegou até aqui, o banner pode ser mostrado
    _shouldShowBanner = true;
    _showBannerController.add(true);
  }

  /// Registra que o banner foi mostrado
  Future<void> markBannerAsShown() async {
    if (!_isInitialized) await initialize();

    try {
      final prefs = await SharedPreferences.getInstance();

      // Atualiza a data da última exibição
      await prefs.setString(_prefKeyLastShown, DateTime.now().toIso8601String());

      // Incrementa o contador de exibições
      final currentCount = prefs.getInt(_prefKeyShowCount) ?? 0;
      await prefs.setInt(_prefKeyShowCount, currentCount + 1);

      // Atualiza o estado
      _shouldShowBanner = false;
      _showBannerController.add(false);

      if (kDebugMode) {
        print('Banner premium marcado como exibido. Total de exibições: ${currentCount + 1}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao registrar exibição do banner: $e');
      }
    }
  }

  /// Notifica o serviço sobre uma nova sessão de jogo
  Future<void> trackGameSession({bool gameCompleted = false}) async {
    if (!_isInitialized) await initialize();

    // Verifica se já é premium
    if (_purchaseManager.removeAdsActive) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Verifica se devemos mostrar após conclusão do jogo
      final showAfterComplete = _config['show_after_game_complete'] ?? true;

      if (gameCompleted && showAfterComplete) {
        await _checkShouldShowBanner();
        return;
      }

      // Se não foi após conclusão, verificamos o número mínimo de sessões
      final sessionCount = prefs.getInt('game_session_count') ?? 0;
      final newCount = sessionCount + 1;
      await prefs.setInt('game_session_count', newCount);

      final minSessions = _config['min_game_sessions'] ?? _defaultMinGameSessions;

      if (newCount >= minSessions) {
        await _checkShouldShowBanner();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao rastrear sessão de jogo: $e');
      }
    }
  }

  /// Retorna as mensagens a serem exibidas no banner
  Map<String, String> getBannerMessages() {
    final primaryMessage = _config['primary_message'] as String? ?? 'Remova os anúncios';
    final secondaryMessage = _config['secondary_message'] as String? ??
        'Jogue sem interrupções por apenas R\$19,90';

    return {
      'primary': primaryMessage,
      'secondary': secondaryMessage,
    };
  }

  /// Libera recursos
  void dispose() {
    _showBannerController.close();
  }
}
