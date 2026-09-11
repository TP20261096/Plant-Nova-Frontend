import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../models/actividad.dart';

/// Tarjeta del menu Inicio. Reemplaza a ActivityCard, que recibia un
/// Map<String, dynamic> sin tipos y un emoji como icono.
///
/// Tres estados que la anterior no sabia representar:
///  - atrasada: borde rojo y cuantos dias lleva,
///  - proyectada: atenuada y sin boton, porque todavia no existe en la base
///    de datos y no se puede completar,
///  - revision: en vez de marcarse, abre la camara.
class ActividadCard extends StatelessWidget {
  final Actividad actividad;

  /// Se llama al tocar el boton de completar.
  final VoidCallback? onCompletar;

  /// Se llama en las actividades de tipo Revision, que abren la camara.
  final VoidCallback? onRevisar;

  final bool completando;

  const ActividadCard({
    Key? key,
    required this.actividad,
    this.onCompletar,
    this.onRevisar,
    this.completando = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final proyectada = actividad.proyectada;

    return Opacity(
      // Las proyectadas son una prevision, no una tarea real. Atenuarlas
      // comunica eso sin necesidad de explicarlo.
      opacity: proyectada ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: actividad.atrasada
              ? Border.all(color: AppColors.error.withOpacity(0.5))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _icono(),
            const SizedBox(width: 12),
            Expanded(child: _texto(isDark)),
            const SizedBox(width: 8),
            _accion(),
          ],
        ),
      ),
    );
  }

  Widget _icono() {
    final color = actividad.tipo.color;
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(actividad.tipo.icono, size: 22, color: color),
    );
  }

  Widget _texto(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          actividad.titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.titleMedium.copyWith(
            fontSize: 14,
            decoration:
            actividad.completada ? TextDecoration.lineThrough : null,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          actividad.planta,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 11,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
        if (actividad.progresoTexto != null) ...[
          const SizedBox(height: 3),
          Text(
            actividad.progresoTexto!,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 10,
              color: AppColors.textTertiary,
            ),
          ),
        ],
        if (actividad.atrasoTexto != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              actividad.atrasoTexto!,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _accion() {
    if (completando) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (actividad.completada) {
      return const Icon(Icons.check_circle,
          color: AppColors.success, size: 26);
    }

    if (actividad.proyectada) {
      return const Icon(Icons.schedule,
          color: AppColors.textTertiary, size: 22);
    }

    // Una revision no se marca a mano: se cierra sacando una foto nueva,
    // que es lo que le da al backend la evidencia de si el tratamiento sirvio.
    if (actividad.abreCamara) {
      return IconButton(
        onPressed: onRevisar,
        icon: const Icon(Icons.camera_alt_outlined,
            color: AppColors.primary, size: 24),
        tooltip: 'Revisar con la cámara',
      );
    }

    return IconButton(
      onPressed: onCompletar,
      icon: const Icon(Icons.radio_button_unchecked,
          color: AppColors.textTertiary, size: 26),
      tooltip: 'Marcar como hecha',
    );
  }
}