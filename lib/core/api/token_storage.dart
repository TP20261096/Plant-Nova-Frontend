import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Guarda los tokens de sesion entre aperturas de la app.
///
/// Usa SharedPreferences, que en Android es un XML sin cifrar dentro del
/// sandbox de la app. Es suficiente para el proyecto, pero si en la tesis
/// tienes un requisito de seguridad sobre credenciales, cambia solo esta
/// clase por flutter_secure_storage: el resto del codigo no se entera.
class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  static const String _kAccess = 'access_token';
  static const String _kRefresh = 'refresh_token';

  /// Copia del usuario autenticado. Permite abrir la app sin esperar a
  /// /auth/me, de modo que un servidor lento no obligue a iniciar sesion.
  static const String _kUsuario = 'usuario_sesion';

  // Cache en memoria para no pegarle al disco en cada peticion.
  String? _access;
  String? _refresh;
  Map<String, dynamic>? _usuario;
  bool _cargado = false;

  Future<void> _cargar() async {
    if (_cargado) return;
    final prefs = await SharedPreferences.getInstance();
    _access = prefs.getString(_kAccess);
    _refresh = prefs.getString(_kRefresh);

    final crudo = prefs.getString(_kUsuario);
    if (crudo != null) {
      try {
        _usuario = jsonDecode(crudo) as Map<String, dynamic>;
      } catch (_) {
        _usuario = null;
      }
    }
    _cargado = true;
  }

  Future<String?> accessToken() async {
    await _cargar();
    return _access;
  }

  Future<String?> refreshToken() async {
    await _cargar();
    return _refresh;
  }

  Future<bool> haySesion() async {
    await _cargar();
    return _refresh != null;
  }

  /// Usuario de la ultima sesion valida, o null si no hay copia.
  Future<Map<String, dynamic>?> usuarioGuardado() async {
    await _cargar();
    return _usuario;
  }

  Future<void> guardarUsuario(Map<String, dynamic> usuario) async {
    _usuario = usuario;
    _cargado = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUsuario, jsonEncode(usuario));
  }

  Future<void> guardar({required String access, required String refresh}) async {
    _access = access;
    _refresh = refresh;
    _cargado = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccess, access);
    await prefs.setString(_kRefresh, refresh);
  }

  Future<void> limpiar() async {
    _access = null;
    _refresh = null;
    _usuario = null;
    _cargado = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccess);
    await prefs.remove(_kRefresh);
    await prefs.remove(_kUsuario);
  }
}