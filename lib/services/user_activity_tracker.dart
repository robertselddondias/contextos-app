// lib/services/user_activity_tracker.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Rastreia a atividade do usuário para determinar os melhores horários para notificações
class UserActivityTracker {
  // Singleton
  static final UserActivityTracker _instance = UserActivityTracker._internal();
  factory UserActivityTracker() => _instance;
  UserActivityTracker._internal();

  // Chaves para o SharedPreferences
  static const String _prefKeyLastSessions = 'user_sessions';
  static const String _prefKeyPreferredHour = 'preferred_hour';
  static const int _maxStoredSessions = 20; // Máximo de sessões para armazenar

  /// Registra a abertura do app
  Future<void> trackAppOpened() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Obter a data e hora atual
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;

      // Recuperar sessões anteriores
      final List<String> storedSessions = prefs.getStringList(_prefKeyLastSessions) ?? [];

      // Adicionar a sessão atual
      storedSessions.add(timestamp.toString());

      // Manter apenas as últimas X sessões
      if (storedSessions.length > _maxStoredSessions) {
        storedSessions.removeRange(0, storedSessions.length - _maxStoredSessions);
      }

      // Salvar as sessões
      await prefs.setStringList(_prefKeyLastSessions, storedSessions);

      // Analisar e atualizar o horário preferido
      _analyzeAndUpdatePreferredTime(prefs, storedSessions);

    } catch (e) {
      if (kDebugMode) {
        print('Erro ao rastrear atividade do usuário: $e');
      }
    }
  }

  /// Analisa as sessões do usuário e determina o horário preferido
  void _analyzeAndUpdatePreferredTime(SharedPreferences prefs, List<String> sessions) {
    try {
      // Converter strings para timestamps
      final List<int> timestamps = sessions
          .map((s) => int.tryParse(s) ?? 0)
          .where((t) => t > 0)
          .toList();

      if (timestamps.isEmpty) return;

      // Converter timestamps para horas do dia
      final List<int> hours = timestamps.map((t) {
        final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(t);
        return dateTime.hour;
      }).toList();

      // Contar a frequência de cada hora
      Map<int, int> hourFrequency = {};
      for (int hour in hours) {
        hourFrequency[hour] = (hourFrequency[hour] ?? 0) + 1;
      }

      // Encontrar a hora mais frequente
      int? preferredHour;
      int maxFrequency = 0;

      hourFrequency.forEach((hour, frequency) {
        if (frequency > maxFrequency) {
          maxFrequency = frequency;
          preferredHour = hour;
        }
      });

      // Só atualizamos se tivermos dados suficientes (pelo menos 3 sessões)
      if (preferredHour != null && sessions.length >= 3) {
        prefs.setInt(_prefKeyPreferredHour, preferredHour!);

        if (kDebugMode) {
          print('Horário preferido atualizado: $preferredHour:00');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao analisar horário preferido: $e');
      }
    }
  }

  /// Obtém o horário preferido do usuário (hora do dia, 0-23)
  Future<int?> getPreferredHour() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_prefKeyPreferredHour);
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao obter horário preferido: $e');
      }
      return null;
    }
  }

  /// Verifica se temos dados de sessão suficientes para determinar um padrão
  Future<bool> hasEnoughData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessions = prefs.getStringList(_prefKeyLastSessions) ?? [];
      return sessions.length >= 5; // Consideramos 5 sessões como mínimo para padrão
    } catch (e) {
      return false;
    }
  }
}
