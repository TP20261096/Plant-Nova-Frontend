import '../core/api/api_client.dart';
import '../models/consejo.dart';

/// GET /tips
class ConsejoService {
  final ApiClient _api = ApiClient.instance;

  Future<List<Consejo>> listar() async {
    final datos = await _api.get('/tips');
    if (datos is! List) return [];
    return datos
        .whereType<Map>()
        .map((e) => Consejo.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
