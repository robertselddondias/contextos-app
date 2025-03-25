// core/constants/app_constants.dart


class AppConstants {
  AppConstants._();

  // Configuração das APIs
  static const bool useGoogleNlp = true; // Defina como true para ativar a API do Google NLP
  static const bool useCustomApi = false; // Defina como true para ativar sua API personalizada
  static const String apiKey = 'YOUR_API_KEY'; // Para sua API personalizada

  // Caminho para as credenciais do Google Cloud
  static String googleCredentialsFilePath = 'assets/credentials/google_credentials.json';

  // Endpoints
  static const String semanticSimilarityEndpoint =
      'https://api.example.com/semantic-similarity';

  // Armazenamento local
  static const String prefsKeyDailyWord = 'daily_word';
  static const String prefsKeyLastPlayed = 'last_played';
  static const String prefsKeyGuesses = 'guesses';
  static const String prefsKeyGameState = 'game_state';
  static const String prefsKeyBestScore = 'best_score';
  static const String prefsKeyThemeMode = 'theme_mode';
  static const String prefsKeyLocale = 'locale';

  // Game settings
  static const int maxGuesses = 15;
  static const double winThreshold = 0.95;

  // Firebase collection names
  static const String dailyWordCollection = 'daily_words';
  static const String userScoresCollection = 'user_scores';
}
