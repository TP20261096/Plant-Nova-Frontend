import '../core/api/api_client.dart';
import '../models/perfil.dart';

/// Endpoints de /profile.
class PerfilService {
  final ApiClient _api = ApiClient.instance;

  /// GET /profile
  Future<Perfil> obtener() async {
    final datos = await _api.get('/profile') as Map<String, dynamic>;
    return Perfil.fromJson(datos);
  }

  /// PATCH /profile — solo los campos que cambiaron.
  Future<Perfil> actualizar(PerfilForm form) async {
    final datos =
    await _api.patch('/profile', body: form.toJson()) as Map<String, dynamic>;
    return Perfil.fromJson(datos);
  }

  /// GET /profile/districts
  ///
  /// El distrito se valida contra esta lista: texto libre devuelve 400. Por
  /// eso el selector tiene que poblarse desde aca y no escribirse a mano.
  Future<List<String>> distritos() async {
    final datos = await _api.get('/profile/districts');
    if (datos is! List) return [];
    // Toleramos las dos formas posibles: lista de textos o de objetos.
    return datos.map((e) {
      if (e is Map) {
        return (e['nombre'] ?? e['distrito'] ?? e.values.first).toString();
      }
      return e.toString();
    }).toList();
  }

  /// PUT /profile/password → 204
  ///
  /// Exige la contrasena actual a proposito. Devuelve 401 si no es correcta.
  Future<void> cambiarPassword({
    required String actual,
    required String nueva,
  }) =>
      _api.put('/profile/password', body: {
        'password_actual': actual,
        'password_nueva': nueva,
      });

  /// DELETE /profile → 204
  ///
  /// Irreversible: borra cuenta, plantas, diagnosticos, actividades e
  /// imagenes. La pantalla tiene que pedir confirmacion explicita.
  Future<void> eliminarCuenta() => _api.delete('/profile');
}