import '../core/utils/json.dart';
import 'enums.dart';

/// Especie de la guia: GET /guide/species
///
/// Este mismo modelo alimenta el selector de especie al registrar una planta:
/// el [id] es el species_id que espera POST /plants.
class Especie {
  final String id;
  final String slug;
  final String nombreComun;
  final String nombreCientifico;
  final String? imagenUrl;
  final String resumen;
  final Dificultad dificultad;
  final int riegoBaseDias;

  /// true si el modelo de diagnostico reconoce este cultivo. Las que no lo
  /// son se pueden registrar igual, pero no se les puede sacar diagnostico.
  final bool diagnosticable;

  const Especie({
    required this.id,
    required this.slug,
    required this.nombreComun,
    required this.nombreCientifico,
    required this.imagenUrl,
    required this.resumen,
    required this.dificultad,
    required this.riegoBaseDias,
    required this.diagnosticable,
  });

  factory Especie.fromJson(Map<String, dynamic> json) {
    return Especie(
      id: Json.texto(json['id']),
      slug: Json.texto(json['slug']),
      nombreComun: Json.texto(json['nombre_comun']),
      nombreCientifico: Json.texto(json['nombre_cientifico']),
      imagenUrl: Json.textoNulo(json['imagen_url']),
      resumen: Json.texto(json['resumen']),
      dificultad: Dificultad.desde(Json.textoNulo(json['dificultad'])),
      riegoBaseDias: Json.entero(json['riego_base_dias']),
      diagnosticable: Json.booleano(json['diagnosticable']),
    );
  }

  /// "Riego cada 3 días"
  String get riegoTexto => riegoBaseDias == 0
      ? 'Riego según necesidad'
      : 'Riego cada $riegoBaseDias ${riegoBaseDias == 1 ? 'día' : 'días'}';
}

/// Ficha completa: GET /guide/species/{slug}
class EspecieDetalle extends Especie {
  final String? familia;
  final String? luzRecomendada;

  /// Ya vienen ordenadas por el backend. Recorrelas tal cual, sin reordenar
  /// ni asumir que siempre son las mismas cinco.
  final List<SeccionGuia> secciones;

  const EspecieDetalle({
    required super.id,
    required super.slug,
    required super.nombreComun,
    required super.nombreCientifico,
    required super.imagenUrl,
    required super.resumen,
    required super.dificultad,
    required super.riegoBaseDias,
    required super.diagnosticable,
    required this.familia,
    required this.luzRecomendada,
    required this.secciones,
  });

  factory EspecieDetalle.fromJson(Map<String, dynamic> json) {
    return EspecieDetalle(
      id: Json.texto(json['id']),
      slug: Json.texto(json['slug']),
      nombreComun: Json.texto(json['nombre_comun']),
      nombreCientifico: Json.texto(json['nombre_cientifico']),
      imagenUrl: Json.textoNulo(json['imagen_url']),
      resumen: Json.texto(json['resumen']),
      dificultad: Dificultad.desde(Json.textoNulo(json['dificultad'])),
      riegoBaseDias: Json.entero(json['riego_base_dias']),
      diagnosticable: Json.booleano(json['diagnosticable']),
      familia: Json.textoNulo(json['familia']),
      luzRecomendada: Json.textoNulo(json['luz_recomendada']),
      secciones: Json.lista(json['secciones'], SeccionGuia.fromJson),
    );
  }
}

/// Un bloque de la ficha: Preparacion, Siembra, Cuidados, Cosecha, Consejos.
class SeccionGuia {
  /// Nombre crudo del backend, sin tildes.
  final String seccion;
  final String contenido;

  const SeccionGuia({required this.seccion, required this.contenido});

  factory SeccionGuia.fromJson(Map<String, dynamic> json) {
    return SeccionGuia(
      seccion: Json.texto(json['seccion']),
      contenido: Json.texto(json['contenido']),
    );
  }

  /// Titulo con tilde para mostrar. Si el backend agrega una seccion nueva,
  /// se muestra su nombre crudo en vez de romperse.
  String get titulo {
    switch (seccion) {
      case 'Preparacion':
        return 'Preparación';
      case 'Siembra':
        return 'Siembra';
      case 'Cuidados':
        return 'Cuidados';
      case 'Cosecha':
        return 'Cosecha';
      case 'Consejos':
        return 'Consejos';
      default:
        return seccion;
    }
  }
}