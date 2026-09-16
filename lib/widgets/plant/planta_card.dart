import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../models/enums.dart';
import '../../models/planta.dart';

/// Tarjeta del Jardín.
///
/// Muestra foto, apodo, especie junto a su estado fitosanitario,
/// y abajo los recordatorios de riego y próxima aplicación de tratamiento.
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
                    child: _foto(),
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
                    // Especie + Badge de estado alineados horizontalmente
                    Row(
                      children: [
                        Expanded(
                          child: Text(
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
                        ),
                        const SizedBox(width: 6),
                        _badgeEstado(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _lineaRiego(isDark),
                    if (planta.estado != EstadoPlanta.sana) ...[
                      const SizedBox(height: 4),
                      _lineaTratamiento(isDark),
                    ],
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(planta.estado.icono, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            planta.estado.etiqueta,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: color,
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

  Widget _lineaTratamiento(bool isDark) {
    final atrasado = planta.tratamientoAtrasado;
    final hoy = planta.tratamientoHoy;

    final color = atrasado
        ? AppColors.error
        : hoy
        ? AppColors.warning
        : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary);

    return Row(
      children: [
        Icon(Icons.healing_outlined, size: 11, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            planta.textoTratamiento,
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
    child:
    Icon(Icons.local_florist, size: 40, color: AppColors.primaryLight),
  );
}