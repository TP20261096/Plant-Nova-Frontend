import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../models/planta.dart';
import '../../app/routes.dart';
import '../../providers/diagnostico_provider.dart';
import '../../providers/planta_provider.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';

/// GET /plants/{id}
///
/// Reemplaza a GardenPlantDetailScreen. Recibe solo el id y pide el detalle
/// al backend en vez de que le pasen un objeto: asi los datos estan frescos
/// al volver de completar un riego o de un diagnostico nuevo.
class PlantaDetalleScreen extends StatefulWidget {
  final String plantaId;

  const PlantaDetalleScreen({Key? key, required this.plantaId})
      : super(key: key);

  @override
  State<PlantaDetalleScreen> createState() => _PlantaDetalleScreenState();
}

class _PlantaDetalleScreenState extends State<PlantaDetalleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlantaProvider>().cargarDetalle(widget.plantaId);
    });
  }

  @override
  void dispose() {
    // Sin notifyListeners: el widget ya se esta desmontando.
    context.read<PlantaProvider>().limpiarDetalle();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<PlantaProvider>();
    final planta = provider.detalle;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(planta?.apodo ?? 'Planta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _cuerpo(provider, planta, isDark),
    );
  }

  Widget _cuerpo(
      PlantaProvider provider,
      PlantaDetalle? planta,
      bool isDark,
      ) {
    if (provider.cargandoDetalle) {
      return const LoadingView(message: 'Cargando planta...');
    }

    if (provider.errorDetalle != null) {
      return ErrorView(
        message: provider.errorDetalle!,
        onRetry: () => provider.cargarDetalle(widget.plantaId),
      );
    }

    if (planta == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: () => provider.cargarDetalle(widget.plantaId),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          _foto(planta),
          const SizedBox(height: 16),
          _cabecera(planta, isDark),
          const SizedBox(height: 20),
          _tarjetaRiego(planta, isDark),
          const SizedBox(height: 16),
          _datos(planta, isDark),
          if (planta.riegoNota != null || planta.otrosCuidados != null) ...[
            const SizedBox(height: 16),
            _cuidados(planta, isDark),
          ],
          const SizedBox(height: 20),
          _historial(planta, isDark),
        ],
      ),
    );
  }

  Widget _foto(PlantaDetalle planta) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Hero(
        tag: 'planta_foto_${planta.id}',
        child: Container(
          height: 200,
          width: double.infinity,
          color: AppColors.primaryBg,
          child: planta.fotoUrl == null
              ? const Center(
            child: Icon(Icons.local_florist,
                size: 56, color: AppColors.primaryLight),
          )
              : Image.network(
            planta.fotoUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.local_florist,
                  size: 56, color: AppColors.primaryLight),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cabecera(PlantaDetalle planta, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(planta.apodo, style: AppTextStyles.headlineMedium),
        const SizedBox(height: 4),
        Text(
          planta.especieVisible,
          style: AppTextStyles.bodyMedium.copyWith(
            fontStyle: FontStyle.italic,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: planta.estado.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(planta.estado.icono, size: 14, color: planta.estado.color),
              const SizedBox(width: 6),
              Text(
                planta.estado.etiqueta,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: planta.estado.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tarjetaRiego(PlantaDetalle planta, bool isDark) {
    final atrasado = planta.riegoAtrasado;
    final color = atrasado ? AppColors.error : AppColors.info;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.water_drop, color: color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planta.textoRiego,
                  style: AppTextStyles.titleMedium.copyWith(color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  planta.riegoFrecuenciaDias == 0
                      ? 'Sin frecuencia calculada'
                      : 'Cada ${planta.riegoFrecuenciaDias} '
                      '${planta.riegoFrecuenciaDias == 1 ? 'día' : 'días'}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _datos(PlantaDetalle planta, bool isDark) {
    return _tarjeta(
      isDark,
      child: Column(
        children: [
          _fila(Icons.place_outlined, 'Ubicación',
              planta.ubicacion.etiqueta),
          _fila(Icons.timeline_outlined, 'Etapa', planta.etapa.etiqueta),
          _fila(
            Icons.event_outlined,
            'Sembrada',
            planta.fechaSiembra == null
                ? 'Sin especificar'
                : _fecha(planta.fechaSiembra!),
          ),
          _fila(
            Icons.water_drop_outlined,
            'Último riego',
            planta.ultimoRiego == null
                ? 'Sin registrar'
                : _fecha(planta.ultimoRiego!),
          ),
        ],
      ),
    );
  }

  Widget _cuidados(PlantaDetalle planta, bool isDark) {
    return _tarjeta(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cuidados', style: AppTextStyles.titleMedium),
          if (planta.riegoNota != null) ...[
            const SizedBox(height: 10),
            Text(planta.riegoNota!, style: AppTextStyles.bodyMedium),
          ],
          if (planta.otrosCuidados != null) ...[
            const SizedBox(height: 10),
            Text(planta.otrosCuidados!, style: AppTextStyles.bodyMedium),
          ],
        ],
      ),
    );
  }

  Widget _historial(PlantaDetalle planta, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Diagnósticos', style: AppTextStyles.titleLarge),
        const SizedBox(height: 10),
        if (!planta.tieneDiagnosticos)
          _tarjeta(
            isDark,
            child: Row(
              children: [
                const Icon(Icons.camera_alt_outlined,
                    color: AppColors.textTertiary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Todavía no le has hecho ningún diagnóstico.',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          )
        else
          ...planta.diagnosticos.map((d) => InkWell(
            onTap: () => _abrirDiagnostico(d.id),
            borderRadius: BorderRadius.circular(14),
            child: _filaDiagnostico(d, isDark),
          )),
      ],
    );
  }

  Widget _filaDiagnostico(DiagnosticoResumen d, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 48,
              height: 48,
              color: AppColors.primaryBg,
              child: d.imagenUrl == null
                  ? const Icon(Icons.image_not_supported_outlined,
                  size: 20, color: AppColors.primaryLight)
                  : Image.network(
                d.imagenUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.image_not_supported_outlined,
                    size: 20,
                    color: AppColors.primaryLight),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.nombreEnfermedad,
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_fecha(d.createdAt)} · confianza ${d.confianzaTexto}',
                  style: AppTextStyles.bodySmall
                      .copyWith(fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: d.estado.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              d.estado.etiqueta,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: d.estado.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Abre un diagnostico del historial.
  ///
  /// Hay que volver a pedirlo con GET /diagnoses/{id} en vez de reusar lo que
  /// trae el detalle de la planta: el resumen no incluye sintomas ni
  /// tratamientos, y los enlaces de imagen caducan en una hora.
  Future<void> _abrirDiagnostico(String id) async {
    final provider = context.read<DiagnosticoProvider>();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final ok = await provider.cargar(id);

    if (!mounted) return;
    Navigator.pop(context); // cierra el indicador

    if (!ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'No se pudo abrir el diagnóstico'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      provider.limpiarError();
      return;
    }

    Navigator.pushNamed(context, AppRoutes.diagnosticoResultado);
  }

  Widget _tarjeta(bool isDark, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _fila(IconData icono, String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icono, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 12),
          Text(etiqueta,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _fecha(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')}/'
          '${f.month.toString().padLeft(2, '0')}/${f.year}';
}