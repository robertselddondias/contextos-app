// core/di/dependency_injection.dart
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:contextual/services/purchase_manager.dart';
import 'package:contextual/services/smart_notification_service.dart';
import 'package:contextual/services/user_activity_tracker.dart';
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

  // Antes da linha de registro dos BLoCs
  getIt.registerLazySingleton(() => SettingsBloc(
    localDataSource: getIt<SharedPrefsManager>(),
  ));

  getIt.registerFactory(() => GameBloc(
    getDailyWord: getIt<GetDailyWord>(),
    makeGuess: getIt<MakeGuess>(),
    saveGameState: getIt<SaveGameState>(),
    wordRepository: getIt<WordRepository>(),
    gameRepository: getIt<GameRepository>(),
    prefs: getIt<SharedPreferences>(),
    firestore: FirebaseFirestore.instance,
  ));

  final purchaseManager = PurchaseManager();
  await purchaseManager.initialize();
  getIt.registerSingleton<PurchaseManager>(purchaseManager);

  final userActivityTracker = UserActivityTracker();
  final smartNotificationService = SmartNotificationService();
  await smartNotificationService.initialize();

  getIt.registerSingleton<UserActivityTracker>(userActivityTracker);
  getIt.registerSingleton<SmartNotificationService>(smartNotificationService);
}
