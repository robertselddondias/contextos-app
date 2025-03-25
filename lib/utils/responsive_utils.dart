// lib/utils/responsive_utils.dart
import 'package:flutter/material.dart';

/// Utilitário para tornar o layout responsivo em diferentes tamanhos de tela
class ResponsiveUtils {
  // Singleton
  static final ResponsiveUtils _instance = ResponsiveUtils._internal();
  factory ResponsiveUtils() => _instance;
  ResponsiveUtils._internal();

  /// Verifica se a tela é um dispositivo móvel pequeno (menos de 360px)
  static bool isSmallMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  /// Verifica se a tela é um dispositivo móvel médio (360px-410px)
  static bool isMediumMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 360 && width < 410;
  }

  /// Verifica se a tela é um dispositivo móvel grande (410px ou mais)
  static bool isLargeMobile(BuildContext context) {
    return MediaQuery.of(context).size.width >= 410;
  }

  /// Retorna o fator de escala adaptativa com base no tamanho da tela
  static double getScaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 320) return 0.85;      // Dispositivos muito pequenos (ex: iPhone SE 1ª geração)
    if (width < 360) return 0.9;       // Dispositivos pequenos (ex: iPhone SE 2020)
    if (width < 410) return 1.0;       // Dispositivos médios (ex: iPhone X/11 Pro, Galaxy S10e)
    if (width < 480) return 1.1;       // Dispositivos grandes (ex: iPhone 11/12/13, Galaxy S20)
    return 1.2;                        // Dispositivos muito grandes (ex: iPhone Pro Max, Galaxy Note)
  }

  /// Calcula o tamanho de fonte responsivo
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final scaleFactor = getScaleFactor(context);

    // Limites para não deixar as fontes muito pequenas
    final calculatedSize = baseFontSize * scaleFactor;
    if (calculatedSize < 10) return 10;
    if (calculatedSize > baseFontSize * 1.4) return baseFontSize * 1.4;

    return calculatedSize;
  }

  /// Calcula o padding responsivo
  static EdgeInsets getResponsivePadding(BuildContext context, {
    double small = 8.0,
    double medium = 16.0,
    double large = 20.0
  }) {
    if (isSmallMobile(context)) {
      return EdgeInsets.all(small);
    } else if (isMediumMobile(context)) {
      return EdgeInsets.all(medium);
    } else {
      return EdgeInsets.all(large);
    }
  }

  /// Calcula o tamanho de um componente de forma responsiva
  static double getResponsiveSize(BuildContext context, double baseSize) {
    final scaleFactor = getScaleFactor(context);
    return baseSize * scaleFactor;
  }

  /// Retorna o número de colunas para uma grade, baseado no tamanho da tela do celular
  static int getResponsiveGridCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 2;  // Celulares pequenos: 2 colunas
    if (width < 600) return 3;  // Celulares normais/grandes: 3 colunas
    return 4;                   // Celulares muito grandes/tablets pequenos: 4 colunas
  }

  /// Retorna o layout apropriado baseado no tamanho do celular
  static T getResponsiveValue<T>({
    required BuildContext context,
    required T medium,
    T? small,
    T? large,
  }) {
    if (isSmallMobile(context) && small != null) {
      return small;
    }
    if (isLargeMobile(context) && large != null) {
      return large;
    }
    return medium;
  }
}

/// Extensão para facilitar o uso dos métodos responsivos
extension ResponsiveContext on BuildContext {
  bool get isSmallMobile => ResponsiveUtils.isSmallMobile(this);
  bool get isMediumMobile => ResponsiveUtils.isMediumMobile(this);
  bool get isLargeMobile => ResponsiveUtils.isLargeMobile(this);

  double get scaleFactor => ResponsiveUtils.getScaleFactor(this);

  double responsiveFontSize(double size) => ResponsiveUtils.getResponsiveFontSize(this, size);
  double responsiveSize(double size) => ResponsiveUtils.getResponsiveSize(this, size);
  int get gridCount => ResponsiveUtils.getResponsiveGridCount(this);

  EdgeInsets responsivePadding({
    double small = 8.0,
    double medium = 16.0,
    double large = 20.0
  }) => ResponsiveUtils.getResponsivePadding(this, small: small, medium: medium, large: large);

  /// Retorna um valor baseado no tamanho do celular (pequeno, médio ou grande)
  T responsiveValue<T>({
    required T medium,
    T? small,
    T? large,
  }) => ResponsiveUtils.getResponsiveValue(
    context: this,
    medium: medium,  // obrigatório
    small: small,    // opcional
    large: large,    // opcional
  );
}
