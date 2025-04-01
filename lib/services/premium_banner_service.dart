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
  static const int _defaultMinIntervalHours = 24; // Intervalo mínimo entre exibições (24h = 1 dia)
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

      // Verifica se o banner já foi exibido hoje
      if (await _wasBannerShownToday()) {
        _shouldShowBanner = false;
        _showBannerController.add(false);
        debugPrint('PremiumBannerService: Banner já foi exibido hoje, não será mostrado novamente');
      } else {
        // Se não foi exibido hoje, verifica outras condições
        await _checkShouldShowBanner();
      }

      // Escutar mudanças nas compras para atualizar o estado do banner
      _purchaseManager.purchaseStateStream.listen((isPremium) {
        if (isPremium) {
          _shouldShowBanner = false;
          _showBannerController.add(false);
        }
      });

      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('PremiumBannerService inicializado: exibir banner = $_shouldShowBanner');
        debugPrint('Configuração: $_config');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao inicializar PremiumBannerService: $e');
      }

      // Mesmo com erro, marcamos como inicializado
      _isInitialized = true;
      _shouldShowBanner = false; // Não mostra o banner em caso de erro
      _showBannerController.add(false);
    }
  }

  /// Verifica se o banner já foi exibido hoje
  Future<bool> _wasBannerShownToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShownStr = prefs.getString(_prefKeyLastShown);

    if (lastShownStr == null) {
      return false; // Nunca foi mostrado
    }

    final lastShown = DateTime.parse(lastShownStr);
    final now = DateTime.now();

    // Verifica se a data da última exibição é a mesma de hoje
    return lastShown.year == now.year &&
        lastShown.month == now.month &&
        lastShown.day == now.day;
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
          debugPrint('Configurações do banner premium carregadas do Firebase');
        }
      } else {
        _config = _getDefaultConfig();

        if (kDebugMode) {
          debugPrint('Configurações padrão do banner premium carregadas (Firebase não disponível)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao carregar configurações do Firebase: $e');
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
    // Use o novo método para verificar
    _shouldShowBanner = await shouldShowBannerInMainScreen();
    _showBannerController.add(_shouldShowBanner);
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
        debugPrint('Banner premium marcado como exibido. Total de exibições: ${currentCount + 1}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao registrar exibição do banner: $e');
      }
    }
  }

  /// Notifica o serviço sobre uma nova sessão de jogo
  Future<void> trackGameSession({bool gameCompleted = false}) async {
    if (!_isInitialized) await initialize();

    // Verifica se já é premium
    if (_purchaseManager.removeAdsActive) return;

    // Verifica se o banner já foi exibido hoje
    if (await _wasBannerShownToday()) {
      return; // Não mostra novamente no mesmo dia
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // Verifica se devemos mostrar após conclusão do jogo
      final showAfterComplete = _config['show_after_game_complete'] ?? true;

      if (gameCompleted && showAfterComplete) {
        _shouldShowBanner = true;
        _showBannerController.add(true);
        return;
      }

      // Se não foi após conclusão, verificamos o número mínimo de sessões
      final sessionCount = prefs.getInt('game_session_count') ?? 0;
      final newCount = sessionCount + 1;
      await prefs.setInt('game_session_count', newCount);

      final minSessions = _config['min_game_sessions'] ?? _defaultMinGameSessions;

      if (newCount >= minSessions) {
        _shouldShowBanner = true;
        _showBannerController.add(true);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro ao rastrear sessão de jogo: $e');
      }
    }
  }

  /// Força a exibição do banner (útil para debugging)
  void forceShowBanner() {
    _shouldShowBanner = true;
    _showBannerController.add(true);
    if (kDebugMode) {
      debugPrint('PremiumBannerService: Banner forçado manualmente');
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

  /// Limpa os dados do banner (para testes)
  Future<void> resetBannerData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyLastShown);
      await prefs.remove(_prefKeyShowCount);
      debugPrint('PremiumBannerService: Dados do banner resetados');
    } catch (e) {
      debugPrint('PremiumBannerService: Erro ao resetar dados do banner: $e');
    }
  }

  Future<bool> shouldShowBannerInMainScreen() async {
    if (!_isInitialized) {
      await initialize();
    }

    // Se o banner não está ativo nas configurações ou o usuário é premium, não mostramos
    if (_config['active'] != true || _purchaseManager.removeAdsActive) {
      return false;
    }

    // Verifica outras condições como contagem de exibições e intervalo de tempo
    try {
      final prefs = await SharedPreferences.getInstance();

      // Verifica o número de exibições
      final showCount = prefs.getInt(_prefKeyShowCount) ?? 0;
      final maxShows = _config['max_shows_per_user'] ?? _defaultMaxShowsPerUser;

      if (showCount >= maxShows) {
        return false;
      }

      // Verifica o intervalo desde a última exibição
      final lastShownStr = prefs.getString(_prefKeyLastShown);
      final minIntervalHours = _config['min_interval_hours'] ?? _defaultMinIntervalHours;

      if (lastShownStr != null) {
        final lastShown = DateTime.parse(lastShownStr);
        final now = DateTime.now();
        final hoursSinceLastShown = now.difference(lastShown).inHours;

        if (hoursSinceLastShown < minIntervalHours) {
          return false;
        }
      }

      // Se chegou até aqui, o banner pode ser mostrado
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('PremiumBannerService: erro ao verificar condições para mostrar banner: $e');
      }
      return false;
    }
  }

  /// Libera recursos
  void dispose() {
    _showBannerController.close();
  }
}
