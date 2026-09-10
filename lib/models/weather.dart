class Weather {
  final double temperature;
  final int humidity;
  final double windSpeed;
  final String description;
  final String icon;
  final String cityName;

  const Weather({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.icon,
    required this.cityName,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    // Obtener el nombre de la ciudad
    String cityName = json['name'] as String;

    // Mapear nombres de distritos a Lima Metropolitana
    if (cityName == 'Rímac' ||
        cityName == 'Miraflores' ||
        cityName == 'San Isidro' ||
        cityName == 'San Borja' ||
        cityName == 'Surco' ||
        cityName == 'La Molina' ||
        cityName == 'Lince' ||
        cityName == 'Magdalena' ||
        cityName == 'Pueblo Libre' ||
        cityName == 'Jesús María' ||
        cityName == 'Breña' ||
        cityName == 'San Miguel' ||
        cityName == 'Barranco' ||
        cityName == 'Chorrillos' ||
        cityName == 'San Juan de Lurigancho' ||
        cityName == 'San Juan de Miraflores' ||
        cityName == 'Villa El Salvador' ||
        cityName == 'Villa María del Triunfo' ||
        cityName == 'Comas' ||
        cityName == 'Los Olivos' ||
        cityName == 'San Martín de Porres' ||
        cityName == 'Independencia' ||
        cityName == 'Carabayllo' ||
        cityName == 'Puente Piedra' ||
        cityName == 'Santa Anita' ||
        cityName == 'Ate' ||
        cityName == 'El Agustino' ||
        cityName == 'San Luis' ||
        cityName == 'Cercado de Lima' ||
        cityName == 'Lima') {
      cityName = 'Lima Metropolitana';
    }

    return Weather(
      temperature: (json['main']['temp'] as num).toDouble(),
      humidity: json['main']['humidity'] as int,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      description: json['weather'][0]['description'] as String,
      icon: json['weather'][0]['icon'] as String,
      cityName: cityName,
    );
  }

  String get temperatureCelsius => '${temperature.toStringAsFixed(1)}°C';
  String get humidityPercentage => 'Humedad: $humidity%';
  String get windSpeedKmh => 'Viento: ${(windSpeed * 3.6).toStringAsFixed(1)} km/h';
}