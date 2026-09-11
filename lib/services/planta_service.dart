import '../core/api/api_client.dart';
import '../models/planta.dart';

/// Endpoints de /plants. Sin estado: solo traduce JSON a modelos.
class PlantaService {
  final ApiClient _api = ApiClient.instance;

  /// GET /plants
  Future<List<Planta>> listar() async {
    final datos = await _api.get('/plants');
    if (datos is! List) return [];
    return datos
        .whereType<Map>()
        .map((e) => Planta.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// GET /plants/{id}
  Future<PlantaDetalle> obtener(String id) async {
    final datos = await _api.get('/plants/$id') as Map<String, dynamic>;
    return PlantaDetalle.fromJson(datos);
  }

  /// POST /plants
  ///
  /// Devuelve la planta creada. Lo unico que necesitamos de verdad es el id,
  /// porque es lo que pide PATCH /diagnoses/{id}/link cuando el usuario
  /// registra una planta nueva desde la pantalla de resultado.
  Future<PlantaDetalle> crear(PlantaForm form) async {
    final datos = await _api.post('/plants', body: form.toJson())
    as Map<String, dynamic>;
    return PlantaDetalle.fromJson(datos);
  }

  /// PUT /plants/{id}
  ///
  /// [cambios] debe traer solo los campos que se modificaron. Usa
  /// PlantaForm.toJsonParcial() para armarlo.
  Future<PlantaDetalle> actualizar(
      String id,
      Map<String, dynamic> cambios,
      ) async {
    final datos =
    await _api.put('/plants/$id', body: cambios) as Map<String, dynamic>;
    return PlantaDetalle.fromJson(datos);
  }

  /// DELETE /plants/{id}
  ///
  /// El backend borra en cascada los diagnosticos y actividades de la planta.
  /// La pantalla tiene que pedir confirmacion antes de llamar aca.
  Future<void> eliminar(String id) => _api.delete('/plants/$id');
}