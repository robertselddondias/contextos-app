// core/routes/app_routes.dart
import 'package:contextual/presentation/screens/firestore_diagnostic_screen.dart';
import 'package:contextual/presentation/screens/game_screen.dart';
import 'package:contextual/presentation/screens/history_screen.dart';
import 'package:contextual/presentation/screens/onboarding_screen.dart';
import 'package:contextual/presentation/screens/settings_screen.dart';
import 'package:contextual/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  AppRoutes._();

  // Nomes das rotas
  static const String splash = '/splash';
  static const String game = '/game';
  static const String settings = '/settings';
  static const String history = '/history';
  static const String wordRelationDiagnostics = '/word_relation_diagnostics';
  static const String onboarding = '/onboarding';

  // Mapa de rotas
  static final Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    game: (context) => const GameScreen(),
    settings: (context) => const SettingsScreen(),
    history: (context) => const HistoryScreen(),
    wordRelationDiagnostics: (context) => const WordRelationDiagnosticScreen(),
    onboarding: (context) => const OnboardingScreen(),
  };

  // Função de geração de rotas
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Aqui poderíamos adicionar lógica adicional para rotas dinâmicas
    return null;
  }

  // Função para tratamento de rotas não encontradas
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Erro'),
        ),
        body: const Center(
          child: Text('Página não encontrada'),
        ),
      ),
    );
  }
}
