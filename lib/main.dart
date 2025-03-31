// Arquivo: lib/main.dart
// Com inicialização apropriada do AdMob

import 'package:contextual/app.dart';
import 'package:contextual/core/di/dependency_injection.dart';
import 'package:contextual/firebase_options.dart';
import 'package:contextual/services/ad_manager.dart';
import 'package:contextual/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o SDK do AdMob primeiro (importante para evitar problemas)
  await MobileAds.instance.initialize();
  debugPrint('Google Mobile Ads SDK inicializado');

  // Initialize Firebase with proper options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set orientation preferences
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize dependencies
  await initDependencies();

  // Inicialização explícita do AdManager após a inicialização das dependências
  final adManager = AdManager();
  await adManager.initialize();
  debugPrint('AdManager inicializado explicitamente');

  // Initialize notification service with proper error handling
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Failed to initialize notifications: $e');
    // Continue without notifications
  }

  runApp(const ContextoApp());
}
