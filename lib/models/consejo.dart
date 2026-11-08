import 'package:flutter/material.dart';

import '../core/utils/json.dart';

/// GET /tips — consejos generales de la pantalla de Inicio.
///
/// Vienen ya ordenados y no dependen del jardin: se muestran aunque el
/// usuario todavia no tenga plantas registradas.
class Consejo {
  final String id;

  /// Identificador estable del consejo, tipo riego_manana. Lo usamos para
  /// elegir el icono: el backend no manda ninguno.
  final String slug;

  final String titulo;
  final String contenido;

  const Consejo({
    required this.id,
    required this.slug,
    required this.titulo,
    required this.contenido,
  });

  factory Consejo.fromJson(Map<String, dynamic> json) {
    return Consejo(
      id: Json.texto(json['id']),
      slug: Json.texto(json['slug']),
      titulo: Json.texto(json['titulo']),
      contenido: Json.texto(json['contenido']),
    );
  }

  /// Icono deducido del slug. Es decoracion, no contenido: si el slug no
  /// coincide con ninguno conocido se usa uno neutro en vez de fallar.
  IconData get icono {
    final s = slug.toLowerCase();
    if (s.contains('riego') || s.contains('agua')) return Icons.water_drop;
    if (s.contains('luz') || s.contains('sol')) return Icons.wb_sunny;
    if (s.contains('abono') || s.contains('compost') || s.contains('nutri')) {
      return Icons.eco;
    }
    if (s.contains('poda') || s.contains('corte')) return Icons.content_cut;
    if (s.contains('plaga') || s.contains('monitor') || s.contains('hoja')) {
      return Icons.bug_report;
    }
    if (s.contains('suelo') || s.contains('sustrato') || s.contains('maceta')) {
      return Icons.grass;
    }
    return Icons.lightbulb_outline;
  }
}
