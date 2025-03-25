import 'package:flutter/material.dart';

/// Widget que detecta toques fora de elementos de entrada de texto
/// e fecha o teclado automaticamente.
class KeyboardDismisser extends StatelessWidget {
  final Widget child;
  final bool excludeFromSemantics;

  const KeyboardDismisser({
    Key? key,
    required this.child,
    this.excludeFromSemantics = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Fechar o teclado quando tocar em qualquer lugar fora de um campo de texto
        FocusManager.instance.primaryFocus?.unfocus();
      },
      behavior: HitTestBehavior.translucent,
      excludeFromSemantics: excludeFromSemantics,
      child: child,
    );
  }
}

/// Extensão para Context que permite esconder o teclado facilmente
extension KeyboardUtils on BuildContext {
  /// Esconde o teclado
  void hideKeyboard() {
    FocusScopeNode currentFocus = FocusScope.of(this);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
}

/// Envolve todo o app para gerenciar o teclado globalmente
class AppKeyboardManager extends StatelessWidget {
  final Widget child;

  const AppKeyboardManager({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return KeyboardDismisser(
      child: child,
    );
  }
}
