import 'package:flutter/foundation.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();

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
      _weather = await _weatherService.getCurrentWeather();

      // Imprimir para verificar
      print('Weather cargado: ${_weather?.temperature}°C');
      print('Humedad cargada: ${_weather?.humidity}%');
      print('Ciudad cargada: ${_weather?.cityName}');

      if (_weather == null) {
        _error = 'No se pudo obtener el clima';
      }
    } catch (e) {
      _error = 'Error al cargar el clima';
      print('Error en WeatherProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}