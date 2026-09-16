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

  final List<InsumoComercial> insumosNoCaseros;
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
    required this.insumosNoCaseros,
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
      insumosNoCaseros:
      Json.lista(json['insumos_no_caseros'], InsumoComercial.fromJson),
      imagenUrl: Json.textoNulo(json['imagen_url']),
      gradcamUrl: Json.textoNulo(json['gradcam_url']),
      createdAt: Json.fechaObligatoria(json['created_at']),
    );
  }

  bool get estaVinculado => plantId != null;
  bool get estaSana => estado == EstadoDiagnostico.sana;

  String get confianzaTexto => '${confianza.round()}%';

  /// Retorna la receta ideal según la etiología agronómica y urgencia real.
  Tratamiento? get tratamientoPrincipal {
    if (tratamientos.isEmpty) return null;

    final clase = top3.isNotEmpty ? top3.first.claseRaw.toLowerCase() : '';
    final nombre = nombreEnfermedad.toLowerCase();
    final urg = urgencia.etiqueta.toLowerCase();

    // 1. Virosis por contacto mecánico -> Desinfección de herramientas
    if (clase.contains('mosaic_virus') || nombre.contains('mosaico')) {
      return _buscarPorSlug('leche_herramientas');
    }

    // 2. Virosis o bacterias por vectores voladores -> Trampas amarillas o Jabón potásico
    if (clase.contains('yellow_leaf_curl') ||
        clase.contains('greening') ||
        nombre.contains('rizado amarillo') ||
        nombre.contains('hlb')) {
      return _buscarPorSlug('trampas_amarillas') ?? _buscarPorSlug('jabon_potasico');
    }

    // 3. Plagas de cuerpo blando (ácaros, pulgones) -> Jabón potásico
    if (clase.contains('spider_mites') ||
        clase.contains('aphid') ||
        nombre.contains('ácaros') ||
        nombre.contains('araña') ||
        nombre.contains('pulgón')) {
      return _buscarPorSlug('jabon_potasico');
    }

    // 4. Infecciones destructivas / alta urgencia -> Caldo bordelés
    if (urg.contains('alta') ||
        clase.contains('late_blight') ||
        clase.contains('black_rot') ||
        clase.contains('canker') ||
        nombre.contains('tizón tardío') ||
        nombre.contains('podredumbre negra') ||
        nombre.contains('cancro')) {
      return _buscarPorSlug('caldo_bordeles_casero');
    }

    // 5. Bacteriosis foliares moderadas -> Extracto de ajo y ají (o caldo bordelés si no existe ajo)
    if (nombre.contains('bacteriana') && !nombre.contains('pudrición')) {
      return _buscarPorSlug('ajo_aji') ?? _buscarPorSlug('bicarbonato');
    }

    // 6. Hongos foliares moderados (tizón temprano, royas, manchas) -> Bicarbonato
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

  /// El cultivo detectado no coincide con la especie registrada.
  bool get especieNoCoincide => estaVinculado && !especieConfirmada;

  /// true si hay algo que advertirle al usuario antes de que confie en esto.
  bool get requiereAdvertencia => confianzaBaja || especieNoCoincide;
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
      case 'leche_herramientas':
        return n.contains('leche') || n.contains('herramientas') || n.contains('desinfección');
      case 'trampas_amarillas':
        return n.contains('trampa') || n.contains('amarilla');
      default:
        return false;
    }
  }

  String get planTexto {
    if (frecuenciaDias == 0) return '';
    if (numAplicaciones == 0) {
      return 'Aplicar cada $frecuenciaDias ${frecuenciaDias == 1 ? 'día' : 'días'}';
    }
    final aplicacion = numAplicaciones == 1 ? 'aplicación' : 'aplicaciones';
    return '$numAplicaciones $aplicacion cada $frecuenciaDias '
        '${frecuenciaDias == 1 ? 'día' : 'días'}';
  }
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

class InsumoComercial {
  final String producto;
  final String? presentacion;
  final String? dondeComprar;
  final String? distrito;
  final String? precioReferencial;

  const InsumoComercial({
    required this.producto,
    required this.presentacion,
    required this.dondeComprar,
    required this.distrito,
    required this.precioReferencial,
  });

  factory InsumoComercial.fromJson(Map<String, dynamic> json) {
    return InsumoComercial(
      producto: Json.texto(json['producto']),
      presentacion: Json.textoNulo(json['presentacion']),
      dondeComprar: Json.textoNulo(json['donde_comprar']),
      distrito: Json.textoNulo(json['distrito']),
      precioReferencial: Json.textoNulo(json['precio_referencial']),
    );
  }
}