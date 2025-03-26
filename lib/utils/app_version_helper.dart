// lib/utils/app_version_helper.dart
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Classe utilitária para obter informações da versão do aplicativo
class AppVersionHelper {
  // Singleton
  static final AppVersionHelper _instance = AppVersionHelper._internal();
  factory AppVersionHelper() => _instance;
  AppVersionHelper._internal();

  PackageInfo? _packageInfo;

  /// Inicializa e carrega as informações do pacote
  Future<void> initialize() async {
    if (_packageInfo == null) {
      _packageInfo = await PackageInfo.fromPlatform();
    }
  }

  /// Obtém a versão do aplicativo no formato "x.y.z"
  Future<String> getAppVersion() async {
    await initialize();
    return _packageInfo?.version ?? 'Desconhecida';
  }

  /// Obtém a versão do aplicativo com o código de build "x.y.z+build"
  Future<String> getFullAppVersion() async {
    await initialize();
    final version = _packageInfo?.version ?? 'Desconhecida';
    final buildNumber = _packageInfo?.buildNumber ?? '';

    return buildNumber.isNotEmpty
        ? '$version+$buildNumber'
        : version;
  }

  /// Obtém o nome do pacote do aplicativo (ex: com.example.app)
  Future<String> getPackageName() async {
    await initialize();
    return _packageInfo?.packageName ?? 'Desconhecido';
  }

  /// Obtém o nome do aplicativo
  Future<String> getAppName() async {
    await initialize();
    return _packageInfo?.appName ?? 'Desconhecido';
  }

  /// Widget para exibir a versão do aplicativo
  static Widget buildVersionText({
    TextStyle? style,
    bool showBuildNumber = false,
  }) {
    return FutureBuilder<String>(
      future: showBuildNumber
          ? AppVersionHelper().getFullAppVersion()
          : AppVersionHelper().getAppVersion(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 12); // Espaço reservado enquanto carrega
        }

        final versionText = snapshot.data ?? 'Versão desconhecida';
        return Text(
          'Versão $versionText',
          style: style ?? TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        );
      },
    );
  }
}
