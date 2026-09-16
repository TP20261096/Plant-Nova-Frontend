import '../core/utils/json.dart';
import 'enums.dart';

/// Planta tal como llega en la lista: GET /plants
///
/// Todo lo relacionado con el riego lo calcula el backend cruzando la especie
/// o el diagnostico con el clima del dia y la ubicacion. La app solo lo pinta.
class Planta {
  final String id;
  final String apodo;

  /// Nombre comun de la especie. Es null cuando el usuario registro algo que
  /// no esta en la guia (species_id opcional).
  final String? especie;

  final Ubicacion ubicacion;
  final Etapa etapa;
  final EstadoPlanta estado;
  final String? fotoUrl;

  final int riegoFrecuenciaDias;
  final DateTime? ultimoRiego;
  final DateTime? proximoRiego;

  /// Negativo significa riego atrasado.
  final int diasParaRiego;

  /// Fecha programada para la siguiente aplicación o revisión (si está en tratamiento).
  final DateTime? proximoTratamiento;

  /// Días restantes calculados directamente por el backend si están disponibles.
  final int? diasParaTratamientoBackend;

  const Planta({
    required this.id,
    required this.apodo,
    required this.especie,
    required this.ubicacion,
    required this.etapa,
    required this.estado,
    required this.fotoUrl,
    required this.riegoFrecuenciaDias,
    required this.ultimoRiego,
    required this.proximoRiego,
    required this.diasParaRiego,
    this.proximoTratamiento,
    this.diasParaTratamientoBackend,
  });

  factory Planta.fromJson(Map<String, dynamic> json) {
    return Planta(
      id: Json.texto(json['id']),
      apodo: Json.texto(json['apodo']),
      especie: Json.textoNulo(json['especie']),
      ubicacion: Ubicacion.desde(Json.textoNulo(json['ubicacion'])),
      etapa: Etapa.desde(Json.textoNulo(json['etapa'])),
      estado: EstadoPlanta.desde(Json.textoNulo(json['estado'])),
      fotoUrl: Json.textoNulo(json['foto_url']),
      riegoFrecuenciaDias: Json.entero(json['riego_frecuencia_dias']),
      ultimoRiego: Json.fecha(json['ultimo_riego']),
      proximoRiego: Json.fecha(json['proximo_riego']),
      diasParaRiego: Json.entero(json['dias_para_riego']),
      proximoTratamiento: Json.fecha(
        json['proximo_tratamiento'] ??
            json['proxima_aplicacion'] ??
            json['proxima_dosis'],
      ),
      diasParaTratamientoBackend: json['dias_para_tratamiento'] != null
          ? Json.entero(json['dias_para_tratamiento'])
          : null,
    );
  }

  /// Texto para el selector de especie cuando la planta no tiene una asociada.
  String get especieVisible => especie ?? 'Especie no registrada';

  bool get riegoAtrasado => diasParaRiego < 0;
  bool get riegoHoy => diasParaRiego == 0;

  /// "Riego atrasado 2 dias" / "Regar hoy" / "Riego en 4 dias"
  String get textoRiego {
    if (ultimoRiego == null && proximoRiego == null) return 'Sin riego programado';
    if (riegoHoy) return 'Regar hoy';
    if (riegoAtrasado) {
      final dias = diasParaRiego.abs();
      return 'Riego atrasado $dias ${dias == 1 ? 'día' : 'días'}';
    }
    return 'Riego en $diasParaRiego ${diasParaRiego == 1 ? 'día' : 'días'}';
  }

  // ═══════════════════════════════════════════════════════════
  // CÁLCULOS DE TRATAMIENTO
  // ═══════════════════════════════════════════════════════════

  int? get diasParaTratamiento {
    if (diasParaTratamientoBackend != null) return diasParaTratamientoBackend;
    if (proximoTratamiento == null) return null;

    final ahora = DateTime.now();
    final fechaBase = DateTime(ahora.year, ahora.month, ahora.day);
    final fechaObj = DateTime(
      proximoTratamiento!.year,
      proximoTratamiento!.month,
      proximoTratamiento!.day,
    );
    return fechaObj.difference(fechaBase).inDays;
  }

  bool get tratamientoAtrasado => (diasParaTratamiento ?? 1) < 0;
  bool get tratamientoHoy => (diasParaTratamiento ?? 1) == 0;

  /// "Dosis hoy" / "Dosis atrasada 2 días" / "Dosis en 3 días"
  String get textoTratamiento {
    final dias = diasParaTratamiento;
    if (dias == null) return 'Dosis programada';
    if (dias == 0) return 'Dosis hoy';
    if (dias < 0) {
      final diff = dias.abs();
      return 'Dosis atrasada $diff ${diff == 1 ? 'día' : 'días'}';
    }
    if (dias == 1) return 'Dosis en 1 día';
    return 'Dosis en $dias días';
  }
}

/// Planta completa: GET /plants/{id}
///
/// Anade los datos que solo aparecen en el detalle. `riegoNota` y
/// `otrosCuidados` salen del ultimo diagnostico, asi que son null mientras la
/// planta no tenga ninguno.
class PlantaDetalle extends Planta {
  final String? speciesId;
  final DateTime? fechaSiembra;
  final String? riegoNota;
  final String? otrosCuidados;
  final DateTime? createdAt;
  final List<DiagnosticoResumen> diagnosticos;

