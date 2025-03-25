// Arquivo: lib/main.dart
// Versão simplificada com inicialização de notificações opcional

import 'package:contextual/app.dart';
import 'package:contextual/core/di/dependency_injection.dart';
import 'package:contextual/firebase_options.dart';
import 'package:contextual/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // Initialize notification service with proper error handling
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Failed to initialize notifications: $e');
    // Continue without notifications
  }

  runApp(const ContextoApp());
}
