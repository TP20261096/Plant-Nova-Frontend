import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../models/actividad.dart';
import '../../models/enums.dart';
import '../../providers/actividad_provider.dart';
import '../../providers/consejo_provider.dart';
import '../../providers/diagnostico_provider.dart';
import '../../providers/perfil_provider.dart';
import '../../providers/planta_provider.dart';
import '../../providers/weather_provider.dart';
import '../../widgets/home/actividad_card.dart';
import '../../widgets/home/dialogo_tarea_completada.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/navigation/custom_bottom_navigation.dart';
import '../actividades/actividades_dia_screen.dart';
import '../diagnosis/upload_plant_screen.dart';
import '../garden/jardin_screen.dart';
import '../garden/planta_detalle_screen.dart';
import '../guide/guia_screen.dart';
import '../profile/perfil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
      context.read<ActividadProvider>().cargarSemana();
      context.read<WeatherProvider>().loadWeather();
      context.read<ConsejoProvider>().cargar();
    });
  }

  // Valida si la actividad corresponde al día que el usuario tiene seleccionado en el carrusel
  /// Si la tarea se puede marcar desde el dia que se esta viendo.
  ///
  /// Una tarea atrasada se puede completar siempre: el backend la repite en
  /// cada dia desde su fecha hasta hoy justo para eso. Antes se comparaba
  /// solo contra el dia seleccionado, de modo que una tarea del miercoles
  /// aparecia hoy pero no se dejaba marcar, y el selector no llega tan
  /// atras como para ir a buscarla.
  bool _sePuedeMarcar(Actividad actividad) {
    return actividad.atrasada ||
        _esActividadDelDiaSeleccionado(actividad.fechaProgramada);
  }

  bool _esActividadDelDiaSeleccionado(DateTime fechaProgramada) {
    return fechaProgramada.year == _selectedDate.year &&
        fechaProgramada.month == _selectedDate.month &&
        fechaProgramada.day == _selectedDate.day;
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
    // La siguiente tarea la calcula el backend y llega en la respuesta de
    // PATCH /activities/{id}; el provider la guarda al completar.
    mostrarDialogoTareaCompletada(
      context,
      completada: actividad,
      proxima: context.read<ActividadProvider>().proximaTarea,
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

          // Las pestanas se mantienen vivas, asi que Perfil no vuelve a
          // ejecutar su initState. Sin esto, los contadores de plantas,
          // diagnosticos y tareas se quedarian con el valor de la primera
          // vez que se abrio la pestana (HU004.2).
          // Entrar a Captura empieza siempre sin planta asociada: la foto
          // que se tome ahi es de una planta nueva, no de la ultima revision.
          if (index == 2) {
            context.read<DiagnosticoProvider>().limpiarPlanta();
          }

          if (index == 4) {
            context.read<PerfilProvider>().cargar(silencioso: true);
          }
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
          // Los providers se leen antes de los await: despues de uno, el
          // widget puede estar desmontado y el context ya no es valido.
          final actividades = context.read<ActividadProvider>();
          final clima = context.read<WeatherProvider>();
          final plantas = context.read<PlantaProvider>();
          await Future.wait([
            actividades.cargarSemana(silencioso: true),
            clima.loadWeather(),
            plantas.cargar(silencioso: true),
          ]);
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
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
              final esDelDiaSeleccionado = _sePuedeMarcar(actividad);

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
    final esDelDiaSeleccionado = _sePuedeMarcar(actividad);

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
                    color: Colors.grey.withValues(alpha: 0.3),
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
                      color: actividad.tipo.color.withValues(alpha: 0.12),
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
                            color: AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
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
                            // Sin fecha: el backend programa la siguiente
                            // aplicacion al completar esta, contando desde la
                            // fecha real de cumplimiento. Antes se deducia el
                            // intervalo buscando "bordel" en el titulo.
                            final esUltimaDosis = numActual >= total || actividad.tipo == TipoActividad.revision;

                            final colorBase = esUltimaDosis ? AppColors.primaryLight : AppColors.warning;

                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: colorBase.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colorBase.withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: colorBase.withValues(alpha: 0.15),
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
                                              ? 'Se programa al completar esta dosis'
                                              : 'Se programa al completar esta dosis',
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
                                color: AppColors.primaryLight.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primaryLight.withValues(alpha: 0.3),
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
                      disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
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
                      disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
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
                color: AppColors.primaryLight.withValues(alpha: 0.3),
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
        ? Colors.white.withValues(alpha: 0.9)
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
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
      return _weatherShell(
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
      return _weatherShell(
        child: Row(
          children: [
            const Icon(Icons.cloud_off, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => weatherProvider.loadWeather(),
                child: Text(
                  '${weatherProvider.error ?? 'No se pudo cargar el clima.'} '
                  'Toca aquí para reintentar.',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _weatherShell(
      sombra: true,
      child: Row(
        children: [
          // El backend no manda el estado del cielo ni un codigo de icono,
          // asi que mostramos la temperatura en lugar de inventar un simbolo.
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${weather.temperatura.round()}°',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Lima Metropolitana',
                  style: TextStyle(
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
                  weather.actualizadoTexto.isEmpty
                      ? '${weather.ciudad} · ${weather.temperaturaTexto}'
                      : '${weather.ciudad} · ${weather.actualizadoTexto}',
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
              _weatherDato(Icons.water_drop, weather.humedadTexto),
              const SizedBox(height: 4),
              _weatherDato(Icons.air, weather.vientoTexto),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weatherShell({required Widget child, bool sombra = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade500, Colors.blue.shade300],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: sombra
            ? [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }

  Widget _weatherDato(IconData icono, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, color: Colors.white.withValues(alpha: 0.95), size: 14),
        const SizedBox(width: 4),
        Text(
          texto,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
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
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: color.withValues(alpha: 0.25),
          highlightColor: color.withValues(alpha: 0.12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
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
    final provider = context.watch<ConsejoProvider>();
    final consejos = provider.consejos;

    // Si no hay consejos que mostrar, la seccion desaparece en vez de
    // ocupar espacio con una tarjeta vacia.
    if (consejos.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
                  icon: consejo.icono,
                  titulo: consejo.titulo,
                  texto: consejo.contenido,
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
          color: AppColors.primaryLight.withValues(alpha: 0.3),
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
          const Icon(
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