import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';

enum EstadoSesion {
  /// Todavia no sabemos: la app esta arrancando.
  comprobando,
  autenticado,
  noAutenticado,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();

  EstadoSesion _estado = EstadoSesion.comprobando;
  Usuario? _usuario;
  bool _cargando = false;
  String? _error;

  EstadoSesion get estado => _estado;
  Usuario? get usuario => _usuario;
  bool get cargando => _cargando;
  String? get error => _error;
  bool get autenticado => _estado == EstadoSesion.autenticado;

  AuthProvider() {
    // Si el refresh falla en cualquier peticion, el cliente avisa por aca.
    ApiClient.instance.onSesionExpirada = _sesionExpirada;
  }

  /// Lo llama el splash al abrir la app.
  Future<void> comprobarSesion() async {
    if (!await _auth.haySesionGuardada()) {
      _estado = EstadoSesion.noAutenticado;
      notifyListeners();
      return;
    }

    try {
      _usuario = await _auth.usuarioActual();
      _estado = EstadoSesion.autenticado;
    } on ApiException catch (e) {
      // Sin red no tiene sentido mandar al login: el token puede seguir bueno.
      // Preferimos pedir credenciales antes que dejar la app en un limbo.
      _estado = EstadoSesion.noAutenticado;
      _error = e.sinConexion ? e.mensaje : null;
    } catch (_) {
      _estado = EstadoSesion.noAutenticado;
    }
    notifyListeners();
  }

  Future<bool> iniciarSesion(String email, String password) {
    return _intentar(
            () => _auth.iniciarSesion(email: email, password: password));
  }

  Future<bool> registrar({
    required String nombre,
    required String email,
    required String password,
  }) {
    return _intentar(
          () => _auth.registrar(email: email, password: password, nombre: nombre),
    );
  }

  Future<void> cerrarSesion() async {
    await _auth.cerrarSesion();
    _usuario = null;
    _error = null;
    _estado = EstadoSesion.noAutenticado;
    notifyListeners();
  }

  /// Para actualizar el nombre en la barra superior cuando el usuario lo
  /// cambia desde Perfil, sin volver a pedir /auth/me.
  void actualizarUsuario(Usuario usuario) {
    _usuario = usuario;
    notifyListeners();
  }

  void limpiarError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<bool> _intentar(Future<Usuario> Function() accion) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _usuario = await accion();
      _estado = EstadoSesion.autenticado;
      return true;
    } on ApiException catch (e) {
      _error = e.mensaje;
      return false;
    } catch (e) {
      _error = 'Ocurrio un error inesperado.';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  void _sesionExpirada() {
    _usuario = null;
    _estado = EstadoSesion.noAutenticado;
    _error = 'Tu sesion expiro. Vuelve a iniciar sesion.';
    notifyListeners();
  }
}