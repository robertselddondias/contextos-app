// lib/presentation/widgets/app_lifecycle_wrapper.dart
import 'package:contextual/presentation/blocs/game/game_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Widget que monitora o ciclo de vida do aplicativo e notifica o GameBloc
/// quando o aplicativo volta ao primeiro plano para verificar novas palavras
class AppLifecycleWrapper extends StatefulWidget {
  final Widget child;

  const AppLifecycleWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<AppLifecycleWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      // Notifica o GameBloc para verificar por novas palavras
      if (mounted) {
        try {
          final gameBloc = context.read<GameBloc>();
          // Aciona a função onAppResume no GameBloc
          gameBloc.onAppResume();
          // Também aciona o evento GameRefreshDaily para garantir
          gameBloc.add(const GameRefreshDaily());
        } catch (e) {
          debugPrint('Error notifying GameBloc on app resume: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
