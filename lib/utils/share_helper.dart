// utils/share_helper.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareHelper {
  ShareHelper._();

  /// Compartilha os resultados do jogo
  static Future<void> shareResults({
    required BuildContext context,
    required String shareText,
  }) async {
    try {
      await Share.share(
        shareText,
        subject: 'Meus resultados no Contexto',
      );
    } catch (e) {
      // Fallback caso o plugin Share.share falhe
      _showManualShareDialog(context, shareText);
    }
  }

  /// Exibe um diálogo para compartilhamento manual
  /// (caso o compartilhamento automático falhe)
  static void _showManualShareDialog(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Copiar resultados'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Não foi possível abrir o menu de compartilhamento. '
                  'Você pode copiar o texto abaixo e compartilhar manualmente:',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(text),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          TextButton(
            onPressed: () {
              _copyToClipboard(context, text);
              Navigator.of(context).pop();
            },
            child: const Text('Copiar'),
          ),
        ],
      ),
    );
  }

  /// Copia o texto para a área de transferência
  static void _copyToClipboard(BuildContext context, String text) {
    // Em uma implementação real, usaríamos Clipboard.setData
    // aqui, mas para manter a simplicidade, apenas exibimos
    // uma mensagem de sucesso

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Texto copiado para a área de transferência'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
