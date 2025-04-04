// Passo 1: Padronização de AppConstants.dart
// Arquivo: lib/core/constants/app_constants.dart
// Certifique-se de que todas as chaves de armazenamento estão definidas aqui

class AppConstants {
  AppConstants._();

  // Configuração das APIs
  static const bool useGoogleNlp = true;
  static const bool useCustomApi = false;
  static const String apiKey = 'YOUR_API_KEY';

  // Caminho para as credenciais do Google Cloud
  static String googleCredentialsFilePath = 'assets/credentials/google_credentials.json';

  // Endpoints
  static const String semanticSimilarityEndpoint =
      'https://api.example.com/semantic-similarity';

  // Armazenamento local - CHAVES PADRONIZADAS PARA PREFERÊNCIAS
  static const String prefsKeyDailyWord = 'daily_word';
  static const String prefsKeyLastPlayed = 'last_played';
  static const String prefsKeyGuesses = 'guesses';
  static const String prefsKeyGameState = 'game_state';
  static const String prefsKeyBestScore = 'best_score';
  static const String prefsKeyThemeMode = 'theme_mode';
  static const String prefsKeyLocale = 'locale';
  static const String prefsKeyGameStateDate = 'game_state_date';
  static const String prefsKeyAnonymousUserId = 'anonymous_user_id';
  static const String prefsKeyRemoveAdsActive = 'remove_ads_active';
  static const String prefsKeyLastInterstitialShown = 'last_interstitial_shown';
  static const String prefsKeyInterstitialAdCount = 'interstitial_ad_count';
  static const String prefsKeyInterstitialFrequency = 'interstitial_frequency';
  static const String prefsKeyPremiumUser = 'premium_user';
  static const String prefsKeyNotificationsEnabled = 'notifications_enabled';
  static const String prefsKeySmartNotificationsEnabled = 'smart_notifications_enabled';
  static const String prefsKeyLastWordCheckDate = 'last_word_check_date';
  static const String prefsKeyShowedOnboarding = 'showed_onboarding';
  static const String prefsKeyUserSessions = 'user_sessions';
  static const String prefsKeyPreferredHour = 'preferred_hour';
  static const String prefsKeyLastShownPremiumBanner = 'premium_banner_last_shown';
  static const String prefsKeyPremiumBannerShowCount = 'premium_banner_show_count';
  static const String prefsKeyGameSessionCount = 'game_session_count';
  static const String prefsKeySimilarityIndex = 'similarity_index';

  // Prefixos para chaves compostas
  static const String prefixDailyWord = 'daily_word_';
  static const String prefixSimilarity = 'similarity_';

  // Game settings
  static const int maxGuesses = 15;
  static const double winThreshold = 0.95;

  // Firebase collection names
  static const String dailyWordCollection = 'daily_words';
  static const String userScoresCollection = 'user_scores';
}