  const PlantaDetalle({
    required super.id,
    required super.apodo,
    required super.especie,
    required super.ubicacion,
    required super.etapa,
    required super.estado,
    required super.fotoUrl,
    required super.riegoFrecuenciaDias,
    required super.ultimoRiego,
    required super.proximoRiego,
    required super.diasParaRiego,
    super.proximoTratamiento,
    super.diasParaTratamientoBackend,
    required this.speciesId,
    required this.fechaSiembra,
    required this.riegoNota,
    required this.otrosCuidados,
    required this.createdAt,
    required this.diagnosticos,
  });

  factory PlantaDetalle.fromJson(Map<String, dynamic> json) {
    return PlantaDetalle(
      id: Json.texto(json['id']),
      apodo: Json.texto(json['apodo']),
      especie: Json.textoNulo(json['especie']),
      ubicacion: Ubicacion.desde(Json.textoNulo(json['ubicacion'])),
      etapa: Etapa.desde(Json.textoNulo(json['etapa'])),
      estado: EstadoPlanta.desde(Json.textoNulo(json['estado'])),
      fotoUrl: Json.textoNulo(json['foto_url']),
      riegoFrecuenciaDias: Json.entero(json['riego_frecuencia_dias']),
      ultimoRiego: Json.fecha(json['ultimo_riego']),
      proximoRiego: Json.fecha(json['proximo_riego']),
      diasParaRiego: Json.entero(json['dias_para_riego']),
      proximoTratamiento: Json.fecha(
        json['proximo_tratamiento'] ??
            json['proxima_aplicacion'] ??
            json['proxima_dosis'],
      ),
      diasParaTratamientoBackend: json['dias_para_tratamiento'] != null
          ? Json.entero(json['dias_para_tratamiento'])
          : null,
      speciesId: Json.textoNulo(json['species_id']),
      fechaSiembra: Json.fecha(json['fecha_siembra']),
      riegoNota: Json.textoNulo(json['riego_nota']),
      otrosCuidados: Json.textoNulo(json['otros_cuidados']),
      createdAt: Json.fecha(json['created_at']),
      diagnosticos:
      Json.lista(json['diagnosticos'], DiagnosticoResumen.fromJson),
    );
  }

  bool get tieneDiagnosticos => diagnosticos.isNotEmpty;

  /// El backend ya los manda del mas reciente al mas antiguo.
  DiagnosticoResumen? get ultimoDiagnostico =>
      diagnosticos.isEmpty ? null : diagnosticos.first;
}

/// Diagnostico resumido dentro del detalle de una planta.
class DiagnosticoResumen {
  final String id;
  final String nombreEnfermedad;
  final EstadoDiagnostico estado;
  final double confianza;

  /// Enlace firmado que caduca en una hora. No lo guardes en cache.
  final String? imagenUrl;
  final DateTime createdAt;

  const DiagnosticoResumen({
    required this.id,
    required this.nombreEnfermedad,
    required this.estado,
    required this.confianza,
    required this.imagenUrl,
    required this.createdAt,
  });

  factory DiagnosticoResumen.fromJson(Map<String, dynamic> json) {
    return DiagnosticoResumen(
      id: Json.texto(json['id']),
      nombreEnfermedad: Json.texto(json['nombre_enfermedad']),
      estado: EstadoDiagnostico.desde(Json.textoNulo(json['estado'])),
      confianza: Json.decimal(json['confianza']),
      imagenUrl: Json.textoNulo(json['imagen_url']),
      createdAt: Json.fechaObligatoria(json['created_at']),
    );
  }

  /// "79%" para pintar en la tarjeta.
  String get confianzaTexto => '${confianza.round()}%';
}

/// Cuerpo de POST /plants y PUT /plants/{id}.
class PlantaForm {
  final String apodo;
  final Ubicacion ubicacion;
  final Etapa etapa;
  final String? speciesId;
  final DateTime? fechaSiembra;
  final DateTime? ultimoRiego;

  const PlantaForm({
    required this.apodo,
    required this.ubicacion,
    required this.etapa,
    this.speciesId,
    this.fechaSiembra,
    this.ultimoRiego,
  });

  Map<String, dynamic> toJson() => {
    'apodo': apodo.trim(),
    'ubicacion': ubicacion.valor,
    'etapa': etapa.valor,
    'species_id': speciesId,
    'fecha_siembra':
    fechaSiembra == null ? null : Json.aFechaApi(fechaSiembra!),
    'ultimo_riego':
    ultimoRiego == null ? null : Json.aFechaApi(ultimoRiego!),
  };

  Map<String, dynamic> toJsonParcial(PlantaDetalle original) {
    final cambios = <String, dynamic>{};
    if (apodo.trim() != original.apodo) cambios['apodo'] = apodo.trim();
    if (ubicacion != original.ubicacion) {
      cambios['ubicacion'] = ubicacion.valor;
    }
    if (etapa != original.etapa) cambios['etapa'] = etapa.valor;
    if (speciesId != original.speciesId) cambios['species_id'] = speciesId;

    final fechaOriginal = original.fechaSiembra;
    final cambioFecha = fechaSiembra == null
        ? fechaOriginal != null
        : fechaOriginal == null ||
        Json.aFechaApi(fechaSiembra!) != Json.aFechaApi(fechaOriginal);
    if (cambioFecha) {
      cambios['fecha_siembra'] =
      fechaSiembra == null ? null : Json.aFechaApi(fechaSiembra!);
    }

    final ultimoOriginal = original.ultimoRiego;
    final cambioUltimo = ultimoRiego == null
        ? ultimoOriginal != null
        : ultimoOriginal == null ||
        Json.aFechaApi(ultimoRiego!) != Json.aFechaApi(ultimoOriginal);
    if (cambioUltimo) {
      cambios['ultimo_riego'] =
      ultimoRiego == null ? null : Json.aFechaApi(ultimoRiego!);
    }

    return cambios;
  }
}