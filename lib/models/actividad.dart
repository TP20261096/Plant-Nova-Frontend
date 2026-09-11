import '../core/utils/json.dart';
import 'enums.dart';

/// Tarea del menu Inicio: GET /activities?fecha=YYYY-MM-DD
///
/// Dos cosas cambian como se pinta la lista:
///
/// - Las atrasadas llegan primero, ya ordenadas. No las reordenes.
/// - En fechas futuras los riegos llegan con id null y proyectada true. Son
///   previsiones, no registros: van atenuadas y no se pueden completar.
class Actividad {
  /// null en las actividades proyectadas. Por eso no se puede completar:
  /// no existe todavia en la base de datos.
  final String? id;

  final String plantId;
  final String planta;
  final TipoActividad tipo;
  final EstadoActividad estado;
  final String titulo;
  final String? descripcion;
  final DateTime fechaProgramada;
  final DateTime? fechaCompletada;

  /// Mayor que cero indica retraso. Hay que mostrarlo en la tarjeta.
  final int diasAtraso;

  /// Numero de aplicacion dentro del plan de tratamiento. null en riegos.
  final int? aplicacionNum;
  final int? totalAplicaciones;
  final String? recetaNombre;
  final String? diagnosisId;

  final bool proyectada;

  const Actividad({
    required this.id,
    required this.plantId,
    required this.planta,
    required this.tipo,
    required this.estado,
    required this.titulo,
    required this.descripcion,
    required this.fechaProgramada,
    required this.fechaCompletada,
    required this.diasAtraso,
    required this.aplicacionNum,
    required this.totalAplicaciones,
    required this.recetaNombre,
    required this.diagnosisId,
    required this.proyectada,
  });

  factory Actividad.fromJson(Map<String, dynamic> json) {
    return Actividad(
      id: Json.textoNulo(json['id']),
      plantId: Json.texto(json['plant_id']),
      planta: Json.texto(json['planta']),
      tipo: TipoActividad.desde(Json.textoNulo(json['tipo'])),
      estado: EstadoActividad.desde(Json.textoNulo(json['estado'])),
      titulo: Json.texto(json['titulo']),
      descripcion: Json.textoNulo(json['descripcion']),
      fechaProgramada: Json.fechaObligatoria(json['fecha_programada']),
      fechaCompletada: Json.fecha(json['fecha_completada']),
      diasAtraso: Json.entero(json['dias_atraso']),
      aplicacionNum: Json.enteroNulo(json['aplicacion_num']),
      totalAplicaciones: Json.enteroNulo(json['total_aplicaciones']),
      recetaNombre: Json.textoNulo(json['receta_nombre']),
      diagnosisId: Json.textoNulo(json['diagnosis_id']),
      proyectada: Json.booleano(json['proyectada']),
    );
  }

  bool get completada => estado.estaCompletada;
  bool get atrasada => diasAtraso > 0 && !completada;

  /// Solo se puede marcar lo que existe en la base y esta pendiente.
  bool get sePuedeCompletar => id != null && !proyectada && !completada;

  /// Las de tipo Revision abren la camara en vez de marcarse a mano.
  bool get abreCamara => tipo == TipoActividad.revision;

  /// "Aplicación 2 de 3" para el plan de tratamiento.
  String? get progresoTexto {
    if (aplicacionNum == null || totalAplicaciones == null) return null;
    return 'Aplicación $aplicacionNum de $totalAplicaciones';
  }

  /// "Atrasada 2 días"
  String? get atrasoTexto {
    if (!atrasada) return null;
    return 'Atrasada $diasAtraso ${diasAtraso == 1 ? 'día' : 'días'}';
  }
}

/// Cuerpo de POST /activities, para las tareas que crea el usuario a mano.
class ActividadForm {
  final String plantId;
  final TipoActividad tipo;
  final String titulo;
  final String? descripcion;
  final DateTime fechaProgramada;

  const ActividadForm({
    required this.plantId,
    required this.tipo,
    required this.titulo,
    this.descripcion,
    required this.fechaProgramada,
  });

  Map<String, dynamic> toJson() => {
    'plant_id': plantId,
    'tipo': tipo.valor,
    'titulo': titulo.trim(),
    'descripcion': descripcion?.trim(),
    'fecha_programada': Json.aFechaApi(fechaProgramada),
  };
}