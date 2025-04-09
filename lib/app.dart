// Arquivo: lib/app.dart (modificado)
import 'package:contextual/core/routes/app_routes.dart';
import 'package:contextual/core/theme/app_theme.dart';
import 'package:contextual/presentation/blocs/game/game_bloc.dart';
import 'package:contextual/presentation/blocs/settings/settings_bloc.dart';
import 'package:contextual/presentation/screens/onboarding_screen.dart';
import 'package:contextual/presentation/screens/splash_screen.dart';
import 'package:contextual/presentation/widgets/app_lifecycle_wrapper.dart';
import 'package:contextual/presentation/widgets/premium_banner_wrapper.dart';
import 'package:contextual/utils/keyboard_dismisser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContextoApp extends StatelessWidget {
  const ContextoApp({super.key});

  // Função para verificar se deve mostrar o onboarding
  Future<bool> _shouldShowOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool('showedOnboarding') ?? false);
    } catch (e) {
      // Em caso de erro, retornamos false para ir direto para o app
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBannerWrapper(
      child: MultiBlocProvider(
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
            // Envolve o GetMaterialApp com o AppLifecycleWrapper e o AppKeyboardManager
            return AppLifecycleWrapper(
              child: AppKeyboardManager(
                child: GetMaterialApp(
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
                  getPages: [
                    // Converta as rotas do MaterialApp para rotas do GetX
                    for (var entry in AppRoutes.routes.entries)
                      GetPage(
                          name: entry.key,
                          page: () => entry.value(context)
                      ),
                  ],
                  initialRoute: AppRoutes.splash,
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
              ),
            );
          },
        ),
      ),
    );
  }
}
