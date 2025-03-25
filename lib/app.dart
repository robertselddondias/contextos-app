import 'package:contextual/core/routes/app_routes.dart';
import 'package:contextual/core/theme/app_theme.dart';
import 'package:contextual/presentation/blocs/game/game_bloc.dart';
import 'package:contextual/presentation/blocs/settings/settings_bloc.dart';
import 'package:contextual/presentation/screens/onboarding_screen.dart';
import 'package:contextual/presentation/screens/splash_screen.dart';
import 'package:contextual/utils/keyboard_dismisser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContextoApp extends StatelessWidget {
  const ContextoApp({super.key});

  Future<bool> _shouldShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('showedOnboarding') ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<GameBloc>(
          create: (_) => GetIt.I<GameBloc>()..add(const GameInitialized()),
        ),
        BlocProvider<SettingsBloc>(
          create: (_) => GetIt.I<SettingsBloc>()..add(const SettingsLoaded()),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        buildWhen: (previous, current) =>
        previous.themeMode != current.themeMode ||
            previous.locale != current.locale,
        builder: (context, state) {
          // Envolva o MaterialApp com o AppKeyboardManager
          return AppKeyboardManager(
            child: MaterialApp(
              title: 'Contexto',
              debugShowCheckedModeBanner: false,
              themeMode: state.themeMode,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('pt', 'BR'),
                Locale('en', 'US'),
                Locale('es', 'ES'),
              ],
              locale: state.locale,
              routes: AppRoutes.routes,
              home: FutureBuilder<bool>(
                future: _shouldShowOnboarding(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SplashScreen();
                  }

                  final shouldShowOnboarding = snapshot.data ?? false;

                  if (shouldShowOnboarding) {
                    return const OnboardingScreen();
                  } else {
                    return const SplashScreen();
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
