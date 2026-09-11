import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../models/planta.dart';

/// Tarjeta del Jardin. Reemplaza a GardenPlantCard.
///
/// Mantiene el diseno de la anterior y agrega el estado del riego, que es el
/// dato que el usuario necesita ver de un vistazo: si una planta esta
/// atrasada, esta tarjeta tiene que gritarlo.
class PlantaCard extends StatelessWidget {
  final Planta planta;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const PlantaCard({
    Key? key,
    required this.planta,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                    color:
                    isDark ? AppColors.darkPrimaryBg : AppColors.primaryBg,
                  ),
                  child: ClipRRect(
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Hero(
                      tag: 'planta_foto_${planta.id}',
                      child: _foto(),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      planta.apodo,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      planta.especieVisible,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    _badgeEstado(),
                    const SizedBox(height: 6),
                    _lineaRiego(isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badgeEstado() {
    final color = planta.estado.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(planta.estado.icono, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              planta.estado.etiqueta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineaRiego(bool isDark) {
    final atrasado = planta.riegoAtrasado;
    final hoy = planta.riegoHoy;

    final color = atrasado
        ? AppColors.error
        : hoy
        ? AppColors.info
        : (isDark ? AppColors.darkTextTertiary : AppColors.textTertiary);

    return Row(
      children: [
        Icon(Icons.water_drop_outlined, size: 11, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            planta.textoRiego,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight:
              atrasado || hoy ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _foto() {
    final url = planta.fotoUrl;

    // Ya no hay rutas de archivo local: el backend devuelve URLs.
    if (url == null || url.isEmpty) return _placeholder();

    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progreso) {
        if (progreso == null) return child;
        return Center(
          child: CircularProgressIndicator(
            valueColor:
            const AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
            value: progreso.expectedTotalBytes != null
                ? progreso.cumulativeBytesLoaded / progreso.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() => const Center(
    child: Icon(Icons.local_florist, size: 40, color: AppColors.primaryLight),
  );
}