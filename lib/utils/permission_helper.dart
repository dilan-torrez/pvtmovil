import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<bool> requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied || status.isLimited) {
      final result = await Permission.camera.request();
      
      if (result.isGranted) {
        return true;
      }
      
      if (result.isPermanentlyDenied) {
        if (context.mounted) {
          _showSettingsDialog(context);
        }
      }
      
      return false;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showSettingsDialog(context);
      }
      return false;
    }

    return false;
  }

  static Future<bool> requestNotificationPermission(BuildContext context) async {
    final status = await Permission.notification.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied || status.isLimited) {
      final result = await Permission.notification.request();
      
      if (result.isGranted) {
        return true;
      }
      
      if (result.isPermanentlyDenied) {
        if (context.mounted) {
          _showSettingsDialog(context, isNotification: true);
        }
      }
      
      return false;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        _showSettingsDialog(context, isNotification: true);
      }
      return false;
    }

    return false;
  }

  static void _showSettingsDialog(BuildContext context, {bool isNotification = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permiso requerido'),
          content: Text(
            isNotification
                ? 'Para recibir notificaciones push, necesitas habilitar los permisos en la configuración de la aplicación.'
                : 'Para usar la cámara, necesitas habilitar los permisos en la configuración de la aplicación.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Configuración'),
            ),
          ],
        );
      },
    );
  }

  static Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  static Future<bool> checkNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }
}
