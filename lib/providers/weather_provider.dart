import 'package:flutter/foundation.dart';

import '../core/api/api_exception.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _service = WeatherService();

  Weather? _weather;
  bool _isLoading = false;
  String? _error;

  Weather? get weather => _weather;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadWeather() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _weather = await _service.obtener();
      _error = null;
    } on ApiException catch (e) {
      // 503: la fuente externa no respondio y no habia lectura previa.
      _error = e.codigo == 503
          ? 'El clima no está disponible por ahora.'
          : e.mensaje;
    } catch (_) {
      _error = 'No se pudo cargar el clima.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
