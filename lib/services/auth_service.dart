import '../core/api/api_client.dart';
import '../core/api/token_storage.dart';
import '../models/usuario.dart';

/// Llamadas a /auth/*. No guarda estado de UI: eso es tarea de AuthProvider.
class AuthService {
  final ApiClient _api = ApiClient.instance;
  final TokenStorage _tokens = TokenStorage.instance;

  Future<Usuario> registrar({
    required String email,
    required String password,
    required String nombre,
  }) async {
    final datos = await _api.post('/auth/register', body: {
      'email': email.trim(),
      'password': password,
      'nombre': nombre.trim(),
    });
    return _guardarSesion(datos as Map<String, dynamic>);
  }

  Future<Usuario> iniciarSesion({
    required String email,
    required String password,
  }) async {
    final datos = await _api.post('/auth/login', body: {
      'email': email.trim(),
      'password': password,
    });
    return _guardarSesion(datos as Map<String, dynamic>);
  }

  /// Comprueba contra el servidor si la sesion guardada sigue viva.
  ///
  /// Si el access_token esta vencido, ApiClient renueva por dentro y esta
  /// llamada igual devuelve el usuario. Solo falla si el refresh tambien
  /// murio, y ahi hay que volver a iniciar sesion.
  Future<Usuario> usuarioActual() async {
    final datos = await _api.get('/auth/me') as Map<String, dynamic>;
    // Toleramos las dos formas posibles: el usuario plano o envuelto.
    final cuerpo = datos.containsKey('usuario')
        ? datos['usuario'] as Map<String, dynamic>
        : datos;
    return Usuario.fromJson(cuerpo);
  }

  /// Cierra sesion en el servidor y borra los tokens locales.
  ///
  /// Si la llamada falla (sin red, token ya vencido) igual borramos local:
  /// desde el punto de vista del usuario, cerrar sesion nunca debe fallar.
  Future<void> cerrarSesion() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {
      // Ignorado a proposito.
    } finally {
      await _tokens.limpiar();
    }
  }

  Future<bool> haySesionGuardada() => _tokens.haySesion();

  Future<Usuario> _guardarSesion(Map<String, dynamic> datos) async {
    await _tokens.guardar(
      access: datos['access_token'] as String,
      refresh: datos['refresh_token'] as String,
    );
    return Usuario.fromJson(datos['usuario'] as Map<String, dynamic>);
  }
}