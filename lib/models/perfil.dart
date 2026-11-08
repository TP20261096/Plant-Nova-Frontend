import '../core/utils/json.dart';
import 'enums.dart';
import 'usuario.dart';

/// GET /profile
///
/// Es la version extendida del [Usuario] que devuelve auth. El distrito no es
/// decorativo: determina el clima de referencia con el que el backend calcula
/// el riego de todas las plantas, y solo admite los valores que devuelve
/// GET /profile/districts.
class Perfil {
  final String id;
  final String email;
  final String nombre;
  final String? fotoUrl;
  final String? distrito;
  final bool notificaciones;
  /// Apariencia elegida por el usuario. Vive en el perfil y no solo en el
  /// dispositivo, asi que le acompana si entra desde otro telefono.
  final Tema tema;

  /// Contadores del resumen de actividad (HU004). Los calcula el backend.
  final int plantasRegistradas;
  final int diagnosticosRealizados;
  final int tareasPendientes;
  final int tareasCompletadas;

  final DateTime? createdAt;

  const Perfil({
    required this.id,
    required this.email,
    required this.nombre,
    required this.fotoUrl,
    required this.distrito,
    required this.notificaciones,
    required this.tema,
    required this.plantasRegistradas,
    required this.diagnosticosRealizados,
    required this.tareasPendientes,
    required this.tareasCompletadas,
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
      tema: Tema.desde(Json.textoNulo(json['tema'])),
      plantasRegistradas: Json.entero(json['plantas_registradas']),
      diagnosticosRealizados: Json.entero(json['diagnosticos_realizados']),
      tareasPendientes: Json.entero(json['tareas_pendientes']),
      tareasCompletadas: Json.entero(json['tareas_completadas']),
      createdAt: Json.fecha(json['created_at']),
    );
  }

  /// Para refrescar el nombre que muestra la barra superior sin volver a
  /// pedir /auth/me despues de editar el perfil.
  Usuario get usuario => Usuario(id: id, email: email, nombre: nombre);

  bool get tieneDistrito => distrito != null && distrito!.isNotEmpty;

  String get iniciales => usuario.iniciales;
}

/// Cuerpo de PATCH /profile. Solo admite nombre, distrito, notificaciones y
/// tema, y solo se envian los que cambiaron.
///
/// La foto NO va aqui: se sube con POST /profile/avatar.
class PerfilForm {
  final String? nombre;
  final String? distrito;
  final bool? notificaciones;
  final Tema? tema;

  const PerfilForm({
    this.nombre,
    this.distrito,
    this.notificaciones,
    this.tema,
  });

  Map<String, dynamic> toJson() {
    final datos = <String, dynamic>{};
    if (nombre != null) datos['nombre'] = nombre!.trim();
    if (distrito != null) datos['distrito'] = distrito;
    if (notificaciones != null) datos['notificaciones'] = notificaciones;
    if (tema != null) datos['tema'] = tema!.valor;
    return datos;
  }

  bool get vacio => toJson().isEmpty;
}