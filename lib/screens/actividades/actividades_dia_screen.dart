import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../providers/actividad_provider.dart';
import '../../providers/planta_provider.dart';
import '../../widgets/home/actividad_card.dart';

/// Pantalla con TODAS las actividades de un dia.
/// Se abre desde el boton "Ver todas" del inicio.
class ActividadesDiaScreen extends StatefulWidget {
  final DateTime fecha;

  const ActividadesDiaScreen({
    Key? key,
    required this.fecha,
  }) : super(key: key);

  @override
  State<ActividadesDiaScreen> createState() => _ActividadesDiaScreenState();
}

class _ActividadesDiaScreenState extends State<ActividadesDiaScreen> {
  @override
  void initState() {
    super.initState();
    // Al abrir esta pantalla, aseguramos que el provider tenga
    // seleccionada la fecha que nos pasaron.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActividadProvider>().seleccionarFecha(widget.fecha);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<ActividadProvider>();
    final actividades = provider.actividades;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _titulo(widget.fecha),
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.cargar(silencioso: true),
          child: _buildBody(provider, actividades, isDark),
        ),
      ),
    );
  }

  Widget _buildBody(
      ActividadProvider provider,
      List actividades,
      bool isDark,
      ) {
    // Cargando
    if (provider.cargando && actividades.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            AppColors.primaryLight,
          ),
        ),
      );
    }

    // Error
    if (provider.error != null && actividades.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => provider.cargar(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    // Vacío
    if (actividades.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_available,
                size: 56,
                color: AppColors.primaryLight,
              ),
              const SizedBox(height: 16),
              Text(
                'No hay actividades para este día',
                style: AppTextStyles.titleMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Descansa o adelanta otras tareas',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Lista completa
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 32),
      itemCount: actividades.length + 1,
      itemBuilder: (context, index) {
        // Header con contador
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Row(
              children: [
                Icon(
                  Icons.checklist,
                  color: AppColors.primaryLight,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${actividades.length} '
                      '${actividades.length == 1 ? "actividad" : "actividades"}',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        final actividad = actividades[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ActividadCard(actividad: actividad),
        );
      },
    );
  }

  String _titulo(DateTime fecha) {
    final now = DateTime.now();

    final isToday = fecha.day == now.day &&
        fecha.month == now.month &&
        fecha.year == now.year;
    if (isToday) return 'Actividades de hoy';

    final ayer = now.subtract(const Duration(days: 1));
    final isYesterday = fecha.day == ayer.day &&
        fecha.month == ayer.month &&
        fecha.year == ayer.year;
    if (isYesterday) return 'Actividades de ayer';

    final manana = now.add(const Duration(days: 1));
    final isTomorrow = fecha.day == manana.day &&
        fecha.month == manana.month &&
        fecha.year == manana.year;
    if (isTomorrow) return 'Actividades de mañana';

    const dias = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    final nombre = dias[fecha.weekday - 1];
    return 'Actividades del $nombre ${fecha.day}';
  }
}