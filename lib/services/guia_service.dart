import '../core/api/api_client.dart';
import '../models/especie.dart';

/// Endpoints de /guide. Alimenta el menu Guia y tambien el selector de
/// especie al registrar una planta.
class GuiaService {
  final ApiClient _api = ApiClient.instance;

  /// GET /guide/species
  ///
  /// [q] busca por nombre. [soloDiagnosticables] filtra las especies que el
  /// modelo reconoce, util cuando el usuario viene desde una captura.
  Future<List<Especie>> especies({String? q, bool? soloDiagnosticables}) async {
    final datos = await _api.get('/guide/species', query: {
      'q': (q != null && q.trim().isNotEmpty) ? q.trim() : null,
      'diagnosticables': soloDiagnosticables,
    });
    if (datos is! List) return [];
    return datos
        .whereType<Map>()
        .map((e) => Especie.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// GET /guide/species/{slug}
  Future<EspecieDetalle> detalle(String slug) async {
    final datos =
    await _api.get('/guide/species/$slug') as Map<String, dynamic>;
    return EspecieDetalle.fromJson(datos);
  }
}