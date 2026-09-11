import 'package:flutter/material.dart';

import '../app/theme/app_colors.dart';

/// Los valores que viaja el backend vienen sin tildes y con guion bajo
/// (Balcon, Sin_diagnostico). Lo que ve el usuario lleva tildes y espacios.
/// Estos enums guardan las dos caras y evitan comparar strings sueltos por
/// toda la app, que es de donde salen los bugs silenciosos.
///
/// Todos tienen un valor `desconocido` para que, si el backend agrega una
/// opcion nueva, la app la pinte de forma neutra en vez de reventar.

// ------------------------------------------------------------------ ubicacion

enum Ubicacion {
  balcon('Balcon', 'Balcón', Icons.balcony_outlined),
  ventana('Ventana', 'Ventana', Icons.window_outlined),
  terraza('Terraza', 'Terraza', Icons.deck_outlined),
  patio('Patio', 'Patio', Icons.yard_outlined),
  interior('Interior', 'Interior', Icons.home_outlined),
  jardin('Jardin', 'Jardín', Icons.grass_outlined),
  desconocido('', 'Sin ubicación', Icons.place_outlined);

  const Ubicacion(this.valor, this.etiqueta, this.icono);

  /// Lo que se manda y se recibe del backend.
  final String valor;

  /// Lo que ve el usuario.
  final String etiqueta;
  final IconData icono;

  static Ubicacion desde(String? valor) {
    return Ubicacion.values.firstWhere(
          (u) => u.valor == valor,
      orElse: () => Ubicacion.desconocido,
    );
  }

  /// Opciones reales para poblar un selector, sin el comodin.
  static List<Ubicacion> get opciones =>
      Ubicacion.values.where((u) => u != Ubicacion.desconocido).toList();
}

// ---------------------------------------------------------------------- etapa

enum Etapa {
  germinacion('Germinacion', 'Germinación'),
  crecimiento('Crecimiento', 'Crecimiento'),
  floracion('Floracion', 'Floración'),
  fructificacion('Fructificacion', 'Fructificación'),
  cosecha('Cosecha', 'Cosecha'),
  desconocido('', 'Sin etapa');

  const Etapa(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  static Etapa desde(String? valor) {
    return Etapa.values.firstWhere(
          (e) => e.valor == valor,
      orElse: () => Etapa.desconocido,
    );
  }

  static List<Etapa> get opciones =>
      Etapa.values.where((e) => e != Etapa.desconocido).toList();
}

// ------------------------------------------------------------- estado planta

/// Lo calcula el backend a partir de los diagnosticos. Nunca se envia.
enum EstadoPlanta {
  sinDiagnostico('Sin_diagnostico', 'Sin diagnóstico'),
  sana('Sana', 'Sana'),
  enTratamiento('En_tratamiento', 'En tratamiento'),
  desconocido('', 'Desconocido');

  const EstadoPlanta(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  static EstadoPlanta desde(String? valor) {
    return EstadoPlanta.values.firstWhere(
          (e) => e.valor == valor,
      orElse: () => EstadoPlanta.desconocido,
    );
  }

  Color get color {
    switch (this) {
      case EstadoPlanta.sana:
        return AppColors.success;
      case EstadoPlanta.enTratamiento:
        return AppColors.warning;
      case EstadoPlanta.sinDiagnostico:
      case EstadoPlanta.desconocido:
        return AppColors.textTertiary;
    }
  }

  IconData get icono {
    switch (this) {
      case EstadoPlanta.sana:
        return Icons.check_circle;
      case EstadoPlanta.enTratamiento:
        return Icons.healing;
      case EstadoPlanta.sinDiagnostico:
      case EstadoPlanta.desconocido:
        return Icons.help_outline;
    }
  }
}

// ---------------------------------------------------- estado del diagnostico

enum EstadoDiagnostico {
  sana('Sana', 'Sana'),
  enferma('Enferma', 'Enferma'),
  desconocido('', 'Sin determinar');

  const EstadoDiagnostico(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  static EstadoDiagnostico desde(String? valor) {
    return EstadoDiagnostico.values.firstWhere(
          (e) => e.valor == valor,
      orElse: () => EstadoDiagnostico.desconocido,
    );
  }

  Color get color =>
      this == EstadoDiagnostico.sana ? AppColors.success : AppColors.error;
}

// -------------------------------------------------------------------urgencia

enum Urgencia {
  baja('Baja', 'Baja'),
  media('Media', 'Media'),
  alta('Alta', 'Alta'),
  desconocida('', 'Sin definir');

  const Urgencia(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  static Urgencia desde(String? valor) {
    return Urgencia.values.firstWhere(
          (u) => u.valor == valor,
      orElse: () => Urgencia.desconocida,
    );
  }

  Color get color {
    switch (this) {
      case Urgencia.alta:
        return AppColors.error;
      case Urgencia.media:
        return AppColors.warning;
      case Urgencia.baja:
        return AppColors.success;
      case Urgencia.desconocida:
        return AppColors.textTertiary;
    }
  }
}

// ------------------------------------------------------------ tipo actividad

enum TipoActividad {
  riego('Riego', 'Riego', Icons.water_drop_outlined),
  tratamiento('Tratamiento', 'Tratamiento', Icons.healing_outlined),

  /// Cierra el ciclo de tratamiento: al tocarla debe abrirse la camara.
  revision('Revision', 'Revisión', Icons.camera_alt_outlined),
  desconocido('', 'Tarea', Icons.task_alt_outlined);

  const TipoActividad(this.valor, this.etiqueta, this.icono);

  final String valor;
  final String etiqueta;
  final IconData icono;

  static TipoActividad desde(String? valor) {
    return TipoActividad.values.firstWhere(
          (t) => t.valor == valor,
      orElse: () => TipoActividad.desconocido,
    );
  }

  Color get color {
    switch (this) {
      case TipoActividad.riego:
        return AppColors.info;
      case TipoActividad.tratamiento:
        return AppColors.warning;
      case TipoActividad.revision:
        return AppColors.primary;
      case TipoActividad.desconocido:
        return AppColors.textTertiary;
    }
  }
}

// ---------------------------------------------------------- estado actividad

enum EstadoActividad {
  pendiente('Pendiente', 'Pendiente'),
  completada('Completada', 'Completada'),
  desconocido('', 'Pendiente');

  const EstadoActividad(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  static EstadoActividad desde(String? valor) {
    return EstadoActividad.values.firstWhere(
          (e) => e.valor == valor,
      orElse: () => EstadoActividad.desconocido,
    );
  }

  bool get estaCompletada => this == EstadoActividad.completada;
}

// -------------------------------------------------------------- dificultad

enum Dificultad {
  baja('Baja', 'Fácil'),
  media('Media', 'Media'),
  alta('Alta', 'Difícil'),
  desconocida('', 'Sin definir');

  const Dificultad(this.valor, this.etiqueta);

  final String valor;
  final String etiqueta;

  static Dificultad desde(String? valor) {
    return Dificultad.values.firstWhere(
          (d) => d.valor == valor,
      orElse: () => Dificultad.desconocida,
    );
  }
}