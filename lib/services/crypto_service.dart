import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Servicio de encriptación pura en Dart para evitar vulnerabilidades en código nativo (AES-CBC).
/// Utiliza AES-GCM, que es un modo de cifrado autenticado más seguro.
class CryptoService {
  /// Obtiene la clave de encriptación desde el archivo .env
  static Key _getKey() {
    // Se recomienda una clave de 32 caracteres para AES-256
    String keyString = dotenv.env['ENCRYPTION_KEY']!;

    // Ajustamos la clave para que tenga exactamente 32 bytes
    if (keyString.length < 32) {
      keyString = keyString.padRight(32, '0');
    } else if (keyString.length > 32) {
      keyString = keyString.substring(0, 32);
    }
    return Key.fromUtf8(keyString);
  }

  /// Cifra un texto plano y devuelve una cadena en formato base64(iv):base64(encrypted)
  static String encrypt(String plainText) {
    if (plainText.isEmpty) return '';

    final key = _getKey();
    // IV de 16 bytes para GCM (aunque 12 bytes es estándar para GCM, 'encrypt' usa 16 por defecto en su implementación de AES)
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));

    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Retornamos el IV y el texto cifrado concatenados para poder descifrar después
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Descifra una cadena cifrada generada por el método [encrypt]
  static String? decrypt(String encryptedData) {
    if (encryptedData.isEmpty) return null;

    try {
      final parts = encryptedData.split(':');
      if (parts.length != 2) return null;

      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);

      final key = _getKey();
      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));

      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      // En caso de error (clave incorrecta o formato inválido), retornamos null
      return null;
    }
  }
}
