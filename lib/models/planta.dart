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
///
/// Es una version corta: para ver sintomas, tratamientos e insumos hay que
/// pedir GET /diagnoses/{id}, que ademas devuelve las imagenes con enlaces
/// recien firmados.
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
///
/// Existe como clase aparte a proposito: el backend rechaza `estado` y
/// `riego_frecuencia_dias`, asi que si mandaramos una Planta serializada
/// entera nos daria 400. Aca solo estan los campos que si se pueden enviar.
///
/// `foto_url` NO va aca. La foto se establece unicamente por
/// POST /plants/{id}/photo; mandarla en este cuerpo devuelve 422.
class PlantaForm {
  final String apodo;
  final Ubicacion ubicacion;
  final Etapa etapa;
  final String? speciesId;
  final DateTime? fechaSiembra;

  const PlantaForm({
    required this.apodo,
    required this.ubicacion,
    required this.etapa,
    this.speciesId,
    this.fechaSiembra,
  });

  Map<String, dynamic> toJson() => {
    'apodo': apodo.trim(),
    'ubicacion': ubicacion.valor,
    'etapa': etapa.valor,
    'species_id': speciesId,
    'fecha_siembra':
    fechaSiembra == null ? null : Json.aFechaApi(fechaSiembra!),
  };

  /// PUT acepta campos parciales, asi que enviamos solo lo que cambio.
  /// Mandar todo funcionaria, pero cambiar `ubicacion` o `species_id` obliga
  /// al backend a recalcular el riego aunque no los hayas tocado.
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
    return cambios;
  }
}