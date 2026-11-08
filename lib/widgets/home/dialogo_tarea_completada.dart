import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../models/actividad.dart';
import '../../models/enums.dart';

/// Confirmacion que aparece al marcar una tarea como completada (HU033).
///
/// Antes vivia duplicada en Inicio y en el detalle del dia, y ambas copias
/// inventaban la fecha siguiente en el cliente: sumaban dias a la fecha
/// actual y deducian el intervalo del tratamiento buscando la palabra
/// "bordel" en el titulo. Ahora la siguiente tarea es la que devuelve el
/// backend en proxima_tarea, que la calcula desde la fecha real de
/// cumplimiento y con el clima del dia.
void mostrarDialogoTareaCompletada(
  BuildContext context, {
  required Actividad completada,
  required Actividad? proxima,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final esRiego = completada.tipo == TipoActividad.riego;
  final numActual = completada.aplicacionNum;
  final total = completada.totalAplicaciones;
  final esUltimaDosis =
      numActual != null && total != null && numActual >= total;

  final String titulo;
  final String detalle;

  if (esRiego) {
    titulo = '¡Riego registrado!';
    detalle = 'Has registrado el riego de ${completada.planta}.';
  } else if (numActual != null && total != null && total > 1) {
    titulo = esUltimaDosis ? '¡Tratamiento terminado!' : '¡Tratamiento aplicado!';
    detalle = esUltimaDosis
        ? '¡Completaste el ciclo de $total aplicaciones de '
            '${completada.planta}!'
        : 'Has completado la dosis $numActual de $total de '
            '${completada.planta}.';
  } else {
    titulo = '¡Actividad completada!';
    detalle = 'Has completado la actividad de ${completada.planta}.';
  }

  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
              size: 38,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color:
                  isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detalle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          _BandaProxima(proxima: proxima),
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Entendido'),
          ),
        ),
      ],
    ),
  );
}

/// Banda inferior con la siguiente tarea del jardin, o el "todo al día"
/// cuando el backend devuelve proxima_tarea en null.
class _BandaProxima extends StatelessWidget {
  final Actividad? proxima;

  const _BandaProxima({required this.proxima});

  @override
  Widget build(BuildContext context) {
    final p = proxima;

    if (p == null) {
      return _caja(
        color: AppColors.success,
        icono: Icons.task_alt,
        texto: 'Todo al día. No te queda ninguna tarea pendiente.',
      );
    }

    return _caja(
      color: p.tipo.color,
      icono: p.tipo.icono,
      texto: 'Próxima tarea: ${p.titulo}\n'
          '${p.planta} · ${_fecha(p.fechaProgramada)}',
    );
  }

  Widget _caja({
    required Color color,
    required IconData icono,
    required String texto,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "hoy", "mañana" o "jueves 12 de noviembre".
  String _fecha(DateTime f) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final dia = DateTime(f.year, f.month, f.day);
    final diferencia = dia.difference(hoy).inDays;

    if (diferencia == 0) return 'hoy';
    if (diferencia == 1) return 'mañana';

    const dias = [
      'lunes', 'martes', 'miércoles', 'jueves',
      'viernes', 'sábado', 'domingo',
    ];
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${dias[f.weekday - 1]} ${f.day} de ${meses[f.month - 1]}';
  }
}
