// lib/presentation/widgets/date_change_detector.dart
import 'package:contextual/presentation/blocs/game/game_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Widget que monitora alterações de data e atualiza a palavra do dia quando necessário
class DateChangeDetector extends StatefulWidget {
  final Widget child;

  const DateChangeDetector({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<DateChangeDetector> createState() => _DateChangeDetectorState();
}

class _DateChangeDetectorState extends State<DateChangeDetector> with WidgetsBindingObserver {
  DateTime? _lastCheckDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Verifica na inicialização
    _checkDateChange();

    // Registra a data atual
    _lastCheckDate = DateTime.now();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Quando o app volta para o primeiro plano (retomado)
    if (state == AppLifecycleState.resumed) {
      _checkDateChange();
    }
  }

  void _checkDateChange() {
    final now = DateTime.now();

    // Se não temos registro anterior OU a data mudou
    if (_lastCheckDate == null ||
        _lastCheckDate!.day != now.day ||
        _lastCheckDate!.month != now.month ||
        _lastCheckDate!.year != now.year) {

      // Atualiza a data de verificação
      _lastCheckDate = now;

      // Busca o GameBloc via BlocProvider e aciona a verificação
      // (Aguarda alguns milissegundos para garantir que o BlocProvider esteja disponível)
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          final gameBloc = context.read<GameBloc>();
          gameBloc.checkDailyWordUpdate();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
