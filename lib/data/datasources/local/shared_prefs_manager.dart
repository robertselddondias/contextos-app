// data/datasources/local/shared_prefs_manager.dart
import 'dart:convert';

import 'package:contextual/core/constants/app_constants.dart';
import 'package:contextual/data/models/game_state.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SharedPrefsManager {
  Future<void> saveGameState(GameStateModel gameState);
  Future<GameStateModel?> getGameState();
  Future<void> clearGameState();

  Future<void> saveBestScore(int score);
  Future<int> getBestScore();

  Future<void> saveThemeMode(ThemeMode themeMode);
  Future<ThemeMode> getThemeMode();

  Future<void> saveLocale(Locale locale);
  Future<Locale?> getLocale();

  Future<void> saveDailyWord(String word, String dailyWordId);
  Future<String?> getDailyWord(String dailyWordId);

  Future<void> cacheWordSimilarity(String word1, String word2, double similarity);
  Future<double?> getCachedWordSimilarity(String word1, String word2);
}

class SharedPrefsManagerImpl implements SharedPrefsManager {
  final SharedPreferences _prefs;

  SharedPrefsManagerImpl(this._prefs);

  @override
  Future<void> saveGameState(GameStateModel gameState) async {
    final jsonString = json.encode(gameState.toJson());
    await _prefs.setString(AppConstants.prefsKeyGameState, jsonString);

    // Também salvamos a data do último jogo
    await _prefs.setString(
      AppConstants.prefsKeyLastPlayed,
      DateTime.now().toString().split(' ')[0],
    );
  }

  @override
  Future<GameStateModel?> getGameState() async {
    final jsonString = _prefs.getString(AppConstants.prefsKeyGameState);
    if (jsonString == null) return null;

    try {
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return GameStateModel.fromJson(jsonMap);
    } catch (e) {
      // Em caso de erro, retornamos null para começar um novo jogo
      return null;
    }
  }

  @override
  Future<void> clearGameState() async {
    await _prefs.remove(AppConstants.prefsKeyGameState);
    await _prefs.remove(AppConstants.prefsKeyLastPlayed);
  }

  @override
  Future<void> saveBestScore(int score) async {
    final currentBest = await getBestScore();
    // Salvamos apenas se for melhor que o atual
    if (currentBest == 0 || score < currentBest) {
      await _prefs.setInt(AppConstants.prefsKeyBestScore, score);
    }
  }

  @override
  Future<int> getBestScore() async {
    return _prefs.getInt(AppConstants.prefsKeyBestScore) ?? 0;
  }

  @override
  Future<void> saveThemeMode(ThemeMode themeMode) async {
    await _prefs.setInt(
      AppConstants.prefsKeyThemeMode,
      themeMode.index,
    );
  }

  @override
  Future<ThemeMode> getThemeMode() async {
    final index = _prefs.getInt(AppConstants.prefsKeyThemeMode);
    if (index == null) return ThemeMode.system;

    return ThemeMode.values[index];
  }

  @override
  Future<void> saveLocale(Locale locale) async {
    await _prefs.setString(
      AppConstants.prefsKeyLocale,
      '${locale.languageCode}_${locale.countryCode ?? ''}',
    );
  }

  @override
  Future<Locale?> getLocale() async {
    final localeString = _prefs.getString(AppConstants.prefsKeyLocale);
    if (localeString == null) return null;

    final parts = localeString.split('_');
    if (parts.isEmpty) return null;

    final languageCode = parts[0];
    final countryCode = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : null;

    return Locale(languageCode, countryCode);
  }

  @override
  Future<void> saveDailyWord(String word, String dailyWordId) async {
    await _prefs.setString(
      '${AppConstants.prefsKeyDailyWord}_$dailyWordId',
      word,
    );
  }

  @override
  Future<String?> getDailyWord(String dailyWordId) async {
    return _prefs.getString('${AppConstants.prefsKeyDailyWord}_$dailyWordId');
  }

  @override
  Future<void> cacheWordSimilarity(String word1, String word2, double similarity) async {
    // Normalizamos as palavras para lowercase para garantir consistência
    word1 = word1.toLowerCase();
    word2 = word2.toLowerCase();

    // Garantimos uma ordem consistente das palavras no cache
    if (word1.compareTo(word2) > 0) {
      final temp = word1;
      word1 = word2;
      word2 = temp;
    }

    final key = 'similarity_${word1}_$word2';
    await _prefs.setDouble(key, similarity);

    // Adicionamos a entrada ao índice de similaridades para poder limpar o cache posteriormente
    final index = _prefs.getStringList('similarity_index') ?? [];
    if (!index.contains(key)) {
      index.add(key);
      await _prefs.setStringList('similarity_index', index);

      // Limitamos o tamanho do cache
      if (index.length > 1000) {
        // Remove as entradas mais antigas
        final keysToRemove = index.sublist(0, 200);
        for (final keyToRemove in keysToRemove) {
          await _prefs.remove(keyToRemove);
        }

        // Atualiza o índice
        await _prefs.setStringList('similarity_index', index.sublist(200));
      }
    }
  }

  @override
  Future<double?> getCachedWordSimilarity(String word1, String word2) async {
    // Normalizamos as palavras para lowercase para garantir consistência
    word1 = word1.toLowerCase();
    word2 = word2.toLowerCase();

    // Garantimos uma ordem consistente das palavras no cache
    if (word1.compareTo(word2) > 0) {
      final temp = word1;
      word1 = word2;
      word2 = temp;
    }

    final key = 'similarity_${word1}_$word2';
    return _prefs.getDouble(key);
  }
}
