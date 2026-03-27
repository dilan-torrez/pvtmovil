import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'crypto_service.dart';

/// Servicio de autenticación y almacenamiento seguro
/// Esta clase se encarga de guardar y recuperar tokens, información del usuario
/// y datos del dispositivo de forma segura usando AES-GCM en Dart puro.
class AuthService extends ChangeNotifier {
  
  /// Método privado para obtener la instancia de SharedPreferences
  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  /// Guarda el token principal de sesión, asociado a la versión actual
  Future<void> writeToken(BuildContext context, String token) async {
    final prefs = await _getPrefs();
    final encryptedToken = CryptoService.encrypt(token);
    await prefs.setString('tokenv${dotenv.env['version']}', encryptedToken);
  }

  /// Recupera el token principal de sesión
  Future<String> readToken() async {
    final prefs = await _getPrefs();
    final encryptedToken = prefs.getString('tokenv${dotenv.env['version']}') ?? '';
    if (encryptedToken.isEmpty) return '';
    
    return CryptoService.decrypt(encryptedToken) ?? '';
  }

  /// Guarda un token auxiliar, por ejemplo usado temporalmente antes de iniciar sesión completa
  Future<void> writeAuxtoken(String token) async {
    final prefs = await _getPrefs();
    final encryptedToken = CryptoService.encrypt(token);
    await prefs.setString('auxToken', encryptedToken);
  }

  /// Recupera el token auxiliar
  Future<String> readAuxToken() async {
    final prefs = await _getPrefs();
    final encryptedToken = prefs.getString('auxToken') ?? '';
    if (encryptedToken.isEmpty) return '';
    
    return CryptoService.decrypt(encryptedToken) ?? '';
  }

  /// Guarda los datos del usuario autenticado (en formato JSON)
  Future<void> writeUser(BuildContext context, String value) async {
    final prefs = await _getPrefs();
    final encryptedUser = CryptoService.encrypt(value);
    await prefs.setString('user', encryptedUser);
  }

  /// Recupera los datos del usuario (en formato JSON)
  Future<String> readUser() async {
    final prefs = await _getPrefs();
    final encryptedUser = prefs.getString('user') ?? '';
    if (encryptedUser.isEmpty) return '';
    
    return CryptoService.decrypt(encryptedUser) ?? '';
  }

  /// Guarda el identificador único del dispositivo
  Future<void> writeDeviceId(String deviceId) async {
    final prefs = await _getPrefs();
    final encryptedDeviceId = CryptoService.encrypt(deviceId);
    await prefs.setString('device_id', encryptedDeviceId);
  }

  /// Recupera el identificador único del dispositivo
  Future<String> readDeviceId() async {
    final prefs = await _getPrefs();
    final encryptedDeviceId = prefs.getString('device_id') ?? '';
    if (encryptedDeviceId.isEmpty) return '';
    
    return CryptoService.decrypt(encryptedDeviceId) ?? '';
  }

  /// Elimina los datos de autenticación biométrica
  Future<void> deleteBiometric() async {
    final prefs = await _getPrefs();
    await prefs.remove('biometric');
  }

  /// Elimina los datos de sesión al cerrar sesión del usuario
  Future<void> logout() async {
    final prefs = await _getPrefs();
    await prefs.remove('user');
    await prefs.remove('tokenv${dotenv.env['version']}');
    await prefs.remove('auxToken');
    await prefs.remove('device_id');
  }

  /// Borra absolutamente todo el contenido del almacenamiento persistente
  /// Útil para depuración o reinicio completo de sesión
  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.clear();
  }

  /// Lee si es la primera vez que se abre la app
  Future<String> readFirstTime() async {
    final prefs = await _getPrefs();
    return prefs.getString('firstTime') ?? '';
  }

  /// Guarda si el usuario tiene activada la autenticación biométrica
  Future<void> writeBiometric(BuildContext context, String value) async {
    final prefs = await _getPrefs();
    final encryptedValue = CryptoService.encrypt(value);
    await prefs.setString('biometric', encryptedValue);
  }

  /// Lee si la autenticación biométrica está activada
  Future<String> readBiometric() async {
    final prefs = await _getPrefs();
    final encryptedValue = prefs.getString('biometric') ?? '';
    if (encryptedValue.isEmpty) return '';
    
    return CryptoService.decrypt(encryptedValue) ?? '';
  }

  /// Guarda si es la primera vez que se abre la app (ej. para mostrar onboarding)
  Future<void> writeFirstTime(BuildContext context) async {
    final prefs = await _getPrefs();
    await prefs.setString('firstTime', 'true');
  }
}

