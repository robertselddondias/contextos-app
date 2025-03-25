import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço que gerencia a integração com Game Center (iOS) e
/// Google Play Games Services (Android)
class GameServicesManager {
  // Singleton
  static final GameServicesManager _instance = GameServicesManager._internal();
  factory GameServicesManager() => _instance;
  GameServicesManager._internal();

  // Status de inicialização
  bool _isInitialized = false;
  bool _isSignedIn = false;
  bool _isAvailable = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSignedIn => _isSignedIn;
  bool get isAvailable => _isAvailable;

  // IDs de conquistas e leaderboards
  // Nota: você precisará substituir estes IDs pelos IDs reais criados no
  // Google Play Console e iTunes Connect
  static final String _leaderboardID = Platform.isIOS
      ? 'contextual'
      : 'your_android_leaderboard_id';

  static final Map<String, String> _achievementIDs = {
    'first_word': Platform.isIOS
        ? 'your_ios_first_word_achievement_id'
        : 'your_android_first_word_achievement_id',
    'first_win': Platform.isIOS
        ? 'your_ios_first_win_achievement_id'
        : 'your_android_first_win_achievement_id',
    'win_streak_3': Platform.isIOS
        ? 'your_ios_win_streak_3_achievement_id'
        : 'your_android_win_streak_3_achievement_id',
    'win_streak_5': Platform.isIOS
        ? 'your_ios_win_streak_5_achievement_id'
        : 'your_android_win_streak_5_achievement_id',
    'win_streak_10': Platform.isIOS
        ? 'your_ios_win_streak_10_achievement_id'
        : 'your_android_win_streak_10_achievement_id',
    'perfect_score': Platform.isIOS
        ? 'your_ios_perfect_score_achievement_id'
        : 'your_android_perfect_score_achievement_id',
  };

  /// Inicializa o serviço de jogos
  Future<bool> initialize() async {
    // Se já inicializado, retorne imediatamente
    if (_isInitialized) return _isSignedIn;

    try {
      // Em ambiente de debug/desenvolvimento, podemos pular esta inicialização
      if (kDebugMode && !Platform.isIOS) {
        _isInitialized = true;
        debugPrint('GameServicesManager: inicialização ignorada no modo de depuração');
        return false;
      }

      // Verificar se os serviços estão disponíveis
      final signedIn = await GamesServices.isSignedIn;
      _isAvailable = true;

      if (signedIn) {
        _isSignedIn = true;
        debugPrint('GameServicesManager: usuário já está logado');
      } else {
        // Tenta fazer login automaticamente
        await _signIn();
      }

      _isInitialized = true;
      return _isSignedIn;
    } catch (e) {
      debugPrint('GameServicesManager: erro durante a inicialização: $e');
      // Em caso de erro, marcamos como inicializado para evitar novas tentativas
      _isInitialized = true;
      _isAvailable = false;
      return false;
    }
  }

  /// Realiza o login no serviço de jogos
  Future<bool> _signIn() async {
    try {
      await GamesServices.signIn();
      _isSignedIn = true;
      debugPrint('GameServicesManager: login realizado com sucesso');
      return true;
    } catch (e) {
      debugPrint('GameServicesManager: erro ao fazer login: $e');
      _isSignedIn = false;
      return false;
    }
  }

  /// Tenta fazer login explicitamente (pode ser chamado por um botão)
  Future<bool> signInExplicitly() async {
    if (!_isInitialized) await initialize();
    if (_isSignedIn) return true;
    return _signIn();
  }

  /// Submete uma pontuação para o leaderboard
  Future<bool> submitScore(int score) async {
    if (!_isInitialized) await initialize();
    if (!_isSignedIn || !_isAvailable) return false;

    try {
      await GamesServices.submitScore(
          score: Score(
              androidLeaderboardID: Platform.isAndroid ? _leaderboardID : null,
              iOSLeaderboardID: Platform.isIOS ? _leaderboardID : null,
              value: score
          )
      );

      debugPrint('GameServicesManager: pontuação $score enviada com sucesso');
      return true;
    } catch (e) {
      debugPrint('GameServicesManager: erro ao enviar pontuação: $e');
      return false;
    }
  }

  /// Mostra o leaderboard
  Future<bool> showLeaderboard() async {
    if (!_isInitialized) await initialize();
    if (!_isAvailable) return false;

    try {
      // No iOS, isso vai solicitar login se o usuário não estiver logado
      await GamesServices.showLeaderboards(
        androidLeaderboardID: Platform.isAndroid ? _leaderboardID : null,
        iOSLeaderboardID: Platform.isIOS ? _leaderboardID : null,
      );

      debugPrint('GameServicesManager: leaderboard exibido com sucesso');
      return true;
    } catch (e) {
      debugPrint('GameServicesManager: erro ao exibir leaderboard: $e');
      return false;
    }
  }

