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

  /// El primero es el plan que el backend programa como actividades.
  /// Los demas son alternativas informativas.
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

  /// El tratamiento que el sistema va a programar como actividades.
  Tratamiento? get tratamientoPrincipal =>
      tratamientos.isEmpty ? null : tratamientos.first;

  /// Alternativas informativas, sin programacion automatica.
  List<Tratamiento> get tratamientosAlternativos =>
      tratamientos.length <= 1 ? const [] : tratamientos.sublist(1);

  /// El cultivo detectado no coincide con la especie registrada.
  ///
  /// Solo tiene sentido cuando el diagnostico ya pertenece a una planta: si
  /// todavia no esta vinculado, no hay especie registrada contra la cual
  /// comparar y el campo no significa nada.
  bool get especieNoCoincide => estaVinculado && !especieConfirmada;

  /// true si hay algo que advertirle al usuario antes de que confie en esto.
  bool get requiereAdvertencia => confianzaBaja || especieNoCoincide;
}

/// Una de las tres clases mas probables que devolvio el modelo.
class Prediccion {
  /// Etiqueta cruda del modelo, tipo Corn_Corn_Gray_leaf_spot.
  /// Sirve para depurar; no la muestres al usuario.
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
  final String nombre;
  final String descripcion;
  final List<Ingrediente> ingredientes;

  /// Pasos ya ordenados.
  final List<String> preparacion;

  final String modoUso;
  final String? precauciones;
  final String? costoAprox;
  final int frecuenciaDias;
  final int numAplicaciones;
  final String? nota;

  const Tratamiento({
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

  /// "3 aplicaciones cada 7 dias"
  String get planTexto {
    if (numAplicaciones == 0 || frecuenciaDias == 0) return '';
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

/// Producto de tienda, con punto de venta. El backend filtra estos resultados
/// por el distrito del perfil del usuario.
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