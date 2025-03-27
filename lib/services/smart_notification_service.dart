// lib/services/smart_notification_service.dart
import 'package:contextual/services/user_activity_tracker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Serviço para gerenciar notificações inteligentes baseadas nos padrões de uso
class SmartNotificationService {
  // Singleton
  static final SmartNotificationService _instance = SmartNotificationService._internal();
  factory SmartNotificationService() => _instance;
  SmartNotificationService._internal();

  // Plugin de notificações
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Rastreador de atividade
  final UserActivityTracker _activityTracker = UserActivityTracker();

  // Status
  bool _isInitialized = false;

  // Chave para preferências
  static const String _prefKeyNotificationsEnabled = 'smart_notifications_enabled';

  // ID da notificação diária
  static const int _dailyNotificationId = 1001;

  /// Inicializa o serviço de notificações
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Inicializa timezone
      tz.initializeTimeZones();

      // Configuração para Android
      final AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configuração para iOS
      final DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

      // Configuração geral
      final InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Inicializar plugin
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      // Criar canal para Android
      await _createNotificationChannel();

      // Verificar permissões e agendar notificação inicial
      final notificationsEnabled = await isEnabled();
      if (notificationsEnabled) {
        await scheduleNextNotification();
      }

      _isInitialized = true;

      if (kDebugMode) {
        print('SmartNotificationService inicializado com sucesso');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao inicializar SmartNotificationService: $e');
      }
    }
  }

  /// Handler para notificações locais iOS (para versões anteriores do iOS)
  void _onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) {
    if (kDebugMode) {
      print('Recebida notificação local iOS: $id, $title, $body, $payload');
    }
  }

  /// Handler para respostas de notificações
  void _onNotificationResponse(NotificationResponse response) {
    if (kDebugMode) {
      print('Resposta de notificação: ${response.id}, ${response.payload}');
    }
  }

  /// Cria o canal de notificação para Android
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'smart_reminder_channel',
      'Lembretes Inteligentes',
      description: 'Notificações adaptadas aos seus horários de jogo',
      importance: Importance.high,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Verifica se as notificações inteligentes estão habilitadas
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyNotificationsEnabled) ?? false;
  }

  /// Ativa ou desativa as notificações inteligentes
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyNotificationsEnabled, enabled);

    if (enabled) {
      // Se habilitado, agenda a próxima notificação
      await scheduleNextNotification();
    } else {
      // Se desabilitado, cancela todas as notificações agendadas
      await _notifications.cancelAll();
    }
  }

  /// Agenda a próxima notificação baseada nos padrões de uso
  Future<void> scheduleNextNotification() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Cancela notificações anteriores
      await _notifications.cancel(_dailyNotificationId);

      // Verifica se temos dados suficientes para determinar o horário ideal
      final hasData = await _activityTracker.hasEnoughData();

      // Determina o horário para a notificação
      final DateTime scheduledDate = await _determineNotificationTime(hasData);

      // Se a data calculada já passou, não agenda
      if (scheduledDate.isBefore(DateTime.now())) {
        if (kDebugMode) {
          print('Data calculada já passou, não agendando notificação');
        }
        return;
      }

      // Converte para timezone
      final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(
        scheduledDate,
        tz.local,
      );

      // Conteúdo da notificação
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'smart_reminder_channel',
        'Lembretes Inteligentes',
        channelDescription: 'Notificações adaptadas aos seus horários de jogo',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'Nova palavra disponível',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Agenda a notificação
      await _notifications.zonedSchedule(
        _dailyNotificationId,
        'Nova palavra disponível!',
        'Descubra a palavra do dia e desafie-se novamente!',
        tzScheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      if (kDebugMode) {
        print('Próxima notificação agendada para: $scheduledDate');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao agendar notificação: $e');
      }
    }
  }

  /// Determina o melhor horário para enviar a notificação
  Future<DateTime> _determineNotificationTime(bool hasEnoughData) async {
    DateTime now = DateTime.now();

    if (hasEnoughData) {
      // Se temos dados suficientes, usamos o horário preferido do usuário
      final preferredHour = await _activityTracker.getPreferredHour();

      if (preferredHour != null) {
        // Cria uma data para hoje no horário preferido
        DateTime preferredTime = DateTime(
          now.year,
          now.month,
          now.day,
          preferredHour,
          0, // minutos
        );

        // Se o horário já passou hoje, agenda para amanhã
        if (preferredTime.isBefore(now)) {
          preferredTime = preferredTime.add(const Duration(days: 1));
        }

        return preferredTime;
      }
    }

    // Fallback - se não temos dados suficientes, usamos um horário padrão
    // Notificação às 9:00 da manhã do dia seguinte
    DateTime defaultTime = DateTime(
      now.year,
      now.month,
      now.day,
      9, // 9:00 da manhã
      0,
    );

    // Se já passou das 9:00, programa para amanhã
    if (defaultTime.isBefore(now)) {
      defaultTime = defaultTime.add(const Duration(days: 1));
    }

    return defaultTime;
  }

  /// Notifica imediatamente (útil para testes)
  Future<void> sendTestNotification() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'smart_reminder_channel',
        'Lembretes Inteligentes',
        channelDescription: 'Notificações adaptadas aos seus horários de jogo',
        importance: Importance.high,
        priority: Priority.high,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Envia a notificação teste
      await _notifications.show(
        1002, // ID diferente para não conflitar com a notificação diária
        'Notificação de Teste',
        'Esta é uma notificação de teste para verificar se está funcionando.',
        details,
      );

      if (kDebugMode) {
        print('Notificação de teste enviada');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao enviar notificação de teste: $e');
      }
    }
  }

  /// Solicita permissões para enviar notificações
  Future<bool> requestPermissions() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Para iOS
      final bool? iosPermission = await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Para Android >= 13 (API 33+)
      final bool? androidPermission = await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      // Se uma das permissões for concedida, consideramos habilitado
      final bool permissionsGranted = (iosPermission ?? false) || (androidPermission ?? false);

      // Se as permissões foram concedidas, ativamos as notificações
      if (permissionsGranted) {
        await setEnabled(true);
      }

      return permissionsGranted;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao solicitar permissões: $e');
      }
      return false;
    }
  }

  /// Reagenda as notificações quando o app é atualizado ou reinstalado
  Future<void> rescheduleNotificationsIfEnabled() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final enabled = await isEnabled();
      if (enabled) {
        await scheduleNextNotification();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao reagendar notificações: $e');
      }
    }
  }
}
