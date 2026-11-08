import '../core/utils/json.dart';
import 'enums.dart';

/// Respuesta completa de POST /diagnose y GET /diagnoses/{id}.
///
/// Ojo con las imagenes: `imagenUrl` y `gradcamUrl` son enlaces firmados que
/// caducan en una hora. No los persistas ni los metas en cache de disco; si
/// hace falta volver a mostrarlos, pide el diagnostico otra vez.
class Diagnostico {
  final String id;

  /// null cuando el diagnostico todavia no se vinculo a una planta.
  final String? plantId;

  final EstadoDiagnostico estado;
  final String cultivo;
  final String? especieSlug;
  final String nombreEnfermedad;
  final String? nombreCientifico;
  final double confianza;

  /// Por debajo del 60 % el modelo no esta seguro. Suele pasar cuando la foto
  /// no es una hoja. Hay que advertir en vez de presentar el resultado como
  /// certero.
  final bool confianzaBaja;

  /// false cuando el cultivo detectado no coincide con la especie registrada
  /// en la planta. Hay que avisarle al usuario, no asumir que corresponde.
  final bool especieConfirmada;

  final Urgencia urgencia;
  final List<Prediccion> top3;

  /// Texto corrido, no lista de vinetas.
  final String descripcion;
  final String sintomas;
  final String causas;
  final String prevencion;

  final int riegoFrecuenciaDias;
  final String? riegoNota;
  final String? otrosCuidados;

  /// Lista cruda de tratamientos disponibles para este diagnóstico.
  final List<Tratamiento> tratamientos;

  final String? imagenUrl;
  final String? gradcamUrl;
  final DateTime createdAt;

  const Diagnostico({
    required this.id,
    required this.plantId,
    required this.estado,
    required this.cultivo,
    required this.especieSlug,
    required this.nombreEnfermedad,
    required this.nombreCientifico,
    required this.confianza,
    required this.confianzaBaja,
    required this.especieConfirmada,
    required this.urgencia,
    required this.top3,
    required this.descripcion,
    required this.sintomas,
    required this.causas,
    required this.prevencion,
    required this.riegoFrecuenciaDias,
    required this.riegoNota,
    required this.otrosCuidados,
    required this.tratamientos,
    required this.imagenUrl,
    required this.gradcamUrl,
    required this.createdAt,
  });

  factory Diagnostico.fromJson(Map<String, dynamic> json) {
    return Diagnostico(
      id: Json.texto(json['id']),
      plantId: Json.textoNulo(json['plant_id']),
      estado: EstadoDiagnostico.desde(Json.textoNulo(json['estado'])),
      cultivo: Json.texto(json['cultivo']),
      especieSlug: Json.textoNulo(json['especie_slug']),
      nombreEnfermedad: Json.texto(json['nombre_enfermedad']),
      nombreCientifico: Json.textoNulo(json['nombre_cientifico']),
      confianza: Json.decimal(json['confianza']),
      confianzaBaja: Json.booleano(json['confianza_baja']),
      especieConfirmada: Json.booleano(json['especie_confirmada'], siNulo: true),
      urgencia: Urgencia.desde(Json.textoNulo(json['urgencia'])),
      top3: Json.lista(json['top3'], Prediccion.fromJson),
      descripcion: Json.texto(json['descripcion']),
      sintomas: Json.texto(json['sintomas']),
      causas: Json.texto(json['causas']),
      prevencion: Json.texto(json['prevencion']),
      riegoFrecuenciaDias: Json.entero(json['riego_frecuencia_dias']),
      riegoNota: Json.textoNulo(json['riego_nota']),
      otrosCuidados: Json.textoNulo(json['otros_cuidados']),
      tratamientos: Json.lista(json['tratamientos'], Tratamiento.fromJson),
      imagenUrl: Json.textoNulo(json['imagen_url']),
      gradcamUrl: Json.textoNulo(json['gradcam_url']),
      createdAt: Json.fechaObligatoria(json['created_at']),
    );
  }

  bool get estaVinculado => plantId != null;
  bool get estaSana => estado == EstadoDiagnostico.sana;

  String get confianzaTexto => '${confianza.round()}%';

