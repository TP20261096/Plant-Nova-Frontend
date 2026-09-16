import 'dart:io';

import '../core/api/api_client.dart';
import '../models/perfil.dart';

class PerfilService {
  final ApiClient _api = ApiClient.instance;

  /// GET /profile
  Future<Perfil> obtener() async {
    final res = await _api.get('/profile');
    return Perfil.fromJson(res);
  }

  /// PATCH /profile
  Future<Perfil> actualizar(PerfilForm form) async {
    final res = await _api.patch('/profile', body: form.toJson());
    return Perfil.fromJson(res);
  }

  /// POST /profile/avatar
  Future<Perfil> subirFoto(File imagen) async {
    final res = await _api.postArchivo(
      '/profile/avatar',
      campo: 'foto',
      archivo: imagen,
    );
    return Perfil.fromJson(res);
  }

  /// GET /profile/districts
  Future<List<String>> distritos() async {
    final res = await _api.get('/profile/districts');
    return (res as List).map((e) => e.toString()).toList();
  }

  /// PUT /profile/password
  Future<void> cambiarPassword({
    required String actual,
    required String nueva,
  }) async {
    await _api.put(
      '/profile/password',
      body: {
        'password_actual': actual,
        'password_nueva': nueva,
      },
    );
  }

  /// DELETE /profile
  Future<void> eliminarCuenta() async {
    await _api.delete('/profile');
  }
}