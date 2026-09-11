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
import '../../widgets/common/primary_button.dart';
import '../plants/registrar_planta_screen.dart';

/// Resultado de POST /diagnose.
///
/// La pantalla anterior mostraba sintomas, causas y prevencion como listas de
/// vinetas, y el tratamiento como una lista de textos. El backend manda las
/// tres primeras como texto corrido y los tratamientos como objetos con
/// ingredientes, pasos, costo y plan de aplicacion. Esta version se organiza
/// sobre esa forma.
///
/// Ademas muestra tres cosas que antes no existian y que son las que evitan
/// que el usuario confie de mas en el modelo: confianza baja, especie no
/// confirmada y el top 3 de predicciones.
class DiagnosticoResultadoScreen extends StatelessWidget {
  const DiagnosticoResultadoScreen({Key? key}) : super(key: key);

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
        title: const Text('Diagnóstico'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          _Imagenes(diagnostico: d),
          const SizedBox(height: 16),
          if (d.requiereAdvertencia) ...[
            _advertencias(d),
            const SizedBox(height: 16),
          ],
          _cabecera(d, isDark),
          if (d.confianzaBaja && d.top3.length > 1) ...[
            const SizedBox(height: 16),
            _top3(d, isDark),
          ],
          const SizedBox(height: 16),
          if (d.descripcion.isNotEmpty)
            _bloqueTexto('Qué es', d.descripcion, Icons.info_outline, isDark),
          if (d.sintomas.isNotEmpty)
            _bloqueTexto('Síntomas', d.sintomas,
                Icons.visibility_outlined, isDark),
          if (d.causas.isNotEmpty)
            _bloqueTexto('Causas', d.causas, Icons.help_outline, isDark),
          if (!d.estaSana && d.tratamientos.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Tratamiento', style: AppTextStyles.titleLarge),
            const SizedBox(height: 10),
            _TratamientoCard(
              tratamiento: d.tratamientoPrincipal!,
              principal: true,
              vinculado: d.estaVinculado,
            ),
            ...d.tratamientosAlternativos.map(
                  (t) => _TratamientoCard(tratamiento: t, principal: false),
            ),
          ],
          if (d.insumosNoCaseros.isNotEmpty) ...[
            const SizedBox(height: 8),
            _insumos(d, isDark),
          ],
          if (d.prevencion.isNotEmpty)
            _bloqueTexto('Prevención', d.prevencion,
                Icons.shield_outlined, isDark),
          _cuidados(d, isDark),
          const SizedBox(height: 24),
          _accion(context, d, provider),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ advertencias

  Widget _advertencias(Diagnostico d) {
    return Column(
      children: [
        if (d.confianzaBaja)
          _aviso(
            Icons.warning_amber_rounded,
            AppColors.warning,
            'El modelo no está seguro',
            'La confianza es de ${d.confianzaTexto}. Vuelve a tomar la foto '
                'con buena luz, enfocando una sola hoja y llenando el encuadre.',
          ),
        if (d.especieNoCoincide)
          _aviso(
            Icons.error_outline,
            AppColors.error,
            'La especie no coincide',
            'La foto parece ser de ${d.cultivo}, distinto a la especie que '
                'registraste para esta planta. Revisa que sea la planta correcta.',
          ),
      ],
    );
  }

  Widget _aviso(IconData icono, Color color, String titulo, String texto) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: AppTextStyles.titleMedium
                        .copyWith(fontSize: 14, color: color)),
                const SizedBox(height: 4),
                Text(texto,
                    style: AppTextStyles.bodySmall.copyWith(height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- cabecera

  Widget _cabecera(Diagnostico d, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _chip(d.estado.etiqueta, d.estado.color),
            const SizedBox(width: 8),
            if (!d.estaSana)
              _chip('Urgencia ${d.urgencia.etiqueta}', d.urgencia.color),
            const Spacer(),
            Text(
              d.confianzaTexto,
              style: AppTextStyles.titleMedium.copyWith(
                color: d.confianzaBaja
                    ? AppColors.warning
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(d.nombreEnfermedad, style: AppTextStyles.headlineMedium),
        if (d.nombreCientifico != null) ...[
          const SizedBox(height: 2),
          Text(
            d.nombreCientifico!,
            style: AppTextStyles.bodyMedium.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text('Cultivo: ${d.cultivo}',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textTertiary)),
      ],
    );
  }

  Widget _top3(Diagnostico d, bool isDark) {
    return _tarjeta(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Otras posibilidades', style: AppTextStyles.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Como la confianza es baja, estas son las opciones que el modelo '
                'consideró.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 10),
          ...d.top3.map((p) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(p.nombreEnfermedad,
                      style: AppTextStyles.bodyMedium),
                ),
                Text(
                  p.confianzaTexto,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- bloques

  Widget _bloqueTexto(
      String titulo, String contenido, IconData icono, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _tarjeta(
        isDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(titulo, style: AppTextStyles.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            // El backend manda texto corrido, no vinetas.
            Text(contenido,
                style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _cuidados(Diagnostico d, bool isDark) {
    if (d.riegoFrecuenciaDias == 0 &&
        d.riegoNota == null &&
        d.otrosCuidados == null) {
      return const SizedBox.shrink();
    }
    return _tarjeta(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop_outlined,
                  size: 18, color: AppColors.info),
              const SizedBox(width: 8),
              Text('Cuidados', style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          if (d.riegoFrecuenciaDias > 0)
            Text(
              'Riego cada ${d.riegoFrecuenciaDias} '
                  '${d.riegoFrecuenciaDias == 1 ? 'día' : 'días'}',
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          if (d.riegoNota != null) ...[
            const SizedBox(height: 4),
            Text(d.riegoNota!,
                style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),
          ],
          if (d.otrosCuidados != null) ...[
            const SizedBox(height: 8),
            Text(d.otrosCuidados!,
                style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),
          ],
        ],
      ),
    );
  }

  Widget _insumos(Diagnostico d, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _tarjeta(
        isDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.store_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Dónde comprar', style: AppTextStyles.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Productos de tienda, por si prefieres no prepararlo en casa.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: 10),
            ...d.insumosNoCaseros.map((i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(i.producto,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                  if (i.presentacion != null)
                    Text(i.presentacion!,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary)),
                  if (i.dondeComprar != null)
                    Text(
                      i.distrito == null
                          ? i.dondeComprar!
                          : '${i.dondeComprar!} · ${i.distrito!}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textTertiary),
                    ),
                  if (i.precioReferencial != null)
                    Text(i.precioReferencial!,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- accion

  Widget _accion(
      BuildContext context,
      Diagnostico d,
      DiagnosticoProvider provider,
      ) {
    if (d.estaVinculado) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: AppColors.success),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    d.estaSana
                        ? 'Guardado en el historial de tu planta.'
                        : 'Las tareas del tratamiento ya están en tu Inicio.',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            text: 'Volver al inicio',
            onPressed: () {
              provider.limpiar();
              Navigator.pushNamedAndRemoveUntil(
                  context, AppRoutes.home, (_) => false);
            },
          ),
        ],
      );
    }

    return PrimaryButton(
      text: 'Guardar en mi jardín',
      icon: Icons.eco,
      isLoading: provider.vinculando,
      onPressed: () => _elegirPlanta(context, provider),
    );
  }

  /// El diagnostico no nace pegado a una planta cuando el usuario entra por
  /// la pestana Captura. Aca elige a cual pertenece, o registra una nueva.
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
            MaterialPageRoute(builder: (_) => const RegistrarPlantaScreen()),
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
      // El backend acaba de programar el tratamiento y cambiar el estado de
      // la planta: las dos listas que lo muestran estan desactualizadas.
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

  // ---------------------------------------------------------------- helpers

  Widget _chip(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        texto,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
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
}

/// Imagen analizada y mapa de calor, alternables.
///
/// El Grad-CAM muestra en que zona de la hoja se fijo el modelo. Es lo que
/// convierte el resultado en algo revisable en lugar de una caja negra.
class _Imagenes extends StatefulWidget {
  final Diagnostico diagnostico;

  const _Imagenes({required this.diagnostico});

  @override
  State<_Imagenes> createState() => _ImagenesState();
}

class _ImagenesState extends State<_Imagenes> {
  bool _mostrarMapa = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.diagnostico;
    final url = _mostrarMapa ? d.gradcamUrl : d.imagenUrl;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 240,
            width: double.infinity,
            color: AppColors.primaryBg,
            child: url == null
                ? const Center(
                child: Icon(Icons.image_not_supported_outlined,
                    size: 48, color: AppColors.primaryLight))
                : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, error, __) {
                // Sin esto el fallo se traga en silencio y parece un
                // problema de la pantalla. La consola dice la causa
                // real: host inalcanzable, enlace caducado o 403.
                debugPrint('No se pudo cargar la imagen: $url');
                debugPrint('Motivo: $error');
                return const Center(
                  child: Icon(Icons.image_not_supported_outlined,
                      size: 48, color: AppColors.primaryLight),
                );
              },
            ),
          ),
        ),
        if (d.gradcamUrl != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => _mostrarMapa = !_mostrarMapa),
            icon: Icon(
              _mostrarMapa ? Icons.photo_outlined : Icons.local_fire_department,
              size: 18,
            ),
            label: Text(
              _mostrarMapa
                  ? 'Ver la foto original'
                  : 'Ver dónde miró el modelo',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }
}

/// Receta con ingredientes, preparacion y plan de aplicacion.
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: widget.principal
            ? Border.all(color: AppColors.primary.withOpacity(0.4))
            : null,
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
                      Text(t.nombre, style: AppTextStyles.titleMedium),
                      if (t.planTexto.isNotEmpty)
                        Text(t.planTexto,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textTertiary)),
                    ],
                  ),
                ),
                Icon(_abierto ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textTertiary),
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
                    style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
          if (_abierto) ...[
            const SizedBox(height: 12),
            Text(t.descripcion,
                style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),
            if (t.ingredientes.isNotEmpty) ...[
              const SizedBox(height: 14),
              _subtitulo('Ingredientes'),
              ...t.ingredientes.map((i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(
                      child: Text('${i.item}: ${i.cantidad}',
                          style: AppTextStyles.bodyMedium),
                    ),
                  ],
                ),
              )),
            ],
            if (t.preparacion.isNotEmpty) ...[
              const SizedBox(height: 14),
              _subtitulo('Preparación'),
              ...t.preparacion.asMap().entries.map((e) => Padding(
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
                      child: Text('${e.key + 1}',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(e.value,
                          style: AppTextStyles.bodyMedium
                              .copyWith(height: 1.4)),
                    ),
                  ],
                ),
              )),
            ],
            const SizedBox(height: 14),
            _subtitulo('Cómo aplicarlo'),
            Text(t.modoUso,
                style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),
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
                    const Icon(Icons.warning_amber_rounded,
                        size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(t.precauciones!,
                          style: AppTextStyles.bodySmall.copyWith(height: 1.4)),
                    ),
                  ],
                ),
              ),
            ],
            if (t.costoAprox != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.payments_outlined,
                      size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Text('Costo aproximado: ${t.costoAprox!}',
                      style: AppTextStyles.bodySmall),
                ],
              ),
            ],
            if (t.nota != null) ...[
              const SizedBox(height: 8),
              Text(t.nota!,
                  style: AppTextStyles.bodySmall.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.textTertiary)),
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

/// Hoja para elegir a que planta pertenece el diagnostico.
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
          Text('¿A qué planta corresponde?',
              style: AppTextStyles.titleLarge),
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
                ...plantas.map((p) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryBg,
                    backgroundImage: p.fotoUrl == null
                        ? null
                        : NetworkImage(p.fotoUrl!),
                    child: p.fotoUrl == null
                        ? const Icon(Icons.local_florist,
                        color: AppColors.primary, size: 18)
                        : null,
                  ),
                  title: Text(p.apodo),
                  subtitle: Text(p.especieVisible),
                  onTap: () => Navigator.pop(context, p.id),
                )),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}