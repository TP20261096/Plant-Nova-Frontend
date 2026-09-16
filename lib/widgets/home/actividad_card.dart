import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../models/actividad.dart';

class ActividadCard extends StatelessWidget {
  final Actividad actividad;
  final VoidCallback? onCompletar;
  final VoidCallback? onRevisar;
  final VoidCallback? onTap;
  final bool completando;

  const ActividadCard({
    Key? key,
    required this.actividad,
    this.onCompletar,
    this.onRevisar,
    this.onTap,
    this.completando = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final proyectada = actividad.proyectada;

    return Opacity(
      opacity: proyectada ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
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
    Widget contenido;

    if (completando) {
      contenido = const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.2),
      );
    } else if (actividad.completada) {
      contenido = const Icon(
        Icons.check_circle,
        color: AppColors.success,
        size: 26,
      );
    } else if (actividad.proyectada) {
      contenido = const Icon(
        Icons.schedule,
        color: AppColors.textTertiary,
        size: 24,
      );
    } else if (actividad.abreCamara) {
      contenido = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onRevisar,
          borderRadius: BorderRadius.circular(20),
          child: const Center(
            child: Icon(
              Icons.camera_alt_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
        ),
      );
    } else {
      contenido = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onCompletar,
          borderRadius: BorderRadius.circular(20),
          child: const Center(
            child: Icon(
              Icons.radio_button_unchecked,
              color: AppColors.textTertiary,
              size: 26,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 40,
      height: 40,
      child: Center(child: contenido),
    );
  }
}