import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../models/especie.dart';

/// Fila de la lista de la Guia.
///
/// Estructura:
/// - Imagen a la izquierda (centrada verticalmente, 64x64)
/// - Todo el contenido a la derecha: nombre + especie + badges + descripcion
/// - Flechita de navegación al final
class EspecieCard extends StatelessWidget {
  final Especie especie;
  final VoidCallback onTap;

  const EspecieCard({
    Key? key,
    required this.especie,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Imagen a la izquierda (centrada verticalmente)
                _imagen(isDark),
                const SizedBox(width: 12),

                // Todo el contenido a la derecha
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre + especie
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  especie.nombreComun,
                                  style: AppTextStyles.titleMedium.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  especie.nombreCientifico,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 6),

                          // Badges arriba a la derecha
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _chip(
                                    Icons.water_drop_outlined,
                                    especie.riegoTexto,
                                    isDark,
                                  ),
                                  const SizedBox(width: 4),
                                  _chip(
                                    Icons.bar_chart,
                                    especie.dificultad.etiqueta,
                                    isDark,
                                  ),
                                ],
                              ),
                              if (!especie.diagnosticable) ...[
                                const SizedBox(height: 4),
                                _chip(
                                  Icons.no_photography_outlined,
                                  'Sin diagnóstico',
                                  isDark,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Descripción (2 líneas máx)
                      Text(
                        especie.resumen,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11,
                          height: 1.3,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Flechita de navegación
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right,
                  size: 22,
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagen(bool isDark) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkPrimaryBg : AppColors.primaryBg,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: especie.imagenUrl == null
          ? const Icon(Icons.eco, size: 30, color: AppColors.primary)
          : Image.network(
        especie.imagenUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
        const Icon(Icons.eco, size: 30, color: AppColors.primary),
      ),
    );
  }

  Widget _chip(IconData icono, String texto, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkPrimaryBg : AppColors.primaryBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 9, color: AppColors.primaryLight),
          const SizedBox(width: 2),
          Text(
            texto,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.primaryLight : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}