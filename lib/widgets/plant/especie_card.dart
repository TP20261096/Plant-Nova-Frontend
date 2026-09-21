import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../models/especie.dart';

class EspecieCard extends StatelessWidget {
  final Especie especie;
  final VoidCallback onTap;

  const EspecieCard({
    Key? key,
    required this.especie,
    required this.onTap,
  }) : super(key: key);

  Color _colorDificultad(String dif) {
    final lower = dif.toLowerCase();
    if (lower.contains('fácil') || lower.contains('facil')) {
      return AppColors.success;
    } else if (lower.contains('difícil') || lower.contains('dificil')) {
      return AppColors.error;
    }
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorDif = _colorDificultad(especie.dificultad.etiqueta);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCoverImage(isDark),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    especie.nombreComun,
                                    style: AppTextStyles.titleMedium.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    especie.nombreCientifico,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 22,
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.textTertiary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          especie.resumen,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 12,
                            height: 1.3,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _chip(
                              icon: Icons.water_drop,
                              texto: especie.riegoTexto,
                              color: AppColors.primary,
                              isDark: isDark,
                            ),
                            _chip(
                              icon: Icons.bar_chart_rounded,
                              texto: especie.dificultad.etiqueta,
                              color: colorDif,
                              isDark: isDark,
                            ),
                            if (!especie.diagnosticable)
                              _chip(
                                icon: Icons.no_photography_outlined,
                                texto: 'Sin diagnóstico',
                                color: AppColors.textTertiary,
                                isDark: isDark,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage(bool isDark) {
    final Map<String, String> imagenesLocales = {
      'berenjena': 'assets/crops/berenjena.png',
      'citricos': 'assets/crops/citricos.png',
      'lechuga': 'assets/crops/lechuga.png',
      'maiz': 'assets/crops/maiz.png',
      'papa': 'assets/crops/papa.png',
      'pimiento': 'assets/crops/pimiento.png',
      'repollo': 'assets/crops/repollo.png',
      'tomate': 'assets/crops/tomate.png',
    };

    final claveSlug = especie.slug.toLowerCase().trim();
    final claveNombre = especie.nombreComun.toLowerCase().trim();

    final assetPath = imagenesLocales[claveSlug] ?? imagenesLocales[claveNombre];

    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
      child: Container(
        width: 104,
        color: isDark ? AppColors.darkPrimaryBg : AppColors.primaryBg,
        child: assetPath != null
            ? Image.asset(
          assetPath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackIcon(),
        )
            : (especie.imagenUrl != null && especie.imagenUrl!.isNotEmpty)
            ? Image.network(
          especie.imagenUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackIcon(),
        )
            : _fallbackIcon(),
      ),
    );
  }

  Widget _fallbackIcon() {
    return const Center(
      child: Icon(
        Icons.eco_rounded,
        size: 44,
        color: AppColors.primaryLight,
      ),
    );
  }

  Widget _chip({
    required IconData icon,
    required String texto,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}