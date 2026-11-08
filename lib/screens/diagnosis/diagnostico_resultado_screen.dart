import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../models/diagnostico.dart';
import '../../models/enums.dart';
import '../../models/planta.dart';
import '../../providers/actividad_provider.dart';
import '../../providers/diagnostico_provider.dart';
import '../../providers/perfil_provider.dart';
import '../../providers/planta_provider.dart';
import '../../widgets/common/animated_tab_bar.dart';
import '../../widgets/common/primary_button.dart';

class _ResultadoModalGuardar {
  final String plantaId;
  final String? apodoExistente;

  _ResultadoModalGuardar({required this.plantaId, this.apodoExistente});
}

class DiagnosticoResultadoScreen extends StatefulWidget {
  const DiagnosticoResultadoScreen({super.key});

  @override
  State<DiagnosticoResultadoScreen> createState() =>
      _DiagnosticoResultadoScreenState();
}

class _DiagnosticoResultadoScreenState
    extends State<DiagnosticoResultadoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _esRevisionActiva = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final tabInicial = args?['tabInicial'] as int? ?? 0;
      final esRevisionArg = args?['esRevision'] as bool? ?? false;

      setState(() {
        _esRevisionActiva = esRevisionArg; // Estrictamente controlado por el flujo de tareas
      });

      if (tabInicial > 0 && tabInicial < _tabController.length) {
        _tabController.animateTo(tabInicial);
      }
    });
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

    // Solo mostramos barra inferior si es una revisión activa o si es un diagnóstico nuevo sin vincular
    final mostrarAccion = _esRevisionActiva || !d.estaVinculado;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Resultado del diagnóstico'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildTopSection(d, isDark),
          const SizedBox(height: 10),
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
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(d, isDark),
                _buildTratamientoTab(d, isDark),
                _buildPrevencionTab(d, isDark),
                _buildCuidadosTab(d, isDark),
              ],
            ),
          ),
          if (mostrarAccion)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.background,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
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

  Widget _buildTopSection(Diagnostico d, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 130,
                  child: _ImagenCompacta(diagnostico: d),
                ),
                const SizedBox(width: 10),
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
          if (d.top3.isNotEmpty) ...[
            const SizedBox(height: 8),
            _top3Compacto(d, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoTab(Diagnostico d, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (d.descripcion.isNotEmpty) ...[
            _bloqueTexto('Qué es', d.descripcion, Icons.info_outline, isDark),
            const SizedBox(height: 10),
          ],
          if (d.sintomas.isNotEmpty) ...[
            _bloqueTexto('Síntomas', d.sintomas, Icons.visibility_outlined, isDark),
            const SizedBox(height: 10),
          ],
          if (d.causas.isNotEmpty)
            _bloqueTexto('Causas', d.causas, Icons.help_outline, isDark),
          if (d.descripcion.isEmpty && d.sintomas.isEmpty && d.causas.isEmpty)
            _bloqueVacio('No hay información registrada', isDark),
        ],
      ),
    );
  }

  Widget _buildTratamientoTab(Diagnostico d, bool isDark) {
    if (d.estaSana || d.tratamientos.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _bloqueVacio('Esta planta no requiere tratamiento', isDark),
      );
    }

    final ideal = d.tratamientoPrincipal!;
    final alternativos = d.tratamientosAlternativos;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (d.esIncurable) ...[
            _bannerIncurable(d),
            const SizedBox(height: 8),
          ],
          _TratamientoCard(
            tratamiento: ideal,
            principal: true,
            vinculado: d.estaVinculado,
          ),
          if (alternativos.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.alt_route, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Otras alternativas registradas',
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...alternativos.map(
                  (t) => _TratamientoCard(tratamiento: t, principal: false),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bannerIncurable(Diagnostico d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade400),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enfermedad sin cura casera',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'No apliques preparados buscando salvar hojas muy dañadas. Se debe retirar el material infectado y desinfectar herramientas.',
                  style: TextStyle(fontSize: 11.5, color: Colors.black87, height: 1.3),
                ),
                if (d.requiereReporteSenasa) ...[
                  const SizedBox(height: 6),
                  Text(
                    '⚠️ Alerta sanitaria: Plaga bajo vigilancia oficial. Comuníquese con SENASA Perú.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrevencionTab(Diagnostico d, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: d.prevencion.isNotEmpty
          ? _bloqueTexto('Prevención', d.prevencion, Icons.shield_outlined, isDark)
          : _bloqueVacio('No hay recomendaciones registradas', isDark),
    );
  }

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

  Widget _cabeceraCard(Diagnostico d, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
        color: color.withValues(alpha: 0.12),
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

  Widget _advertencias(Diagnostico d) {
    return Column(
      children: [
        if (d.confianzaBaja)
          _aviso(
            Icons.warning_amber_rounded,
            AppColors.warning,
            'El modelo no está seguro',
            'Confianza de ${d.confianzaTexto}. Se le sugiere tomar de nuevo '
                'la foto con buena luz y enfocando una sola hoja.',
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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

            final nombreVisible = p.nombreEnfermedad.isNotEmpty
                ? p.nombreEnfermedad
                : p.claseRaw
                .replaceAll('___', ' · ')
                .replaceAll('_', ' ');

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          nombreVisible,
                          style: AppTextStyles.bodyMedium.copyWith(fontSize: 11),
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
                      value: p.confianza > 1.0 ? p.confianza / 100.0 : p.confianza,
                      backgroundColor: color.withValues(alpha: 0.1),
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

  Widget _bloqueTexto(
      String titulo, String contenido, IconData icono, bool isDark) {
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
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, size: 15, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(titulo,
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            contenido,
            style: AppTextStyles.bodyMedium.copyWith(height: 1.5, fontSize: 13),
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
                  color: AppColors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.water_drop_outlined,
                    size: 15, color: AppColors.info),
              ),
              const SizedBox(width: 8),
              Text('Cuidados',
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 14)),
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
              style:
              AppTextStyles.bodyMedium.copyWith(height: 1.5, fontSize: 13),
            ),
          ],
          if (d.otrosCuidados != null) ...[
            const SizedBox(height: 6),
            Linkify(
              onOpen: (link) async {
                final Uri url = Uri.parse(link.url);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              text: d.otrosCuidados!.replaceAll(r'\n', '\n'),
              style: AppTextStyles.bodyMedium.copyWith(
                height: 1.5,
                fontSize: 13,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              linkStyle: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _accion(
      BuildContext context,
      Diagnostico d,
      DiagnosticoProvider provider,
      ) {
    // Por debajo del 60 % no se ofrece guardar (HU017.2): el backend
    // tampoco deja vincular, devuelve 409. En su lugar se ofrece repetir
    // la foto, que es lo unico util que puede hacer el usuario aqui.
    if (d.confianzaBaja) {
      return PrimaryButton(
        text: 'Tomar otra foto',
        icon: Icons.camera_alt_outlined,
        // Volver atras deja al usuario en "Analizar planta": la pantalla de
        // analisis se abrio con pushReplacement, asi que debajo esta Inicio
        // con la pestana de captura activa. No limpiamos el provider porque
        // guarda la planta asociada cuando la captura viene de una revision.
        onPressed: () => Navigator.pop(context),
      );
    }

    // Si no está vinculado en absoluto (diagnóstico nuevo de cámara libre)
    if (!d.estaVinculado) {
      return PrimaryButton(
        text: 'Guardar en mi jardín',
        icon: Icons.eco,
        isLoading: provider.vinculando,
        onPressed: () => _elegirPlanta(context, provider),
      );
    }

    // Si está vinculado pero NO viene de una revisión activa (lo abrieron desde el historial del jardín),
    // no se muestra ningún botón.
    if (!_esRevisionActiva) {
      return const SizedBox.shrink();
    }

    // Si SÍ es una revisión activa recién tomada desde las tareas, mostramos los dos caminos:
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _manejarFlujoSeguimiento(context, d),
        icon: Icon(
          d.estaSana ? Icons.celebration : Icons.refresh,
          size: 18,
        ),
        label: Text(
          d.estaSana ? '¡Planta recuperada!' : 'Continuar con el tratamiento',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: d.estaSana ? AppColors.success : AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _manejarFlujoSeguimiento(BuildContext context, Diagnostico d) async {
    if (d.estaSana) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) {
          final isDarkModal = Theme.of(dialogCtx).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDarkModal ? AppColors.darkSurface : AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono con contenedor circular brillante
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.celebration_rounded,
                      color: AppColors.success,
                      size: 42,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '¡Planta Recuperada!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDarkModal ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '¡Excelente trabajo! Has completado todas las revisiones y tu planta se encuentra sana y fuerte en tu jardín.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 13.5,
                    height: 1.4,
                    color: isDarkModal ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.home,
                            (_) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Volver al inicio',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // También mejoramos el SnackBar cuando continúa con el tratamiento
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.event_note, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¡Ciclo de tratamiento actualizado en tus actividades!',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
            (_) => false,
      );
    }
  }

  Future<void> _elegirPlanta(
      BuildContext context,
      DiagnosticoProvider provider,
      ) async {
    final d = provider.actual;
    if (d == null) return;

    final plantaProvider = context.read<PlantaProvider>();
    if (plantaProvider.plantas.isEmpty) {
      await plantaProvider.cargar(silencioso: true);
    }

    if (!context.mounted) return;

    final _ResultadoModalGuardar? resultado =
    await showModalBottomSheet<_ResultadoModalGuardar>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ModalGuardarPlantaConDiagnostico(
        diagnostico: d,
        plantasExistentes: plantaProvider.plantas,
      ),
    );

    if (resultado == null || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      ),
    );

    final ok = await provider.vincular(resultado.plantaId);
    if (!context.mounted) return;

    Navigator.pop(context);

    if (ok) {
      // Los providers se toman antes de los await: despues de uno el widget
      // puede estar desmontado y el context deja de ser valido.
      final plantaProvider = context.read<PlantaProvider>();
      final actividadProvider = context.read<ActividadProvider>();
      final perfilProvider = context.read<PerfilProvider>();

      await plantaProvider.cargar(silencioso: true);

      // Hay que recargar la semana entera, no solo el dia de hoy: al
      // vincular, el backend programa el plan de tratamiento y esas tareas
      // caen en fechas futuras. Con seleccionarFecha se leeria la semana
      // en cache y no apareceria ninguna.
      await actividadProvider.cargarSemana(silencioso: true);

      try {
        await perfilProvider.cargar(silencioso: true);
      } catch (_) {}

      if (!context.mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) {
          final isDarkModal = Theme.of(dialogCtx).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor:
            isDarkModal ? AppColors.darkSurface : AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '¡Planta y actividades registradas!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDarkModal
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  resultado.apodoExistente != null
                      ? 'Se asoció el diagnóstico a ${resultado.apodoExistente} y sus tareas están al día.'
                      : 'Tu planta se agregó al jardín y sus tratamientos quedaron agendados.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 12,
                    color: isDarkModal
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      provider.limpiar();
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.home,
                            (_) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Entendido',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'No se pudo vincular'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      provider.limpiarError();
    }
  }

  Widget _chip(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
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
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

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
                  errorBuilder: (_, error, __) => const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 30,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (d.gradcamUrl != null) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _mostrarMapa = !_mostrarMapa),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
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
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5)
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.principal) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 12, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                    'Tratamiento recomendado',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          InkWell(
            onTap: () => setState(() => _abierto = !_abierto),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.nombre,
                          style: AppTextStyles.titleMedium
                              .copyWith(fontSize: 14)),
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
                const Icon(Icons.event_available,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Este plan ya está programado en tus actividades.',
                    style: AppTextStyles.bodySmall
                        .copyWith(fontSize: 11, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
          if (_abierto) ...[
            const SizedBox(height: 12),
            Text(t.descripcion,
                style: AppTextStyles.bodyMedium
                    .copyWith(height: 1.5, fontSize: 13)),
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
                          style:
                          AppTextStyles.bodyMedium.copyWith(fontSize: 13),
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
                          style: AppTextStyles.bodyMedium
                              .copyWith(height: 1.4, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            _subtitulo('Cómo aplicarlo'),
            Text(t.modoUso,
                style: AppTextStyles.bodyMedium
                    .copyWith(height: 1.5, fontSize: 13)),
            if (t.precauciones != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Linkify(
                        onOpen: (link) async {
                          final Uri url = Uri.parse(link.url);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        text: t.precauciones!.replaceAll(r'\n', '\n'),
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11,
                          height: 1.4,
                          color: Colors.black87,
                        ),
                        linkStyle: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (t.fuentes.isNotEmpty) ...[
              const SizedBox(height: 14),
              _subtitulo('Fuentes'),
              ...t.fuentes.map(_filaFuente),
            ],
          ],
        ],
      ),
    );
  }

  /// Respaldo documental del remedio (HU026.4). Si la fuente trae enlace se
  /// abre en el navegador; si no, se muestra solo el titulo.
  Widget _filaFuente(FuenteTratamiento fuente) {
    final contenido = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          fuente.tieneEnlace ? Icons.link : Icons.menu_book_outlined,
          size: 13,
          color: fuente.tieneEnlace ? Colors.blue : AppColors.textTertiary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            fuente.titulo,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              height: 1.35,
              color: fuente.tieneEnlace
                  ? Colors.blue
                  : AppColors.textSecondary,
              decoration: fuente.tieneEnlace
                  ? TextDecoration.underline
                  : TextDecoration.none,
              decorationColor: Colors.blue,
            ),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: fuente.tieneEnlace
          ? InkWell(
              onTap: () async {
                final url = Uri.parse(fuente.url!);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              child: contenido,
            )
          : contenido,
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

class _ModalGuardarPlantaConDiagnostico extends StatefulWidget {
  final Diagnostico diagnostico;
  final List<Planta> plantasExistentes;

  const _ModalGuardarPlantaConDiagnostico({
    required this.diagnostico,
    required this.plantasExistentes,
  });

  @override
  State<_ModalGuardarPlantaConDiagnostico> createState() =>
      _ModalGuardarPlantaConDiagnosticoState();
}

class _ModalGuardarPlantaConDiagnosticoState
    extends State<_ModalGuardarPlantaConDiagnostico> {
  late TextEditingController _apodoController;
  Ubicacion _ubicacion = Ubicacion.balcon;

  int _opcionRiego = 0;
  bool _creando = false;
  bool _modoExistente = false;

  @override
  void initState() {
    super.initState();
    _apodoController = TextEditingController(
      text: 'Mi ${widget.diagnostico.cultivo}',
    );
  }

  @override
  void dispose() {
    _apodoController.dispose();
    super.dispose();
  }

  Future<void> _guardarNuevaPlanta() async {
    final apodo = _apodoController.text.trim();
    if (apodo.isEmpty) return;

    setState(() => _creando = true);

    final ahora = DateTime.now();
    DateTime fechaReferencia;
    if (_opcionRiego == 0) {
      fechaReferencia = ahora;
    } else if (_opcionRiego == 1) {
      fechaReferencia = ahora.subtract(const Duration(days: 1));
    } else {
      fechaReferencia = ahora.subtract(const Duration(days: 3));
    }

    try {
      final plantaProvider = context.read<PlantaProvider>();

      final form = PlantaForm(
        apodo: apodo,
        ubicacion: _ubicacion,
        etapa: Etapa.crecimiento,
        speciesId: null,
        fechaSiembra: null,
        ultimoRiego: fechaReferencia,
      );

      final nuevaPlanta = await plantaProvider.crear(form);

      if (nuevaPlanta != null && mounted) {
        Navigator.pop(
          context,
          _ResultadoModalGuardar(plantaId: nuevaPlanta.id),
        );
      } else if (mounted) {
        setState(() => _creando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                plantaProvider.error ?? 'No se pudo registrar la planta'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _creando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar la planta: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = widget.diagnostico;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
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
            SizedBox(
              width: double.infinity,
              child: Text(
                _modoExistente
                    ? 'Vincular a planta de tu jardín'
                    : 'Guardar en mi jardín',
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium.copyWith(fontSize: 18),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: Text(
                _modoExistente
                    ? 'Selecciona a cuál de tus plantas asociar este diagnóstico'
                    : 'Cultivo detectado: ${d.cultivo}. Define su entorno para programar sus cuidados.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!_modoExistente) ...[
              Text(
                'Apodo de la planta',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _apodoController,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Ej: Mi ${d.cultivo}',
                  prefixIcon: const Icon(Icons.edit_outlined, size: 18),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurfaceVariant
                      : const Color(0xFFF5F5F5),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Ubicación de la planta',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<Ubicacion>(
                initialValue: _ubicacion,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.place_outlined, size: 18),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurfaceVariant
                      : const Color(0xFFF5F5F5),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: Ubicacion.values.map((u) {
                  return DropdownMenuItem(
                    value: u,
                    child: Text(
                      u.etiqueta,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _ubicacion = val);
                },
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: Text(
                  '¿Cuándo la regaste por última vez?',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _chipOpcion(label: 'Hoy', index: 0),
                  const SizedBox(width: 8),
                  _chipOpcion(label: 'Ayer', index: 1),
                  const SizedBox(width: 8),
                  _chipOpcion(label: 'Hace días', index: 2),
                ],
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                text: 'Guardar y activar cuidados',
                icon: Icons.check,
                isLoading: _creando,
                onPressed: _guardarNuevaPlanta,
              ),
              if (widget.plantasExistentes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _modoExistente = true),
                    child:
                    const Text('¿Ya la tenías registrada? Vincúlala aquí'),
                  ),
                ),
              ],
            ] else ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.plantasExistentes.length,
                  itemBuilder: (context, index) {
                    final p = widget.plantasExistentes[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.primaryBg,
                        child:
                        Icon(Icons.eco, color: AppColors.primary),
                      ),
                      title: Text(p.apodo),
                      subtitle: Text(p.especieVisible),
                      onTap: () {
                        Navigator.pop(
                          context,
                          _ResultadoModalGuardar(
                            plantaId: p.id,
                            apodoExistente: p.apodo,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _modoExistente = false),
                  child: const Text('← Crear como una planta nueva'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chipOpcion({required String label, required int index}) {
    final seleccionado = _opcionRiego == index;
    return Expanded(
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: seleccionado ? AppColors.primary : AppColors.textSecondary,
            fontWeight: seleccionado ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        selected: seleccionado,
        onSelected: (_) => setState(() => _opcionRiego = index),
        selectedColor: AppColors.primaryLight.withValues(alpha: 0.25),
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: seleccionado
                ? AppColors.primary
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}