  /// Desbloqueia uma conquista
  Future<bool> unlockAchievement(String achievementId, {double percentComplete = 100.0}) async {
    if (!_isInitialized) await initialize();
    if (!_isSignedIn || !_isAvailable) return false;

    // Verificar se a conquista existe no mapa
    if (!_achievementIDs.containsKey(achievementId)) {
      debugPrint('GameServicesManager: conquista $achievementId não encontrada');
      return false;
    }

    // Verificar se a conquista já foi desbloqueada
    final prefs = await SharedPreferences.getInstance();
    final achievementKey = 'achievement_$achievementId';
    final alreadyUnlocked = prefs.getBool(achievementKey) ?? false;

    if (alreadyUnlocked && percentComplete >= 100.0) {
      debugPrint('GameServicesManager: conquista $achievementId já foi desbloqueada');
      return true;
    }

    try {
      final id = _achievementIDs[achievementId];

      await GamesServices.unlock(
        achievement: Achievement(
          androidID: Platform.isAndroid && id != null ? id : '',
          iOSID: Platform.isIOS && id != null ? id : '',
          percentComplete: percentComplete,
        ),
      );

      // Salvar localmente que a conquista foi desbloqueada
      if (percentComplete >= 100.0) {
        await prefs.setBool(achievementKey, true);
      }

      debugPrint('GameServicesManager: conquista $achievementId desbloqueada com sucesso');
      return true;
    } catch (e) {
      debugPrint('GameServicesManager: erro ao desbloquear conquista: $e');
      return false;
    }
  }

  /// Mostra todas as conquistas
  Future<bool> showAchievements() async {
    if (!_isInitialized) await initialize();
    if (!_isAvailable) return false;

    try {
      // No iOS, isso vai solicitar login se o usuário não estiver logado
      await GamesServices.showAchievements();
      debugPrint('GameServicesManager: conquistas exibidas com sucesso');
      return true;
    } catch (e) {
      debugPrint('GameServicesManager: erro ao exibir conquistas: $e');
      return false;
    }
  }

  /// Incrementa uma conquista baseada em progresso
  Future<bool> incrementAchievement(String achievementId, int steps) async {
    if (!_isInitialized) await initialize();
    if (!_isSignedIn || !_isAvailable) return false;

    // Verificar se a conquista existe no mapa
    if (!_achievementIDs.containsKey(achievementId)) {
      debugPrint('GameServicesManager: conquista $achievementId não encontrada');
      return false;
    }

    try {
      final id = _achievementIDs[achievementId];

      await GamesServices.increment(
        achievement: Achievement(
          androidID: Platform.isAndroid ? (id ?? '') : '',
          iOSID: Platform.isIOS ? (id ?? '') : '',
          steps: steps,
        ),
      );

      debugPrint('GameServicesManager: conquista $achievementId incrementada em $steps passos');
      return true;
    } catch (e) {
      debugPrint('GameServicesManager: erro ao incrementar conquista: $e');
      return false;
    }
  }

  /// Salva o jogo na nuvem (Google Play Games apenas)
  Future<bool> saveGame(String saveData) async {
    if (!_isInitialized) await initialize();
    if (!_isSignedIn || !_isAvailable || Platform.isIOS) return false;

    try {
      // Nota: a funcionalidade de salvamento em nuvem não está
      // implementada no pacote games_services atualmente
      // Esta é apenas uma implementação ilustrativa
      /*
      await GamesServices.saveGame(
        data: saveData,
        name: "ContextoSave",
      );
      */

      debugPrint('GameServicesManager: funcionalidade de salvamento na nuvem não implementada');
      return false;
    } catch (e) {
      debugPrint('GameServicesManager: erro ao salvar jogo: $e');
      return false;
    }
  }

  /// Recompensa o jogador por uma vitória no jogo
  Future<void> processGameWin(int attempts) async {
    // Desbloqueia a conquista de primeira vitória
    await unlockAchievement('first_win');

    // Envia a pontuação para o leaderboard
    // Calcule a pontuação baseada no número de tentativas (quanto menor, melhor)
    int score = 1000 - (attempts * 50);
    if (score < 100) score = 100; // pontuação mínima

    await submitScore(score);

    // Se foi uma pontuação perfeita (apenas uma tentativa)
    if (attempts == 1) {
      await unlockAchievement('perfect_score');
    }

    // Atualiza sequência de vitórias
    await _updateWinStreak();
  }

  /// Atualiza e verifica as conquistas de sequência de vitórias
  Future<void> _updateWinStreak() async {
    final prefs = await SharedPreferences.getInstance();
    int winStreak = prefs.getInt('win_streak') ?? 0;
    winStreak++;

    await prefs.setInt('win_streak', winStreak);

    // Verifica conquistas baseadas em sequência
    if (winStreak >= 3) {
      await unlockAchievement('win_streak_3');
    }

    if (winStreak >= 5) {
      await unlockAchievement('win_streak_5');
    }

    if (winStreak >= 10) {
      await unlockAchievement('win_streak_10');
    }
  }

  /// Registra uma derrota e reinicia a sequência de vitórias
  Future<void> processGameLoss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('win_streak', 0);
  }

  /// Processa a primeira palavra adivinhada
  Future<void> processFirstWord() async {
    await unlockAchievement('first_word');
  }
}
