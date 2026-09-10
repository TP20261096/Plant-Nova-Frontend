import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';
import '../config/api_config.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  // Coordenadas de Lima, Perú
  static const double _latitude = -12.0464;
  static const double _longitude = -77.0428;

  Future<Weather?> getCurrentWeather() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl?lat=$_latitude&lon=$_longitude&appid=${ApiConfig.openWeatherApiKey}&units=metric&lang=es',
        ),
      );

      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Imprimir datos reales para verificar
        print('Temperatura real: ${data['main']['temp']}°C');
        print('Humedad real: ${data['main']['humidity']}%');
        print('Descripción real: ${data['weather'][0]['description']}');
        print('Ciudad real: ${data['name']}');

        return Weather.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }
}