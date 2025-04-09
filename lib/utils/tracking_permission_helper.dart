import 'dart:io' show Platform;
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

class TrackingPermissionHelper {
  /// Solicita permissão de rastreamento em dispositivos iOS
  static Future<void> requestTrackingPermission() async {
    if (Platform.isIOS) {
      try {
        // Verifica se o dispositivo suporta ATT (iOS 14+)
        final status = await AppTrackingTransparency.trackingAuthorizationStatus;

        // Se o status ainda não foi determinado, mostra o diálogo de permissão
        if (status == TrackingStatus.notDetermined) {
          // Espera para não interferir com a inicialização do app
          await Future.delayed(const Duration(milliseconds: 200));

          // Mostra o diálogo de permissão
          final newStatus = await AppTrackingTransparency.requestTrackingAuthorization();

          print('Permissão de rastreamento: $newStatus');
        } else {
          print('Permissão de rastreamento já determinada: $status');
        }
      } catch (e) {
        print('Erro ao solicitar permissão de rastreamento: $e');
      }
    }
  }

  /// Verifica se o rastreamento está autorizado
  static Future<bool> isTrackingAuthorized() async {
    if (!Platform.isIOS) return true;

    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      return status == TrackingStatus.authorized;
    } catch (e) {
      print('Erro ao verificar status de rastreamento: $e');
      return false;
    }
  }
}
