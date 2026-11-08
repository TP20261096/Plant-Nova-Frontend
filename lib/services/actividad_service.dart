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

  /// GET /activities/range?desde=&hasta=
  ///
  /// Alimenta el selector de 7 dias en una sola peticion. Devuelve un
  /// diccionario con una clave por fecha, de modo que los dias sin tareas
  /// llegan como lista vacia y no hay que deducir que fechas faltan.
  ///
  /// Una tarea atrasada se repite en cada dia desde su fecha hasta hoy;
  /// es intencional del backend: sigue pendiente.
  Future<Map<String, List<Actividad>>> rango({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final datos = await _api.get('/activities/range', query: {
      'desde': Json.aFechaApi(desde),
      'hasta': Json.aFechaApi(hasta),
    });
    if (datos is! Map) return {};

    final resultado = <String, List<Actividad>>{};
    datos.forEach((clave, valor) {
      resultado[clave.toString()] = valor is List
          ? valor
              .whereType<Map>()
              .map((e) => Actividad.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : <Actividad>[];
    });
    return resultado;
  }

  /// POST /activities — tareas que crea el usuario a mano.
  Future<Actividad> crear(ActividadForm form) async {
    final datos = await _api.post('/activities', body: form.toJson())
    as Map<String, dynamic>;
    return Actividad.fromJson(datos);
  }

  /// PATCH /activities/{id}
  ///
  /// Completar dispara el encadenamiento del backend: un riego registra la
  /// fecha y recalcula la frecuencia con el clima del dia; un tratamiento
  /// programa la siguiente aplicacion desde la fecha real de cumplimiento;
  /// la ultima aplicacion crea la actividad de revision.
  ///
  /// Devuelve la actividad actualizada, cuyo campo proxima_tarea trae la
  /// siguiente pendiente de todo el jardin (null si no queda nada).
  Future<Actividad> completar(String id) async {
    final datos = await _api.patch(
      '/activities/$id',
      body: {'estado': 'Completada'},
    ) as Map<String, dynamic>;
    return Actividad.fromJson(datos);
  }
}