  /// Determina si la patología es incurable por métodos caseros y requiere erradicación o saneamiento.
  bool get esIncurable {
    final cientifico = (nombreCientifico ?? '').toLowerCase();
    final nombre = nombreEnfermedad.toLowerCase();
    return cientifico.contains('tomv') ||
        cientifico.contains('tylcv') ||
        cientifico.contains('liberibacter') ||
        cientifico.contains('plasmodiophora') ||
        nombre.contains('virus') ||
        nombre.contains('mosaico') ||
        nombre.contains('rizado amarillo') ||
        nombre.contains('hlb') ||
        nombre.contains('hernia de la col');
  }

  /// Verifica si la enfermedad amerita reporte o vigilancia oficial ante SENASA Perú.
  bool get requiereReporteSenasa {
    final cientifico = (nombreCientifico ?? '').toLowerCase();
    final nombre = nombreEnfermedad.toLowerCase();
    return cientifico.contains('liberibacter') ||
        cientifico.contains('citri') ||
        cientifico.contains('citricarpa') ||
        nombre.contains('hlb') ||
        nombre.contains('cancro') ||
        nombre.contains('mancha negra');
  }

  /// Retorna la receta ideal según la etiología agronómica y urgencia real.
  Tratamiento? get tratamientoPrincipal {
    if (tratamientos.isEmpty) return null;

    final cientifico = (nombreCientifico ?? '').toLowerCase();
    final nombre = nombreEnfermedad.toLowerCase();

    // 1. Virosis mecánicas -> Desinfección de herramientas
    if (cientifico.contains('tomv') || nombre.contains('mosaico')) {
      return _buscarPorSlug('desinfeccion_alcohol') ??
          _buscarPorSlug('leche_herramientas');
    }

    // 2. Transmitidas por vectores voladores -> Trampas amarillas o Jabón potásico
    if (cientifico.contains('tylcv') ||
        cientifico.contains('liberibacter') ||
        nombre.contains('rizado amarillo') ||
        nombre.contains('hlb')) {
      return _buscarPorSlug('trampas_amarillas') ?? _buscarPorSlug('jabon_potasico');
    }

    // 3. Plagas de cuerpo blando (araña roja, pulgones) -> Jabón potásico
    if (cientifico.contains('urticae') ||
        cientifico.contains('aphid') ||
        nombre.contains('ácaro') ||
        nombre.contains('araña') ||
        nombre.contains('pulgón')) {
      return _buscarPorSlug('jabon_potasico');
    }

    // 4. Infecciones destructivas o de alta urgencia -> Desinfección o Caldo bordelés protector
    if (urgencia == Urgencia.alta ||
        cientifico.contains('infestans') ||
        cientifico.contains('pseudomonas') ||
        cientifico.contains('xanthomonas') ||
        nombre.contains('tizón tardío') ||
        nombre.contains('podredumbre') ||
        nombre.contains('cancro')) {
      return _buscarPorSlug('desinfeccion_alcohol') ??
          _buscarPorSlug('caldo_bordeles_casero') ??
          tratamientos.first;
    }

    // 5. Hongos foliares moderados (oídio, tizón temprano, cercospora) -> Bicarbonato
    return _buscarPorSlug('bicarbonato') ?? tratamientos.first;
  }

  /// Devuelve las recetas restantes excluyendo la seleccionada como principal.
  List<Tratamiento> get tratamientosAlternativos {
    final principal = tratamientoPrincipal;
    if (principal == null) return const [];
    return tratamientos.where((t) => t != principal).toList();
  }

  Tratamiento? _buscarPorSlug(String slugBuscado) {
    for (final t in tratamientos) {
      if (t.identificadorCoincide(slugBuscado)) {
        return t;
      }
    }
    return null;
  }

  /// Si hay algo que advertirle al usuario sobre el propio diagnostico.
  ///
  /// La discrepancia de especie NO se decide aqui: especie_confirmada llega
  /// en false tanto cuando el cultivo no coincide como cuando no habia
  /// especie con la que comparar, y distinguir los dos casos exige saber si
  /// la captura se hizo sobre una planta ya registrada. Eso lo sabe
  /// DiagnosticoProvider.especieNoCoincide.
  bool get requiereAdvertencia => confianzaBaja;
}

/// Una de las tres clases mas probables que devolvio el modelo.
class Prediccion {
  final String claseRaw;
  final String nombreEnfermedad;
  final double confianza;

  const Prediccion({
    required this.claseRaw,
    required this.nombreEnfermedad,
    required this.confianza,
  });

  factory Prediccion.fromJson(Map<String, dynamic> json) {
    return Prediccion(
      claseRaw: Json.texto(json['clase_raw']),
      nombreEnfermedad: Json.texto(json['nombre_enfermedad']),
      confianza: Json.decimal(json['confianza']),
    );
  }

