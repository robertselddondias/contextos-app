// lib/presentation/widgets/app_lifecycle_observer.dart
import 'package:contextual/presentation/blocs/game/game_bloc.dart';
import 'package:contextual/services/smart_notification_service.dart';
import 'package:contextual/services/user_activity_tracker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Widget que detecta mudanças no ciclo de vida do aplicativo
/// e realiza várias tarefas: atualiza a palavra do dia, rastreia atividade e agenda notificações
class AppLifecycleObserver extends StatefulWidget {
  final Widget child;

  const AppLifecycleObserver({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver> with WidgetsBindingObserver {
  // Data da última verificação para evitar verificações repetidas
  DateTime? _lastCheck;

  // Serviços
  final UserActivityTracker _activityTracker = UserActivityTracker();
  final SmartNotificationService _notificationService = SmartNotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastCheck = DateTime.now();

    // Inicializa serviços
    _initializeServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Inicializa os serviços necessários
  Future<void> _initializeServices() async {
    try {
      // Registra a atual sessão de uso
      await _activityTracker.trackAppOpened();

      // Inicializa o serviço de notificações
      await _notificationService.initialize();

      // Reagenda notificações (útil após reinstalação ou atualização do app)
      await _notificationService.rescheduleNotificationsIfEnabled();
    } catch (e) {
      debugPrint('Erro ao inicializar serviços: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Quando o app é retomado
    if (state == AppLifecycleState.resumed) {
      // Registra a atividade do usuário
      _activityTracker.trackAppOpened();

      final now = DateTime.now();

      // Verifica se já passou pelo menos 5 minutos desde a última verificação
      // ou se a data mudou desde a última verificação
      if (_lastCheck == null ||
          now.difference(_lastCheck!).inMinutes >= 5 ||
          now.day != _lastCheck!.day ||
          now.month != _lastCheck!.month ||
          now.year != _lastCheck!.year) {

        // Atualiza a data da última verificação
        _lastCheck = now;

        // Verifica se há uma nova palavra do dia
        final gameBloc = context.read<GameBloc>();
        gameBloc.checkDailyWordUpdate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
