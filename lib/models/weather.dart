import '../core/utils/json.dart';

/// GET /weather
///
/// Reemplaza al modelo que parseaba la respuesta de OpenWeather. El clima
/// ahora lo sirve el backend, que es la misma fuente con la que calcula la
/// frecuencia de riego: si el cliente consultara otro proveedor, el usuario
/// veria una humedad distinta de la que genero sus tareas.
///
/// El backend resuelve la ubicacion con el distrito del perfil; sin distrito
/// informa el de Lima centro. La app no pide permisos de ubicacion.
class Weather {
  /// Distrito que el backend uso como referencia.
  final String ciudad;

  final double temperatura;
  final int humedad;
  final double vientoKmh;

  /// Momento de la lectura. Puede ser de hace un rato: el backend cachea.
  final DateTime? observado;

  const Weather({
    required this.ciudad,
    required this.temperatura,
    required this.humedad,
    required this.vientoKmh,
    required this.observado,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      ciudad: Json.texto(json['ciudad'], siNulo: 'Lima'),
      temperatura: Json.decimal(json['temperatura']),
      humedad: Json.entero(json['humedad']),
      vientoKmh: Json.decimal(json['viento_kmh']),
      observado: Json.fecha(json['observado']),
    );
  }

  String get temperaturaTexto => '${temperatura.toStringAsFixed(1)}°C';
  String get humedadTexto => '$humedad%';
  String get vientoTexto => '${vientoKmh.toStringAsFixed(0)} km/h';

  /// "Actualizado 16:00". Vacio si el backend no mando la hora.
  String get actualizadoTexto {
    final o = observado;
    if (o == null) return '';
    final hh = o.hour.toString().padLeft(2, '0');
    final mm = o.minute.toString().padLeft(2, '0');
    return 'Actualizado $hh:$mm';
  }
}
