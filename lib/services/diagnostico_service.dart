import 'dart:io';

import '../core/api/api_client.dart';
import '../models/diagnostico.dart';

/// Endpoints de /diagnose y /diagnoses.
class DiagnosticoService {
  final ApiClient _api = ApiClient.instance;

  /// POST /diagnose — multipart/form-data
  ///
  /// [plantId] es opcional: si viene, el diagnostico queda vinculado a esa
  /// planta y el backend programa las actividades del tratamiento de una vez.
  /// Si no viene, el diagnostico queda suelto y hay que vincularlo despues
  /// con [vincular].
  ///
  /// Limites del backend: JPG, PNG o WEBP, hasta 10 MB. El ApiClient traduce
  /// el 415 y el 413 a mensajes legibles.
  Future<Diagnostico> diagnosticar({
    required File imagen,
    String? plantId,
  }) async {
    final datos = await _api.postArchivo(
      '/diagnose',
      archivo: imagen,
      campo: 'imagen',
      extra: plantId == null ? const {} : {'plant_id': plantId},
    ) as Map<String, dynamic>;
    return Diagnostico.fromJson(datos);
  }

  /// GET /diagnoses/{id}
  ///
  /// Vuelve a pedirlo cuando haga falta mostrar las imagenes: los enlaces
  /// firmados caducan en una hora y este endpoint los devuelve nuevos.
  Future<Diagnostico> obtener(String id) async {
    final datos = await _api.get('/diagnoses/$id') as Map<String, dynamic>;
    return Diagnostico.fromJson(datos);
  }

  /// PATCH /diagnoses/{id}/link
  ///
  /// Al vincular, el backend programa las actividades del tratamiento y
  /// recalcula el estado de la planta. Devuelve 409 si el diagnostico ya
  /// estaba vinculado a otra planta.
  Future<Diagnostico> vincular({
    required String diagnosticoId,
    required String plantId,
  }) async {
    final datos = await _api.patch(
      '/diagnoses/$diagnosticoId/link',
      body: {'plant_id': plantId},
    ) as Map<String, dynamic>;
    return Diagnostico.fromJson(datos);
  }
}