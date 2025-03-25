// core/di/dependency_injection.dart
import 'package:contextual/core/init/initialize_firestore.dart';
import 'package:contextual/data/datasources/local/shared_prefs_manager.dart';
import 'package:contextual/data/datasources/remote/firebase_context_service.dart';
import 'package:contextual/data/datasources/remote/firebase_nlp_service.dart';
import 'package:contextual/data/repositories/firebase_game_repository.dart';
import 'package:contextual/data/repositories/firebase_word_repository.dart';
import 'package:contextual/domain/repositories/game_repository.dart';
import 'package:contextual/domain/repositories/word_repository.dart';
import 'package:contextual/domain/usecases/calculate_similarity.dart';
import 'package:contextual/domain/usecases/get_daily_word.dart';
import 'package:contextual/domain/usecases/make_guess.dart';
import 'package:contextual/domain/usecases/save_game_state.dart';
import 'package:contextual/presentation/blocs/game/game_bloc.dart';
import 'package:contextual/presentation/blocs/settings/settings_bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

Future<void> initDependencies() async {
  // Dependências externas
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  // Adiciona log para debug se necessário
  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  getIt.registerSingleton<Dio>(dio);

  // Data sources
  getIt.registerLazySingleton<SharedPrefsManager>(
        () => SharedPrefsManagerImpl(getIt<SharedPreferences>()),
  );

  // Contexto do Firebase (serviço simplificado)
  getIt.registerLazySingleton<FirebaseContextService>(
        () => FirebaseContextService(),
  );

  // Serviço de NLP
  getIt.registerLazySingleton<NlpService>(
        () => FirebaseNlpService(getIt<Dio>()),
  );

  // Repositories
  getIt.registerLazySingleton<WordRepository>(
        () => FirebaseWordRepository(getIt<NlpService>()),
  );

  getIt.registerLazySingleton<GameRepository>(
        () => FirebaseGameRepository(getIt<SharedPreferences>()),
  );

  // Use cases
  getIt.registerLazySingleton(() => CalculateSimilarity(
    wordRepository: getIt<WordRepository>(),
  ));
  getIt.registerLazySingleton(() => GetDailyWord(
    wordRepository: getIt<WordRepository>(),
    gameRepository: getIt<GameRepository>(),
  ));
  getIt.registerLazySingleton(() => MakeGuess(
    gameRepository: getIt<GameRepository>(),
    calculateSimilarity: getIt<CalculateSimilarity>(),
  ));
  getIt.registerLazySingleton(() => SaveGameState(
    gameRepository: getIt<GameRepository>(),
  ));

  // BLoCs
  getIt.registerFactory(() => GameBloc(
    getDailyWord: getIt<GetDailyWord>(),
    makeGuess: getIt<MakeGuess>(),
    saveGameState: getIt<SaveGameState>(),
  ));
  getIt.registerFactory(() => SettingsBloc(
    localDataSource: getIt<SharedPrefsManager>(),
  ));

  // Inicializar serviços que precisam de inicialização
  // try {
  //   await getIt<FirebaseContextService>().initialize();
  //
  //   // Opcional: Popular com dados iniciais em ambiente de desenvolvimento
  //   if (kDebugMode) {
  //     // Verifica se já existem palavras
  //     final hasWords = await getIt<FirebaseContextService>().wordExists('gato');
  //     if (!hasWords) {
  //       // Se não existem palavras, popula com dados iniciais
  //       await WordRelationSeeder().seedBasicWords();
  //       if (kDebugMode) {
  //         print('Dados iniciais de palavras populados com sucesso!');
  //       }
  //     }
  //   }
  // } catch (e) {
  //   if (kDebugMode) {
  //     print('Erro ao inicializar serviços Firebase: $e');
  //     print('O aplicativo continuará, mas as funcionalidades de contexto podem não funcionar corretamente.');
  //   }
  // }
}