  String get confianzaTexto => '${confianza.round()}%';
}

/// Receta casera con su preparacion y su plan de aplicacion.
class Tratamiento {
  final String? recetaSlug;
  final String nombre;
  final String descripcion;
  final List<Ingrediente> ingredientes;
  final List<String> preparacion;
  final String modoUso;
  final String? precauciones;
  final String? costoAprox;
  final int frecuenciaDias;
  final int numAplicaciones;
  final String? nota;

  /// Respaldo documental del remedio, para el final de la seccion de
  /// tratamiento. Puede venir vacia.
  final List<FuenteTratamiento> fuentes;

  const Tratamiento({
    this.recetaSlug,
    required this.nombre,
    required this.descripcion,
    required this.ingredientes,
    required this.preparacion,
    required this.modoUso,
    required this.precauciones,
    required this.costoAprox,
    required this.frecuenciaDias,
    required this.numAplicaciones,
    required this.nota,
    this.fuentes = const [],
  });

  factory Tratamiento.fromJson(Map<String, dynamic> json) {
    return Tratamiento(
      recetaSlug: Json.textoNulo(json['receta_slug']),
      nombre: Json.texto(json['nombre']),
      descripcion: Json.texto(json['descripcion']),
      ingredientes: Json.lista(json['ingredientes'], Ingrediente.fromJson),
      preparacion: Json.listaTexto(json['preparacion']),
      modoUso: Json.texto(json['modo_uso']),
      precauciones: Json.textoNulo(json['precauciones']),
      costoAprox: Json.textoNulo(json['costo_aprox']),
      frecuenciaDias: Json.entero(json['frecuencia_dias']),
      numAplicaciones: Json.entero(json['num_aplicaciones']),
      nota: Json.textoNulo(json['nota']),
      fuentes: Json.lista(json['fuentes'], FuenteTratamiento.fromJson),
    );
  }

  /// Verifica si el tratamiento corresponde al slug solicitado (por campo o por nombre).
  bool identificadorCoincide(String slugBuscado) {
    if (recetaSlug != null && recetaSlug!.toLowerCase() == slugBuscado.toLowerCase()) {
      return true;
    }
    final n = nombre.toLowerCase();
    switch (slugBuscado) {
      case 'bicarbonato':
        return n.contains('bicarbonato');
      case 'caldo_bordeles_casero':
        return n.contains('bordel') || n.contains('cobre');
      case 'jabon_potasico':
        return n.contains('potásico') || n.contains('potasico') || n.contains('jabón');
      case 'ajo_aji':
        return n.contains('ajo') || n.contains('ají') || n.contains('aji');
      case 'desinfeccion_alcohol':
      case 'leche_herramientas':
        return n.contains('alcohol') ||
            n.contains('desinfección') ||
            n.contains('desinfeccion') ||
            n.contains('herramientas') ||
            n.contains('leche');
      case 'trampas_amarillas':
        return n.contains('trampa') || n.contains('amarilla');
      default:
        return false;
    }
  }

  String get planTexto {
    if (frecuenciaDias == 0) return '';
    if (numAplicaciones == 0) {
      return 'Aplicar cada $frecuenciaDias${frecuenciaDias == 1 ? 'día' : 'días'}';
    }
    final aplicacion = numAplicaciones == 1 ? 'aplicación' : 'aplicaciones';
    return '$numAplicaciones $aplicacion cada $frecuenciaDias '
        '${frecuenciaDias == 1 ? 'día' : 'días'}';
  }
}

/// Referencia externa que respalda un tratamiento (HU026.4).
class FuenteTratamiento {
  final String titulo;
  final String? url;

  const FuenteTratamiento({required this.titulo, required this.url});

  factory FuenteTratamiento.fromJson(Map<String, dynamic> json) {
    return FuenteTratamiento(
      titulo: Json.texto(json['titulo'], siNulo: 'Fuente'),
      url: Json.textoNulo(json['url']),
    );
  }

  bool get tieneEnlace => url != null && url!.startsWith('http');
}

class Ingrediente {
  final String item;
  final String cantidad;

  const Ingrediente({required this.item, required this.cantidad});

  factory Ingrediente.fromJson(Map<String, dynamic> json) {
    return Ingrediente(
      item: Json.texto(json['item']),
      cantidad: Json.texto(json['cantidad']),
    );
  }
}