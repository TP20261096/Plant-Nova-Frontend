import '../core/api/api_client.dart';
import '../models/weather.dart';

/// GET /weather
class WeatherService {
  final ApiClient _api = ApiClient.instance;

  Future<Weather> obtener() async {
    final datos = await _api.get('/weather') as Map<String, dynamic>;
    return Weather.fromJson(datos);
  }
}
