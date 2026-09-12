import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/routes.dart';
import '../../models/diagnostico.dart';
import '../../models/planta.dart';
import '../../providers/actividad_provider.dart';
import '../../providers/diagnostico_provider.dart';
import '../../providers/planta_provider.dart';
import '../../widgets/common/animated_tab_bar.dart';
import '../../widgets/common/primary_button.dart';
import '../plants/registrar_planta_screen.dart';

/// Resultado de POST /diagnose.
///
/// Tabs:
/// - Info: qué es + síntomas + causas
/// - Tratamiento: recetas con ingredientes y preparación
/// - Prevención
/// - Cuidados: riego y otros cuidados
class DiagnosticoResultadoScreen extends StatefulWidget {
  const DiagnosticoResultadoScreen({Key? key}) : super(key: key);

  @override
  State<DiagnosticoResultadoScreen> createState() =>
      _DiagnosticoResultadoScreenState();
}

class _DiagnosticoResultadoScreenState
    extends State<DiagnosticoResultadoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<DiagnosticoProvider>();
    final d = provider.actual;

    if (d == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text('No hay diagnóstico que mostrar.')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Resultado del diagnóstico'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Sección superior compacta
          _buildTopSection(d, isDark),

          const SizedBox(height: 10),

          // Tabs
          AnimatedTabBar(
            controller: _tabController,
            indicatorColor: AppColors.primaryLight,
            labelColor: Colors.white,
            unselectedLabelColor: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
            tabs: const [
              AnimatedTab(icon: Icons.info_outline, label: 'Info'),
              AnimatedTab(icon: Icons.healing, label: 'Tratamiento'),
              AnimatedTab(icon: Icons.shield, label: 'Prevención'),
              AnimatedTab(icon: Icons.favorite, label: 'Cuidados'),
            ],
          ),

          const SizedBox(height: 10),

          // Contenido del tab
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildInfoTab(d, isDark),
                _buildTratamientoTab(d, isDark),
                _buildPrevencionTab(d, isDark),
                _buildCuidadosTab(d, isDark),
              ],
            ),
          ),

          // Acción fija abajo
          Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.background,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: _accion(context, d, provider),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SECCIÓN SUPERIOR COMPACTA
  // ═══════════════════════════════════════════════════════════
  Widget _buildTopSection(Diagnostico d, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila: imagen + (card + aviso) con misma altura
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Imagen que se estira a la altura del card
                SizedBox(
                  width: 130,
                  child: _ImagenCompacta(diagnostico: d),
                ),
                const SizedBox(width: 10),

                // Columna derecha: card + aviso (pegados)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _cabeceraCard(d, isDark),
                      if (d.requiereAdvertencia) ...[
                        const SizedBox(height: 8),
                        _advertencias(d),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Top 3 al final
          if (d.confianzaBaja && d.top3.length > 1) ...[
            const SizedBox(height: 8),
            _top3Compacto(d, isDark),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 1: INFO (qué es + síntomas + causas)
  // ═══════════════════════════════════════════════════════════
  Widget _buildInfoTab(Diagnostico d, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (d.descripcion.isNotEmpty) ...[
            _bloqueTexto(
              'Qué es',
              d.descripcion,
              Icons.info_outline,
              isDark,
            ),
            const SizedBox(height: 10),
          ],
          if (d.sintomas.isNotEmpty) ...[
            _bloqueTexto(
              'Síntomas',
              d.sintomas,
              Icons.visibility_outlined,
              isDark,
            ),
            const SizedBox(height: 10),
          ],
          if (d.causas.isNotEmpty)
            _bloqueTexto(
              'Causas',
              d.causas,
              Icons.help_outline,
              isDark,
            ),
          if (d.descripcion.isEmpty &&
              d.sintomas.isEmpty &&
              d.causas.isEmpty)
            _bloqueVacio('No hay información registrada', isDark),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 2: TRATAMIENTO
  // ═══════════════════════════════════════════════════════════
  Widget _buildTratamientoTab(Diagnostico d, bool isDark) {
    if (d.estaSana || d.tratamientos.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _bloqueVacio(
          'Esta planta no requiere tratamiento',
          isDark,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TratamientoCard(
            tratamiento: d.tratamientoPrincipal!,
            principal: true,
            vinculado: d.estaVinculado,
          ),
          if (d.tratamientosAlternativos.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.alt_route,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Alternativas',
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...d.tratamientosAlternativos.map(
                  (t) => _TratamientoCard(
                tratamiento: t,
                principal: false,
              ),
            ),
          ],
          if (d.insumosNoCaseros.isNotEmpty) ...[
            const SizedBox(height: 8),
            _insumos(d, isDark),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 3: PREVENCIÓN
  // ═══════════════════════════════════════════════════════════
  Widget _buildPrevencionTab(Diagnostico d, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: d.prevencion.isNotEmpty
          ? _bloqueTexto(
        'Prevención',
        d.prevencion,
        Icons.shield_outlined,
        isDark,
      )
          : _bloqueVacio('No hay recomendaciones registradas', isDark),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 4: CUIDADOS
  // ═══════════════════════════════════════════════════════════
  Widget _buildCuidadosTab(Diagnostico d, bool isDark) {
    final tieneCuidados = d.riegoFrecuenciaDias > 0 ||
        d.riegoNota != null ||
        d.otrosCuidados != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: tieneCuidados
          ? _cuidados(d, isDark)
          : _bloqueVacio('No hay cuidados registrados', isDark),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CABECERA COMPACTA
  // ═══════════════════════════════════════════════════════════
  Widget _cabeceraCard(Diagnostico d, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cultivo
          Row(
            children: [
              const Icon(Icons.eco, size: 12, color: AppColors.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  d.cultivo,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Nombre enfermedad
          Text(
            d.nombreEnfermedad,
            style: AppTextStyles.headlineMedium.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Científico
          if (d.nombreCientifico != null) ...[
            const SizedBox(height: 2),
            Text(
              d.nombreCientifico!,
              style: AppTextStyles.bodySmall.copyWith(
                fontStyle: FontStyle.italic,
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Chips pegados al nombre
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _chip(d.estado.etiqueta, d.estado.color),
              if (!d.estaSana)
                _chip('Urgencia ${d.urgencia.etiqueta}', d.urgencia.color),
              _chipConfianza(d),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipConfianza(Diagnostico d) {
    final color = d.confianzaBaja ? AppColors.warning : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            d.confianzaBaja ? Icons.info_outline : Icons.check_circle,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            d.confianzaTexto,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ADVERTENCIAS (al lado derecho, bajo el card)
  // ═══════════════════════════════════════════════════════════
  Widget _advertencias(Diagnostico d) {
    return Column(
      children: [
        if (d.confianzaBaja)
          _aviso(
            Icons.warning_amber_rounded,
            AppColors.warning,
            'El modelo no está seguro',
            'Confianza de ${d.confianzaTexto}. Toma la foto con buena luz.',
          ),
        if (d.especieNoCoincide)
          _aviso(
            Icons.error_outline,
            AppColors.error,
            'La especie no coincide',
            'La foto parece ser de ${d.cultivo}, no de la planta registrada.',
          ),
      ],
    );
  }

  Widget _aviso(
      IconData icono,
      Color color,
      String titulo,
      String texto,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 11,
                    color: color,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  texto,
                  style: AppTextStyles.bodySmall.copyWith(
                    height: 1.3,
                    fontSize: 10,
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

  // ═══════════════════════════════════════════════════════════
  // TOP 3 (ancho completo)
  // ═══════════════════════════════════════════════════════════
  Widget _top3Compacto(Diagnostico d, bool isDark) {
    return _tarjeta(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_outlined,
                size: 13,
                color: AppColors.primary,
              ),
              const SizedBox(width: 5),
              Text(
                'Otras posibilidades',
                style: AppTextStyles.titleMedium.copyWith(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...d.top3.asMap().entries.map((entry) {
            final p = entry.value;
            final color = entry.key == 0
                ? AppColors.primary
                : entry.key == 1
                ? AppColors.info
                : AppColors.textTertiary;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.nombreEnfermedad,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        p.confianzaTexto,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: p.confianza,
                      backgroundColor: color.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BLOQUES
  // ═══════════════════════════════════════════════════════════
  Widget _bloqueTexto(
      String titulo,
      String contenido,
      IconData icono,
      bool isDark,
      ) {
    return _tarjeta(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, size: 15, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            contenido,
            style: AppTextStyles.bodyMedium.copyWith(
              height: 1.5,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bloqueVacio(String mensaje, bool isDark) {
    return _tarjeta(
      isDark,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            mensaje,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _cuidados(Diagnostico d, bool isDark) {
    return _tarjeta(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.water_drop_outlined,
                  size: 15,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Cuidados',
                style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (d.riegoFrecuenciaDias > 0)
            Text(
              'Riego cada ${d.riegoFrecuenciaDias} '
                  '${d.riegoFrecuenciaDias == 1 ? 'día' : 'días'}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          if (d.riegoNota != null) ...[
            const SizedBox(height: 4),
            Text(
              d.riegoNota!,
              style: AppTextStyles.bodyMedium.copyWith(
                height: 1.5,
                fontSize: 13,
              ),
            ),
          ],
          if (d.otrosCuidados != null) ...[
            const SizedBox(height: 6),
            Text(
              d.otrosCuidados!,
              style: AppTextStyles.bodyMedium.copyWith(
                height: 1.5,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _insumos(Diagnostico d, bool isDark) {
    return _tarjeta(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.store_outlined,
                  size: 15,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Dónde comprar',
                style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...d.insumosNoCaseros.map(
                (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    i.producto,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (i.presentacion != null)
                    Text(
                      i.presentacion!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  if (i.dondeComprar != null)
                    Text(
                      i.distrito == null
                          ? i.dondeComprar!
                          : '${i.dondeComprar!} · ${i.distrito!}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  if (i.precioReferencial != null)
                    Text(
                      i.precioReferencial!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ACCIÓN
  // ═══════════════════════════════════════════════════════════
  Widget _accion(
      BuildContext context,
      Diagnostico d,
      DiagnosticoProvider provider,
      ) {
    if (d.estaVinculado) {
      return PrimaryButton(
        text: 'Volver al inicio',
        onPressed: () {
          provider.limpiar();
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
                (_) => false,
          );
        },
      );
    }

    return PrimaryButton(
      text: 'Guardar en mi jardín',
      icon: Icons.eco,
      isLoading: provider.vinculando,
      onPressed: () => _elegirPlanta(context, provider),
    );
  }

  Future<void> _elegirPlanta(
      BuildContext context,
      DiagnosticoProvider provider,
      ) async {
    final plantaProvider = context.read<PlantaProvider>();
    if (plantaProvider.plantas.isEmpty) {
      await plantaProvider.cargar(silencioso: true);
    }

    if (!context.mounted) return;

    final elegida = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _SelectorPlanta(
        plantas: plantaProvider.plantas,
        onRegistrarNueva: () async {
          final creada = await Navigator.push<PlantaDetalle>(
            sheetContext,
            MaterialPageRoute(
              builder: (_) => const RegistrarPlantaScreen(),
            ),
          );
          if (creada != null && sheetContext.mounted) {
            Navigator.pop(sheetContext, creada.id);
          }
        },
      ),
    );

    if (elegida == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final ok = await provider.vincular(elegida);
    if (!context.mounted) return;

    if (ok) {
      context.read<PlantaProvider>().cargar(silencioso: true);
      context.read<ActividadProvider>().cargar(silencioso: true);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'No se pudo vincular'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      provider.limpiarError();
    }
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════
  Widget _chip(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _tarjeta(bool isDark, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// IMAGEN COMPACTA (llena la altura con Expanded)
// ═══════════════════════════════════════════════════════════════
class _ImagenCompacta extends StatefulWidget {
  final Diagnostico diagnostico;

  const _ImagenCompacta({required this.diagnostico});

  @override
  State<_ImagenCompacta> createState() => _ImagenCompactaState();
}

class _ImagenCompactaState extends State<_ImagenCompacta> {
  bool _mostrarMapa = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.diagnostico;
    final url = _mostrarMapa ? d.gradcamUrl : d.imagenUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Imagen que se estira a la altura disponible
        Expanded(
          child: GestureDetector(
            onTap: d.gradcamUrl != null
                ? () => setState(() => _mostrarMapa = !_mostrarMapa)
                : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                color: AppColors.primaryBg,
                child: url == null
                    ? const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 30,
                    color: AppColors.primaryLight,
                  ),
                )
                    : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, __) {
                    debugPrint('No se pudo cargar: $url');
                    return const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 30,
                        color: AppColors.primaryLight,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        // Botón Ver mapa justo debajo
        if (d.gradcamUrl != null) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _mostrarMapa = !_mostrarMapa),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _mostrarMapa
                        ? Icons.photo_outlined
                        : Icons.local_fire_department,
                    size: 11,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      _mostrarMapa ? 'Foto original' : 'Ver mapa',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TRATAMIENTO CARD
// ═══════════════════════════════════════════════════════════════
class _TratamientoCard extends StatefulWidget {
  final Tratamiento tratamiento;
  final bool principal;
  final bool vinculado;

  const _TratamientoCard({
    required this.tratamiento,
    required this.principal,
    this.vinculado = false,
  });

  @override
  State<_TratamientoCard> createState() => _TratamientoCardState();
}

class _TratamientoCardState extends State<_TratamientoCard> {
  late bool _abierto = widget.principal;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = widget.tratamiento;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: widget.principal
            ? Border.all(
          color: AppColors.primary.withOpacity(0.4),
          width: 1.5,
        )
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _abierto = !_abierto),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.nombre,
                        style: AppTextStyles.titleMedium
                            .copyWith(fontSize: 14),
                      ),
                      if (t.planTexto.isNotEmpty)
                        Text(
                          t.planTexto,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  _abierto ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
          if (widget.principal && widget.vinculado) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.event_available,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Este plan ya está programado en tus actividades.',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_abierto) ...[
            const SizedBox(height: 12),
            Text(
              t.descripcion,
              style: AppTextStyles.bodyMedium.copyWith(
                height: 1.5,
                fontSize: 13,
              ),
            ),
            if (t.ingredientes.isNotEmpty) ...[
              const SizedBox(height: 14),
              _subtitulo('Ingredientes'),
              ...t.ingredientes.map(
                    (i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(
                        child: Text(
                          '${i.item}: ${i.cantidad}',
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (t.preparacion.isNotEmpty) ...[
              const SizedBox(height: 14),
              _subtitulo('Preparación'),
              ...t.preparacion.asMap().entries.map(
                    (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${e.key + 1}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e.value,
                          style: AppTextStyles.bodyMedium.copyWith(
                            height: 1.4,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            _subtitulo('Cómo aplicarlo'),
            Text(
              t.modoUso,
              style: AppTextStyles.bodyMedium.copyWith(
                height: 1.5,
                fontSize: 13,
              ),
            ),
            if (t.precauciones != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.precauciones!,
                        style: AppTextStyles.bodySmall.copyWith(
                          height: 1.4,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (t.costoAprox != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.payments_outlined,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Costo aproximado: ${t.costoAprox!}',
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ],
            if (t.nota != null) ...[
              const SizedBox(height: 8),
              Text(
                t.nota!,
                style: AppTextStyles.bodySmall.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _subtitulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        texto.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SELECTOR DE PLANTA
// ═══════════════════════════════════════════════════════════════
class _SelectorPlanta extends StatelessWidget {
  final List<Planta> plantas;
  final VoidCallback onRegistrarNueva;

  const _SelectorPlanta({
    required this.plantas,
    required this.onRegistrarNueva,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Text(
            '¿A qué planta corresponde?',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryBg,
                    child: Icon(Icons.add, color: AppColors.primary),
                  ),
                  title: const Text('Registrar una planta nueva'),
                  onTap: onRegistrarNueva,
                ),
                if (plantas.isNotEmpty) const Divider(height: 1),
                ...plantas.map(
                      (p) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryBg,
                      backgroundImage: p.fotoUrl == null
                          ? null
                          : NetworkImage(p.fotoUrl!),
                      child: p.fotoUrl == null
                          ? const Icon(
                        Icons.local_florist,
                        color: AppColors.primary,
                        size: 18,
                      )
                          : null,
                    ),
                    title: Text(p.apodo),
                    subtitle: Text(p.especieVisible),
                    onTap: () => Navigator.pop(context, p.id),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}