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
import '../../providers/weather_provider.dart';
import '../../widgets/home/actividad_card.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/navigation/custom_bottom_navigation.dart';
import '../actividades/actividades_dia_screen.dart';
import '../diagnosis/upload_plant_screen.dart';
import '../garden/jardin_screen.dart';
import '../garden/planta_detalle_screen.dart';
import '../guide/guia_screen.dart';
import '../profile/perfil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  DateTime _selectedDate = DateTime.now();

  static const int _maxActividadesInicio = 3;

  // Claves para persistir de forma independiente el scroll y estado de cada pestaña
  final List<PageStorageKey<String>> _tabKeys = const [
    PageStorageKey('tab_home'),
    PageStorageKey('tab_guia'),
    PageStorageKey('tab_diagnostico'),
    PageStorageKey('tab_jardin'),
    PageStorageKey('tab_perfil'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlantaProvider>().cargar();
      context.read<ActividadProvider>().cargar();
      context.read<WeatherProvider>().loadWeather();
    });
  }

  // Valida si la actividad corresponde al día que el usuario tiene seleccionado en el carrusel
  bool _esActividadDelDiaSeleccionado(DateTime fechaProgramada) {
    return fechaProgramada.year == _selectedDate.year &&
        fechaProgramada.month == _selectedDate.month &&
        fechaProgramada.day == _selectedDate.day;
  }

  bool _esActividadPasada(DateTime fechaProgramada) {
    final ahora = DateTime.now();
    final hoySinHora = DateTime(ahora.year, ahora.month, ahora.day);
    final fechaSinHora = DateTime(fechaProgramada.year, fechaProgramada.month, fechaProgramada.day);
    return fechaSinHora.isBefore(hoySinHora);
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

    int diasRiego = 3;
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
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          KeyedSubtree(
            key: _tabKeys[0],
            child: _buildHomeContent(context),
          ),
          KeyedSubtree(
            key: _tabKeys[1],
            child: const GuiaScreen(isEmbedded: true),
          ),
          KeyedSubtree(
            key: _tabKeys[2],
            child: const UploadPlantScreen(isEmbedded: true),
          ),
          KeyedSubtree(
            key: _tabKeys[3],
            child: JardinScreen(
              isEmbedded: true,
              onIrAAnalizar: () {
                setState(() {
                  _currentIndex = 2; // <--- Cambia directamente a la sección de analizar (UploadPlantScreen)
                });
              },
            ),
          ),
          KeyedSubtree(
            key: _tabKeys[4],
            child: const PerfilScreen(isEmbedded: true),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          HapticFeedback.selectionClick();
          setState(() => _currentIndex = index);
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HOME CONTENT
  // ═══════════════════════════════════════════════════════════
  Widget _buildHomeContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await context.read<ActividadProvider>().cargar(silencioso: true);
          await context.read<WeatherProvider>().loadWeather();
          await context.read<PlantaProvider>().cargar(silencioso: true);
        },
        color: AppColors.primaryLight,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. CLIMA
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: _buildWeatherCard(context),
              ),

              // 2. SALUDO
              const HomeHeader(),

              // 3. BOX DE ACTIVIDADES
              Container(
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Text(
                        _tituloActividades(_selectedDate),
                        style: AppTextStyles.titleMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDaysSelector(),
                    const SizedBox(height: 8),
                    _buildActivitiesSection(context),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // 4. ESTADO DE CULTIVOS (COMPACTO Y EQUILIBRADO)
              _buildPlantStatusSummary(context),

              const SizedBox(height: 4),

              // 5. CONSEJOS
              _buildQuickTip(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SECCIÓN ACTIVIDADES
  // ═══════════════════════════════════════════════════════════
  Widget _buildActivitiesSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<ActividadProvider>();
    final todas = provider.actividades;

    final visibles = todas.take(_maxActividadesInicio).toList();
    final hayMas = todas.length > _maxActividadesInicio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (provider.cargando && todas.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryLight,
                  ),
                  strokeWidth: 2,
                ),
              ),
            ),
          )
        else if (todas.isEmpty)
          _buildEmptyActivities(isDark)
        else ...[
            ...visibles.map((actividad) {
              final estaProcesando = provider.estaCompletando(actividad.id);
              final esDelDiaSeleccionado = _esActividadDelDiaSeleccionado(actividad.fechaProgramada);

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF3A3A3A)
                          : const Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Opacity(
                      opacity: esDelDiaSeleccionado ? 1.0 : 0.6,
                      child: ActividadCard(
                        actividad: actividad,
                        completando: estaProcesando,
                        onTap: () =>
                            _mostrarModalDetalleActividad(context, actividad),
                        onCompletar: () async {
                          if (!esDelDiaSeleccionado) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Esta actividad pertenece a otra fecha.'),
                                backgroundColor: AppColors.warning,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          final esRevision = actividad.tipo == TipoActividad.revision ||
                              actividad.titulo.toLowerCase().contains('revisar') ||
                              actividad.titulo.toLowerCase().contains('captura');

                          if (esRevision) {
                            HapticFeedback.lightImpact();
                            Navigator.pushNamed(
                              context,
                              AppRoutes.uploadPlant,
                              arguments: {'plantId': actividad.plantId, 'esRevision': true},
                            );
                            return;
                          }

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
                          if (!esDelDiaSeleccionado) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Esta actividad pertenece a otra fecha.'),
                                backgroundColor: AppColors.warning,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          Navigator.pushNamed(
                            context,
                            AppRoutes.uploadPlant,
                            arguments: {'plantId': actividad.plantId, 'esRevision': true},
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            }),
            if (hayMas) ...[
              const SizedBox(height: 6),
              _buildVerTodasButton(context, todas.length),
            ],
          ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MODAL DETALLE DE ACTIVIDAD
  // ═══════════════════════════════════════════════════════════
  void _mostrarModalDetalleActividad(BuildContext context, Actividad actividad) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final esDelDiaSeleccionado = _esActividadDelDiaSeleccionado(actividad.fechaProgramada);

    final esTratamiento = actividad.tipo == TipoActividad.tratamiento ||
        actividad.tipo == TipoActividad.revision ||
        actividad.aplicacionNum != null ||
        actividad.titulo.toLowerCase().contains('solución') ||
        actividad.titulo.toLowerCase().contains('extracto') ||
        actividad.titulo.toLowerCase().contains('aplicar');

    final esRevision = actividad.tipo == TipoActividad.revision ||
        actividad.titulo.toLowerCase().contains('revisar') ||
        actividad.titulo.toLowerCase().contains('captura');

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
                      // Advertencia si no corresponde al día seleccionado
                      if (!esDelDiaSeleccionado) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock_clock, color: AppColors.warning, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Esta actividad está programada para el ${_formatearFechaProxima(actividad.fechaProgramada)}.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

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
                                    content: Text(
                                      'No se pudo encontrar el identificador de la planta',
                                    ),
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
                              final diagnosticoProvider = context.read<DiagnosticoProvider>();

                              await plantaProvider.cargarDetalle(idPlanta);
                              final detalle = plantaProvider.detalle;

                              if (!mounted) return;

                              if (detalle != null && detalle.diagnosticos.isNotEmpty) {
                                final idDiag = detalle.diagnosticos.first.id;
                                final ok = await diagnosticoProvider.cargar(idDiag);

                                if (!mounted) return;
                                Navigator.pop(context);

                                if (ok) {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.diagnosticoResultado,
                                    arguments: {'tabInicial': 1},
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        diagnosticoProvider.error ?? 'No se pudo abrir el tratamiento',
                                      ),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                  diagnosticoProvider.limpiarError();
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
                                          'Preparación, dosis e ingredientes orgánicos paso a paso',
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
                  child: esRevision
                      ? ElevatedButton.icon(
                    onPressed: esDelDiaSeleccionado
                        ? () {
                      Navigator.pop(bottomContext);
                      HapticFeedback.lightImpact();
                      Navigator.pushNamed(
                        context,
                        AppRoutes.uploadPlant,
                        arguments: {
                          'plantId': actividad.plantId,
                          'esRevision': true,
                        },
                      );
                    }
                        : null,
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: Text(
                      esDelDiaSeleccionado ? 'Tomar foto de revisión' : 'Disponible el ${_formatearFechaProxima(actividad.fechaProgramada)}',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                      disabledForegroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                      : ElevatedButton.icon(
                    onPressed: esDelDiaSeleccionado
                        ? () async {
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
                    }
                        : null,
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(
                      esDelDiaSeleccionado ? 'Marcar como completada' : 'Disponible el ${_formatearFechaProxima(actividad.fechaProgramada)}',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                      disabledForegroundColor: Colors.grey,
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

  // ═══════════════════════════════════════════════════════════
  // BOTÓN "VER TODAS"
  // ═══════════════════════════════════════════════════════════
  Widget _buildVerTodasButton(BuildContext context, int total) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 40,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ActividadesDiaScreen(fecha: _selectedDate),
              ),
            );
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkPrimaryBg : AppColors.primaryBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primaryLight.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Ver todas',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '($total)',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.primaryLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SELECTOR DE DÍAS
  // ═══════════════════════════════════════════════════════════
  Widget _buildDaysSelector() {
    final now = DateTime.now();
    final dias = List.generate(7, (i) => now.add(Duration(days: i - 2)));

    return SizedBox(
      height: 58,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: dias.length,
        itemBuilder: (context, index) {
          final date = dias[index];
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedDate = date);
              context.read<ActividadProvider>().seleccionarFecha(date);
            },
            child: SizedBox(
              width: 52,
              child: _buildDayCard(date),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayCard(DateTime date) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    final isToday = date.day == now.day &&
        date.month == now.month &&
        date.year == now.year;

    final isSelected = date.day == _selectedDate.day &&
        date.month == _selectedDate.month &&
        date.year == _selectedDate.year;

    final bgColor = isToday
        ? AppColors.primary
        : (isDark ? AppColors.darkSurface : AppColors.surface);

    final dayNameColor = isToday
        ? Colors.white.withOpacity(0.9)
        : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary);

    final dayNumberColor = isToday
        ? Colors.white
        : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: isSelected && !isToday
            ? Border.all(color: AppColors.primaryLight, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _getDayName(date),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: dayNameColor,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: dayNumberColor,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CLIMA
  // ═══════════════════════════════════════════════════════════
  Widget _buildWeatherCard(BuildContext context) {
    final weatherProvider = context.watch<WeatherProvider>();
    final weather = weatherProvider.weather;

    if (weatherProvider.isLoading && weather == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade500, Colors.blue.shade300],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2.2,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Actualizando clima...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (weather == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade500, Colors.blue.shade300],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => weatherProvider.loadWeather(),
                child: const Text(
                  'No se pudo cargar el clima. Toca aquí para reintentar.',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade500, Colors.blue.shade300],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getWeatherIcon(weather.icon),
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  weather.cityName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${weather.description} · ${weather.temperature.toStringAsFixed(1)}°C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.water_drop,
                    color: Colors.white.withOpacity(0.95),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${weather.humidity}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.air,
                    color: Colors.white.withOpacity(0.95),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(weather.windSpeed * 3.6).toStringAsFixed(0)} km/h',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String iconCode) {
    switch (iconCode) {
      case '01d':
        return Icons.wb_sunny;
      case '01n':
        return Icons.nightlight;
      case '02d':
      case '02n':
        return Icons.wb_cloudy;
      case '03d':
      case '03n':
      case '04d':
      case '04n':
        return Icons.cloud;
      case '09d':
      case '09n':
      case '10d':
      case '10n':
        return Icons.water_drop;
      case '11d':
      case '11n':
        return Icons.thunderstorm;
      case '13d':
      case '13n':
        return Icons.ac_unit;
      case '50d':
      case '50n':
        return Icons.foggy;
      default:
        return Icons.wb_sunny;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ESTADO DE CULTIVOS (COMPACTO Y EQUILIBRADO)
  // ═══════════════════════════════════════════════════════════
  Widget _buildPlantStatusSummary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plantaProvider = context.watch<PlantaProvider>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Estado de tus cultivos',
              style: AppTextStyles.titleMedium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Row(
            children: [
              _buildStatusItem(
                icon: Icons.eco,
                color: AppColors.success,
                label: 'Sanas',
                value: plantaProvider.sanas,
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const JardinScreen(
                        filtroInicial: FiltroJardin.sanas,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildStatusItem(
                icon: Icons.healing,
                color: AppColors.warning,
                label: 'En tratamiento',
                value: plantaProvider.enTratamiento,
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const JardinScreen(
                        filtroInicial: FiltroJardin.tratamiento,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required Color color,
    required String label,
    required int value,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: color.withOpacity(0.25),
          highlightColor: color.withOpacity(0.12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CONSEJOS
  // ═══════════════════════════════════════════════════════════
  Widget _buildQuickTip() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final consejos = [
      {
        'icon': Icons.water_drop,
        'titulo': 'Riego matutino',
        'texto':
        'Riega tus plantas temprano en la mañana para evitar la evaporación.',
      },
      {
        'icon': Icons.wb_sunny,
        'titulo': 'Luz adecuada',
        'texto':
        'La mayoría de cultivos necesitan 6-8 horas de luz solar directa al día.',
      },
      {
        'icon': Icons.eco,
        'titulo': 'Abono orgánico',
        'texto':
        'Usa compost o humus de lombriz cada 15 días para fortalecer tus plantas.',
      },
      {
        'icon': Icons.content_cut,
        'titulo': 'Poda regular',
        'texto':
        'Elimina hojas secas o enfermas para mejorar la circulación de aire.',
      },
      {
        'icon': Icons.bug_report,
        'titulo': 'Monitoreo',
        'texto':
        'Revisa el envés de las hojas cada 2-3 días para detectar plagas a tiempo.',
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Consejos para tus plantas',
              style: AppTextStyles.titleMedium.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            height: 72,
            child: PageView.builder(
              controller: PageController(viewportFraction: 1.0),
              itemCount: consejos.length,
              itemBuilder: (context, index) {
                final consejo = consejos[index];
                return _buildTipCard(
                  isDark,
                  icon: consejo['icon'] as IconData,
                  titulo: consejo['titulo'] as String,
                  texto: consejo['texto'] as String,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(
      bool isDark, {
        required IconData icon,
        required String titulo,
        required String texto,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkPrimaryBg : AppColors.primaryBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primaryLight.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.warning,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  titulo,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 12,
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  texto,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    height: 1.2,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyActivities(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available,
            size: 32,
            color: AppColors.primaryLight,
          ),
          const SizedBox(height: 8),
          Text(
            'No hay actividades para este día',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            'Registra una planta para tener actividades',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _tituloActividades(DateTime date) {
    final now = DateTime.now();

    final isToday = date.day == now.day &&
        date.month == now.month &&
        date.year == now.year;
    if (isToday) return 'Actividades de hoy';

    final ayer = now.subtract(const Duration(days: 1));
    final isYesterday = date.day == ayer.day &&
        date.month == ayer.month &&
        date.year == ayer.year;
    if (isYesterday) return 'Actividades de ayer';

    final manana = now.add(const Duration(days: 1));
    final isTomorrow = date.day == manana.day &&
        date.month == manana.month &&
        date.year == manana.year;
    if (isTomorrow) return 'Actividades de mañana';

    final nombreDia = _getDayNameCompleto(date);
    return 'Actividades del $nombreDia ${date.day}';
  }

  String _getDayName(DateTime date) {
    const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return dias[date.weekday - 1];
  }

  String _getDayNameCompleto(DateTime date) {
    const dias = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    return dias[date.weekday - 1];
  }
}