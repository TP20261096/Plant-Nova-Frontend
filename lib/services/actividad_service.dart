import '../core/api/api_client.dart';
import '../core/utils/json.dart';
import '../models/actividad.dart';

/// Endpoints de /activities.
class ActividadService {
  final ApiClient _api = ApiClient.instance;

  /// GET /activities?fecha=YYYY-MM-DD
  ///
  /// Sin fecha el backend asume hoy. Devuelve las tareas ya ordenadas, con
  /// las atrasadas primero: no hay que reordenarlas en el cliente.
  Future<List<Actividad>> listar({DateTime? fecha}) async {
    final datos = await _api.get('/activities', query: {
      'fecha': fecha == null ? null : Json.aFechaApi(fecha),
    });
    if (datos is! List) return [];
    return datos
        .whereType<Map>()
        .map((e) => Actividad.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// POST /activities — tareas que crea el usuario a mano.
  Future<Actividad> crear(ActividadForm form) async {
    final datos = await _api.post('/activities', body: form.toJson())
    as Map<String, dynamic>;
    return Actividad.fromJson(datos);
  }

  /// PATCH /activities/{id}
  ///
  /// Envía el cambio de estado a "Completada" que FastAPI recibe en el endpoint actualizar().
  Future<void> completar(String id) => _api.patch(
    '/activities/$id',
    body: {'estado': 'Completada'},
  );
}