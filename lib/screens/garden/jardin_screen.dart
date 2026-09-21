import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../models/enums.dart';
import '../../models/planta.dart';
import '../../providers/actividad_provider.dart';
import '../../providers/perfil_provider.dart';
import '../../providers/planta_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/plant/planta_card.dart';
import 'planta_detalle_screen.dart';

/// Tipos de filtro interactivo para la vista de jardín
enum FiltroJardin { todas, sanas, tratamiento }

/// Pantalla de Mi Jardín con filtrado dinámico y persistencia de estado
class JardinScreen extends StatefulWidget {
  final bool isEmbedded;
  final FiltroJardin filtroInicial;
  final VoidCallback? onIrAAnalizar; // <--- 1. Añadir el callback

  const JardinScreen({
    Key? key,
    this.isEmbedded = false,
    this.filtroInicial = FiltroJardin.todas,
    this.onIrAAnalizar,
  }) : super(key: key);

  @override
  State<JardinScreen> createState() => _JardinScreenState();
}

class _JardinScreenState extends State<JardinScreen>
    with AutomaticKeepAliveClientMixin {
  late FiltroJardin _filtroActivo;

  @override
  bool get wantKeepAlive => true; // Mantiene el estado y scroll vivos

  @override
  void initState() {
    super.initState();
    _filtroActivo = widget.filtroInicial;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlantaProvider>().cargar();
    });
  }

  List<Planta> _filtrarPlantas(List<Planta> lista) {
    switch (_filtroActivo) {
      case FiltroJardin.sanas:
        return lista.where((p) => p.estado == EstadoPlanta.sana).toList();
      case FiltroJardin.tratamiento:
        return lista.where((p) => p.estado != EstadoPlanta.sana).toList();
      case FiltroJardin.todas:
      default:
        return lista;
    }
  }

  Future<void> _abrirRegistro() async {
    // Si está embebido en el menú inferior, cambia a la pestaña de análisis (índice 2)
    if (widget.onIrAAnalizar != null) {
      widget.onIrAAnalizar!();
    } else {
      // Fallback por si se abrió de forma independiente
      Navigator.pushNamed(context, AppRoutes.uploadPlant);
    }
  }

  void _abrirDetalle(Planta planta) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlantaDetalleScreen(plantaId: planta.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Requerido por AutomaticKeepAliveClientMixin

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<PlantaProvider>();
    final plantasFiltradas = _filtrarPlantas(provider.plantas);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
        title: const Text('Mi jardín'),
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
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isEmbedded)
              _encabezado(isDark, provider)
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    _subtitulo(provider),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            if (_filtroActivo != FiltroJardin.todas)
              _barraFiltroActivo(isDark, plantasFiltradas.isNotEmpty),
            Expanded(
              child: _cuerpo(context, provider, plantasFiltradas, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _encabezado(bool isDark, PlantaProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Mi jardín',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMedium.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _subtitulo(provider),
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _barraFiltroActivo(bool isDark, bool hayPlantas) {
    final textoFiltro = _filtroActivo == FiltroJardin.sanas
        ? 'Plantas sanas'
        : 'Plantas en tratamiento';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _filtroActivo == FiltroJardin.sanas
                  ? AppColors.success.withOpacity(0.15)
                  : AppColors.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _filtroActivo == FiltroJardin.sanas
                      ? Icons.eco
                      : Icons.healing,
                  size: 14,
                  color: _filtroActivo == FiltroJardin.sanas
                      ? AppColors.success
                      : AppColors.warning,
                ),
                const SizedBox(width: 6),
                Text(
                  textoFiltro,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _filtroActivo == FiltroJardin.sanas
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          if (hayPlantas)
            TextButton(
              onPressed: () => setState(() => _filtroActivo = FiltroJardin.todas),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Mostrar todas', style: TextStyle(fontSize: 12)),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  String _subtitulo(PlantaProvider provider) {
    if (provider.cargando && provider.plantas.isEmpty) {
      return 'Cargando plantas...';
    }

    if (_filtroActivo == FiltroJardin.sanas) {
      final sanas = provider.sanas;
      return sanas == 1 ? '1 planta sana' : '$sanas plantas sanas';
    }

    if (_filtroActivo == FiltroJardin.tratamiento) {
      final enTrat = provider.enTratamiento;
      return enTrat == 1
          ? '1 planta en tratamiento'
          : '$enTrat plantas en tratamiento';
    }

    if (provider.plantas.isEmpty) {
      return 'Tus plantas y sus cuidados';
    }
    if (provider.conRiegoAtrasado > 0) {
      final n = provider.conRiegoAtrasado;
      return n == 1
          ? '1 planta con riego atrasado'
          : '$n plantas con riego atrasado';
    }
    if (provider.enTratamiento > 0) {
      final n = provider.enTratamiento;
      return n == 1 ? '1 planta en tratamiento' : '$n plantas en tratamiento';
    }
    final total = provider.totalPlantas;
    return total == 1 ? '1 planta al día' : '$total plantas al día';
  }

  Widget _cuerpo(
      BuildContext context,
      PlantaProvider provider,
      List<Planta> plantasAMostrar,
      bool isDark,
      ) {
    if (provider.cargando && provider.plantas.isEmpty) {
      return const LoadingView(message: 'Cargando tu jardín...');
    }

    if (provider.error != null && provider.plantas.isEmpty) {
      return ErrorView(
        message: provider.error!,
        onRetry: () => provider.cargar(),
      );
    }

    if (plantasAMostrar.isEmpty) {
      return EmptyState(
        icon: Icons.local_florist,
        title: _filtroActivo == FiltroJardin.sanas
            ? 'No hay plantas sanas'
            : _filtroActivo == FiltroJardin.tratamiento
            ? 'No hay plantas en tratamiento'
            : 'Tu jardín está vacío',
        message: _filtroActivo == FiltroJardin.todas
            ? 'Registra tu primera planta para empezar a cuidarla.'
            : 'No se encontraron plantas bajo este filtro.',
        buttonText: _filtroActivo == FiltroJardin.todas
            ? 'Registrar planta'
            : 'Ver todas',
        onButtonPressed: _filtroActivo == FiltroJardin.todas
            ? _abrirRegistro
            : () => setState(() => _filtroActivo = FiltroJardin.todas),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.cargar(silencioso: true),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: plantasAMostrar.length,
        itemBuilder: (context, index) {
          final planta = plantasAMostrar[index];
          return PlantaCard(
            key: ValueKey('planta_${planta.id}'),
            planta: planta,
            onTap: () => _abrirDetalle(planta),
            onLongPress: () => _confirmarEliminar(context, planta, isDark),
          );
        },
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, Planta planta, bool isDark) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Eliminar planta',
          textAlign: TextAlign.center,
          style: AppTextStyles.titleLarge.copyWith(
            fontSize: 17,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Se borrarán también sus diagnósticos y tareas. '
              '¿Quieres borrar ${planta.apodo}?',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 14,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        actionsPadding: const EdgeInsets.all(8),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    final plantaProv = context.read<PlantaProvider>();
                    final actividadProv = context.read<ActividadProvider>();
                    final perfilProv = context.read<PerfilProvider>();
                    final messenger = ScaffoldMessenger.of(context);

                    final ok = await plantaProv.eliminar(planta.id);
                    if (!mounted) return;

                    if (ok) {
                      // Sincroniza silenciosamente Inicio y Perfil
                      await Future.wait([
                        actividadProv.cargar(silencioso: true),
                        perfilProv.cargar(silencioso: true),
                      ]);
                    } else {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(plantaProv.error ?? 'No se pudo eliminar'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Eliminar', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}