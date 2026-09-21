import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../models/actividad.dart';
import '../../models/enums.dart';
import '../../providers/actividad_provider.dart';
import '../../providers/diagnostico_provider.dart';
import '../../providers/planta_provider.dart';
import '../../widgets/home/actividad_card.dart';
import '../garden/planta_detalle_screen.dart';

/// Pantalla con TODAS las actividades de un día.
/// Se abre desde el botón "Ver todas" del inicio.
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActividadProvider>().seleccionarFecha(widget.fecha);
    });
  }

  String _formatearFechaProxima(DateTime fecha) {
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    const dias = [
      'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'
    ];
    final diaSemana = dias[fecha.weekday - 1];
    final mes = meses[fecha.month - 1];
    return '$diaSemana ${fecha.day} de $mes';
  }

  void _mostrarDialogoExitoActividad(BuildContext context, Actividad actividad) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final esRiego = actividad.tipo == TipoActividad.riego ||
        actividad.titulo.toLowerCase().contains('riego');

    // Buscar la frecuencia de riego de la planta específica si está disponible en el provider
    int diasRiego = 3; // Valor por defecto genérico
    try {
      final plantaProvider = context.read<PlantaProvider>();
      final plantaEncontrada = plantaProvider.plantas.firstWhere(
            (p) => p.id == actividad.plantId,
        orElse: () => plantaProvider.plantas.first,
      );
      if (plantaEncontrada.riegoFrecuenciaDias != null) {
        diasRiego = plantaEncontrada.riegoFrecuenciaDias!;
      }
    } catch (_) {}

    final fechaProximaRiego = DateTime.now().add(Duration(days: diasRiego));
    final fechaRiegoTexto = _formatearFechaProxima(fechaProximaRiego);

    final numActual = actividad.aplicacionNum ?? 1;
    final totalAplicaciones = actividad.totalAplicaciones ?? 1;
    final esUnica = totalAplicaciones <= 1;

    final esBordeles = actividad.titulo.toLowerCase().contains('bordel');
    final diasIntervalo = esBordeles ? 10 : 7;
    final fechaProximaTratamiento = DateTime.now().add(Duration(days: diasIntervalo));
    final fechaTratamientoTexto = _formatearFechaProxima(fechaProximaTratamiento);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
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
              esRiego
                  ? '¡Riego registrado!'
                  : (esUnica ? '¡Actividad completada!' : '¡Tratamiento aplicado!'),
              style: AppTextStyles.titleMedium.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (esRiego) ...[
              Text(
                'Has registrado el riego de ${actividad.planta}.',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(
                    'Próximo riego: $fechaRiegoTexto',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ] else if (esUnica) ...[
              Text(
                'Has completado exitosamente la actividad de ${actividad.planta}.',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ] else if (numActual < totalAplicaciones) ...[
              Text(
                'Has completado la dosis $numActual de $totalAplicaciones de ${actividad.planta}.',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.event, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Próxima dosis: $fechaTratamientoTexto',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                '¡Completaste el ciclo de $totalAplicaciones aplicaciones!',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_outlined, size: 16, color: AppColors.primaryLight),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Revisión fitosanitaria: $fechaTratamientoTexto',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<ActividadProvider>();
    final actividades = provider.actividades;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
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
      List<Actividad> actividades,
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
              const Icon(
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
              const Icon(
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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
      itemCount: actividades.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
            child: Row(
              children: [
                const Icon(
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
        final estaProcesando = provider.estaCompletando(actividad.id);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ActividadCard(
            actividad: actividad,
            completando: estaProcesando,
            onTap: () => _mostrarModalDetalleActividad(context, actividad),
            onCompletar: () async {
              HapticFeedback.lightImpact();
              final ok = await provider.completar(actividad);
              if (!mounted) return;
              if (ok) {
                context.read<PlantaProvider>().cargar(silencioso: true);

                final esValida = actividad.tipo == TipoActividad.tratamiento ||
                    actividad.tipo == TipoActividad.revision ||
                    actividad.tipo == TipoActividad.riego ||
                    actividad.aplicacionNum != null ||
                    actividad.titulo.toLowerCase().contains('solución') ||
                    actividad.titulo.toLowerCase().contains('extracto') ||
                    actividad.titulo.toLowerCase().contains('aplicar') ||
                    actividad.titulo.toLowerCase().contains('riego');

                if (esValida) {
                  _mostrarDialogoExitoActividad(context, actividad);
                }
              } else if (provider.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(provider.error!),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            onRevisar: () {
              Navigator.pushNamed(
                context,
                AppRoutes.uploadPlant,
                arguments: {'plantId': actividad.plantId},
              );
            },
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MODAL DETALLE DE ACTIVIDAD (Preparación y pasos)
  // ═══════════════════════════════════════════════════════════
  void _mostrarModalDetalleActividad(BuildContext context, Actividad actividad) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final esTratamiento = actividad.tipo == TipoActividad.tratamiento ||
        actividad.tipo == TipoActividad.revision ||
        actividad.aplicacionNum != null ||
        actividad.titulo.toLowerCase().contains('solución') ||
        actividad.titulo.toLowerCase().contains('extracto') ||
        actividad.titulo.toLowerCase().contains('aplicar');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: actividad.tipo.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      actividad.tipo.icono,
                      color: actividad.tipo.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          actividad.titulo,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          actividad.planta,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (actividad.progresoTexto != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            actividad.progresoTexto!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. INDICACIONES RÁPIDAS
                      if (actividad.descripcion != null &&
                          actividad.descripcion!.isNotEmpty) ...[
                        Text(
                          'INDICACIONES RÁPIDAS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            actividad.descripcion!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              height: 1.5,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],

                      // 2. RECORDATORIO DE PRÓXIMO TRATAMIENTO (SOLO SI TIENE MÚLTIPLES APLICACIONES)
                      if (esTratamiento && actividad.totalAplicaciones != null && actividad.totalAplicaciones! > 1) ...[
                        const SizedBox(height: 12),
                        Builder(
                          builder: (context) {
                            final numActual = actividad.aplicacionNum ?? 1;
                            final total = actividad.totalAplicaciones ?? 3;
                            final esBordeles = actividad.titulo.toLowerCase().contains('bordel');
                            final diasIntervalo = esBordeles ? 10 : 7;
                            final proximaFecha = DateTime.now().add(Duration(days: diasIntervalo));
                            final fechaFormateada = _formatearFechaProxima(proximaFecha);
                            final esUltimaDosis = numActual >= total || actividad.tipo == TipoActividad.revision;

                            final colorBase = esUltimaDosis ? AppColors.primaryLight : AppColors.warning;

                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: colorBase.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colorBase.withOpacity(0.25)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: colorBase.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      esUltimaDosis ? Icons.camera_alt_outlined : Icons.calendar_today_outlined,
                                      size: 16,
                                      color: colorBase,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          esUltimaDosis
                                              ? 'REVISIÓN TRAS COMPLETAR'
                                              : 'PRÓXIMO TRATAMIENTO',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                            color: colorBase,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          esUltimaDosis
                                              ? 'Foto diagnóstica el $fechaFormateada'
                                              : 'Siguiente dosis el $fechaFormateada',
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],

                      // 3. ACCESO A LA GUÍA PASO A PASO
                      if (esTratamiento) ...[
                        const SizedBox(height: 12),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              Navigator.pop(bottomContext);

                              final idPlanta = actividad.plantId;
                              if (idPlanta.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No se encontró el id de la planta'),
                                    backgroundColor: AppColors.warning,
                                  ),
                                );
                                return;
                              }

                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              );

                              final plantaProvider = context.read<PlantaProvider>();
                              final diagProvider = context.read<DiagnosticoProvider>();

                              await plantaProvider.cargarDetalle(idPlanta);
                              final detalle = plantaProvider.detalle;

                              if (!mounted) return;

                              if (detalle != null && detalle.diagnosticos.isNotEmpty) {
                                final diagId = detalle.diagnosticos.first.id;
                                final ok = await diagProvider.cargar(diagId);

                                if (!mounted) return;
                                Navigator.pop(context);

                                if (ok) {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.diagnosticoResultado,
                                    arguments: {'tabInicial': 1},
                                  );
                                }
                              } else {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PlantaDetalleScreen(
                                      plantaId: idPlanta,
                                      enfocarCuidados: true,
                                    ),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primaryLight.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.healing_outlined,
                                    color: AppColors.primaryLight,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Ver tratamiento de ${actividad.planta}',
                                          style: AppTextStyles.titleMedium.copyWith(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryLight,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Preparación, dosis e ingredientes paso a paso',
                                          style: AppTextStyles.bodySmall.copyWith(
                                            fontSize: 11,
                                            color: isDark
                                                ? AppColors.darkTextSecondary
                                                : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: AppColors.primaryLight,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              if (!actividad.completada && !actividad.proyectada)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(bottomContext);
                      HapticFeedback.lightImpact();

                      final provider = context.read<ActividadProvider>();
                      final ok = await provider.completar(actividad);

                      if (!mounted || !ok) return;

                      context.read<PlantaProvider>().cargar(silencioso: true);

                      final esValida = actividad.tipo == TipoActividad.tratamiento ||
                          actividad.tipo == TipoActividad.revision ||
                          actividad.tipo == TipoActividad.riego ||
                          actividad.aplicacionNum != null ||
                          actividad.titulo.toLowerCase().contains('solución') ||
                          actividad.titulo.toLowerCase().contains('extracto') ||
                          actividad.titulo.toLowerCase().contains('aplicar') ||
                          actividad.titulo.toLowerCase().contains('riego');

                      if (esValida) {
                        _mostrarDialogoExitoActividad(context, actividad);
                      }
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Marcar como completada'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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