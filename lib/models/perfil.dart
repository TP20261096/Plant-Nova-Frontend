import '../core/utils/json.dart';
import 'usuario.dart';

/// GET /profile
///
/// Es la version extendida del [Usuario] que devuelve auth. El distrito no es
/// decorativo: filtra los puntos de venta de insumos que aparecen en el
/// diagnostico, y solo se admiten los valores de GET /profile/districts.
class Perfil {
  final String id;
  final String email;
  final String nombre;
  final String? fotoUrl;
  final String? distrito;
  final bool notificaciones;
  final int plantasRegistradas;
  final DateTime? createdAt;

  const Perfil({
    required this.id,
    required this.email,
    required this.nombre,
    required this.fotoUrl,
    required this.distrito,
    required this.notificaciones,
    required this.plantasRegistradas,
    required this.createdAt,
  });

  factory Perfil.fromJson(Map<String, dynamic> json) {
    return Perfil(
      id: Json.texto(json['id']),
      email: Json.texto(json['email']),
      nombre: Json.texto(json['nombre']),
      fotoUrl: Json.textoNulo(json['foto_url']),
      distrito: Json.textoNulo(json['distrito']),
      notificaciones: Json.booleano(json['notificaciones'], siNulo: true),
      plantasRegistradas: Json.entero(json['plantas_registradas']),
      createdAt: Json.fecha(json['created_at']),
    );
  }

  /// Para refrescar el nombre que muestra la barra superior sin volver a
  /// pedir /auth/me despues de editar el perfil.
  Usuario get usuario => Usuario(id: id, email: email, nombre: nombre);

  bool get tieneDistrito => distrito != null && distrito!.isNotEmpty;

  String get iniciales => usuario.iniciales;
}

/// Cuerpo de PATCH /profile. Solo admite estos cuatro campos, y solo se
/// envian los que cambiaron: mandar el objeto entero daria 400 en cuanto
/// incluyera algo que el endpoint no acepta.
class PerfilForm {
  final String? nombre;
  final String? fotoUrl;
  final String? distrito;
  final bool? notificaciones;

  const PerfilForm({
    this.nombre,
    this.fotoUrl,
    this.distrito,
    this.notificaciones,
  });

  Map<String, dynamic> toJson() {
    final datos = <String, dynamic>{};
    if (nombre != null) datos['nombre'] = nombre!.trim();
    if (fotoUrl != null) datos['foto_url'] = fotoUrl;
    if (distrito != null) datos['distrito'] = distrito;
    if (notificaciones != null) datos['notificaciones'] = notificaciones;
    return datos;
  }

  bool get vacio => toJson().isEmpty;
}