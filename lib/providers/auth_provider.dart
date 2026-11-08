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
      // Sin respuesta del servidor no hay prueba de que la sesion haya
      // caducado: puede ser un arranque en frio o un corte momentaneo. Si
      // tenemos copia del usuario, se entra igual y la app se pondra al dia
      // en la siguiente peticion. Obligar a iniciar sesion cada vez que el
      // servidor tarda es la causa de que la sesion pareciera no durar.
      if (e.sinConexion) {
        final enCache = await _auth.usuarioEnCache();
        if (enCache != null) {
          _usuario = enCache;
          _estado = EstadoSesion.autenticado;
          notifyListeners();
          return;
        }
        _estado = EstadoSesion.noAutenticado;
        _error = e.mensaje;
      } else {
        // El servidor respondio y rechazo: la sesion caduco de verdad.
        _estado = EstadoSesion.noAutenticado;
        _error = 'Tu sesión ha expirado. Inicia sesión nuevamente';
      }
    } catch (_) {
      final enCache = await _auth.usuarioEnCache();
      if (enCache != null) {
        _usuario = enCache;
        _estado = EstadoSesion.autenticado;
        notifyListeners();
        return;
      }
      _estado = EstadoSesion.noAutenticado;
      _error = 'Tu sesión ha expirado. Inicia sesión nuevamente';
    }
    notifyListeners();
  }

  Future<bool> iniciarSesion(String email, String password) {
    return _intentar(
      () => _auth.iniciarSesion(email: email, password: password),
      mensaje: (e) {
        // El backend puede distinguir correo inexistente de contrasena
        // incorrecta; la interfaz no debe hacerlo. Un mensaje unico evita
        // confirmar a un desconocido que un correo esta registrado.
        if (e.codigo == 401) {
          return 'Correo o contraseña incorrectos. Intenta de nuevo';
        }
        if (e.sinConexion) {
          return 'No se pudo iniciar sesión. Verifica tu conexión e '
              'inténtalo de nuevo';
        }
        return e.mensaje;
      },
    );
  }

  Future<bool> registrar({
    required String nombre,
    required String email,
    required String password,
  }) {
    return _intentar(
      () => _auth.registrar(email: email, password: password, nombre: nombre),
      mensaje: (e) {
        // El backend responde "user already registered", en ingles y no
        // siempre con 409, asi que ademas del codigo miramos el texto.
        final detalle = e.mensaje.toLowerCase();
        final correoRepetido = e.conflicto ||
            detalle.contains('already registered') ||
            detalle.contains('already exists') ||
            detalle.contains('ya está registrado') ||
            detalle.contains('ya existe');
        if (correoRepetido) return 'Ese correo ya está en uso';
        if (e.sinConexion) {
          return 'No se pudo completar el registro. Verifica tu conexión e '
              'inténtalo de nuevo';
        }
        return e.mensaje;
      },
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

  Future<bool> _intentar(
    Future<Usuario> Function() accion, {
    String Function(ApiException)? mensaje,
  }) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _usuario = await accion();
      _estado = EstadoSesion.autenticado;
      return true;
    } on ApiException catch (e) {
      _error = mensaje?.call(e) ?? e.mensaje;
      return false;
    } catch (e) {
      _error = 'Ocurrió un error inesperado.';
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  void _sesionExpirada() {
    _usuario = null;
    _estado = EstadoSesion.noAutenticado;
    _error = 'Tu sesión ha expirado. Inicia sesión nuevamente';
    notifyListeners();
  }
}