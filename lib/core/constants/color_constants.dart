// core/constants/color_constants.dart
import 'package:flutter/material.dart';

class ColorConstants {
  ColorConstants._();

  // Cores principais - Esquema elegante
  static const Color primary = Color(0xFF5B4FBF);       // Roxo elegante
  static const Color primaryVariant = Color(0xFF453AA0); // Roxo mais escuro
  static const Color secondary = Color(0xFF42BBBC);     // Turquesa vibrante
  static const Color secondaryVariant = Color(0xFF33908E); // Turquesa escuro
  static const Color accent = Color(0xFFFF7966);        // Coral para acentos

  // Cores de fundo e superfície
  static const Color background = Color(0xFFF8F7FC);    // Quase branco com uma leve tonalidade de roxo
  static const Color surface = Color(0xFFFFFFFF);       // Branco puro
  static const Color surfaceVariant = Color(0xFFF1EFF9); // Superfície alternativa

  // Cores de estado
  static const Color error = Color(0xFFE53935);         // Vermelho mais vibrante
  static const Color success = Color(0xFF43A047);       // Verde vibrante
  static const Color warning = Color(0xFFFFB300);       // Amarelo âmbar
  static const Color info = Color(0xFF2196F3);          // Azul informativo

  // Cores de texto para tema claro
  static const Color textPrimary = Color(0xFF212121);   // Quase preto
  static const Color textSecondary = Color(0xFF666666); // Cinza escuro
  static const Color textHint = Color(0xFF9E9E9E);      // Cinza médio
  static const Color textDisabled = Color(0xFFBDBDBD);  // Cinza claro

  // Cores para o tema escuro
  static const Color darkBackground = Color(0xFF121212);      // Preto suave
  static const Color darkSurface = Color(0xFF1E1E1E);         // Cinza muito escuro
  static const Color darkSurfaceVariant = Color(0xFF2D2D2D);  // Variante de superfície
  static const Color darkTextPrimary = Color(0xFFF5F5F5);     // Branco levemente acinzentado
  static const Color darkTextSecondary = Color(0xFFB3B3B3);   // Cinza claro

  // Gradientes elegantes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF7868E6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, Color(0xFF66BB6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Cores para similaridade - Escala mais elegante
  static const List<Color> similarityColors = [
    Color(0xFFD1DEFC), // Azul muito claro - similaridade baixa (0-20%)
    Color(0xFFA3C4FB), // Azul claro (20-40%)
    Color(0xFF7DADFA), // Azul médio claro (40-60%)
    Color(0xFF5696F9), // Azul médio (60-80%)
    Color(0xFF2F7FEF), // Azul vibrante (80-90%)
    Color(0xFF1565C0), // Azul escuro (90-99%)
    Color(0xFF43A047), // Verde - correspondência exata (100%)
  ];

  // Cores para similaridade em tema escuro
  static const List<Color> darkSimilarityColors = [
    Color(0xFF0D2144), // Azul escuro - similaridade baixa (0-20%)
    Color(0xFF153567), // Azul escuro (20-40%)
    Color(0xFF1C478A), // Azul médio escuro (40-60%)
    Color(0xFF2359AC), // Azul médio (60-80%)
    Color(0xFF2A6BCE), // Azul vibrante escuro (80-90%)
    Color(0xFF3179DE), // Azul claro (90-99%)
    Color(0xFF2E7D32), // Verde escuro - correspondência exata (100%)
  ];

  /// Obtém a cor com base na similaridade para tema claro
  static Color getSimilarityColor(double similarity, {bool darkMode = false}) {
    final colors = darkMode ? darkSimilarityColors : similarityColors;

    if (similarity >= 1.0) return darkMode ? colors[6] : success;
    if (similarity >= 0.9) return colors[5];
    if (similarity >= 0.8) return colors[4];
    if (similarity >= 0.6) return colors[3];
    if (similarity >= 0.4) return colors[2];
    if (similarity >= 0.2) return colors[1];
    return colors[0];
  }

  /// Obtém a cor do texto com base na similaridade
  /// (para garantir contraste adequado)
  static Color getSimilarityTextColor(double similarity, {bool darkMode = false}) {
    if (darkMode) {
      // No tema escuro, usamos texto mais claro para valores altos
      if (similarity >= 0.8) return Colors.white;
      if (similarity >= 0.4) return const Color(0xFFF0F0F0);
      return const Color(0xFFE0E0E0);
    } else {
      // No tema claro, ajustamos a cor para garantir legibilidade
      if (similarity >= 0.8) return Colors.white;
      return const Color(0xFF212121);
    }
  }

  /// Obtém um gradiente baseado na similaridade
  static LinearGradient getSimilarityGradient(double similarity, {bool darkMode = false}) {
    final baseColor = getSimilarityColor(similarity, darkMode: darkMode);

    // Cria um gradiente sutilmente mais claro para dar profundidade
    var lighterColor = Color.lerp(baseColor, Colors.white, darkMode ? 0.1 : 0.2)!;

    return LinearGradient(
      colors: [baseColor, lighterColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
