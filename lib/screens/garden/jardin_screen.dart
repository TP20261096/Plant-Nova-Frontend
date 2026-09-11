import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../models/planta.dart';
import '../../providers/planta_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/plant/planta_card.dart';
import '../plants/registrar_planta_screen.dart';
import 'planta_detalle_screen.dart';

/// Menu Jardin. Reemplaza a DiagnosisHistoryScreen, que a pesar del nombre
/// era esta pantalla.
class JardinScreen extends StatefulWidget {
  final bool isEmbedded;

  const JardinScreen({Key? key, this.isEmbedded = false}) : super(key: key);

  @override
  State<JardinScreen> createState() => _JardinScreenState();
}

class _JardinScreenState extends State<JardinScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlantaProvider>().cargar();
    });
  }

  Future<void> _abrirRegistro() async {
    final creada = await Navigator.push<PlantaDetalle>(
      context,
      MaterialPageRoute(builder: (_) => const RegistrarPlantaScreen()),
    );
    if (creada != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${creada.apodo} se agregó a tu jardín'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<PlantaProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
        title: const Text('Mi jardín'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _abrirRegistro,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _encabezado(isDark, provider),
            Expanded(child: _cuerpo(context, provider, isDark)),
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
              color:
              isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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

  /// El subtitulo resume lo que importa: si hay riegos atrasados, eso manda.
  String _subtitulo(PlantaProvider provider) {
    if (provider.cargando || provider.plantas.isEmpty) {
      return 'Tus plantas y sus cuidados';
    }
    if (provider.conRiegoAtrasado > 0) {
      final n = provider.conRiegoAtrasado;
      return n == 1 ? '1 planta con riego atrasado' : '$n plantas con riego atrasado';
    }
    if (provider.enTratamiento > 0) {
      final n = provider.enTratamiento;
      return n == 1 ? '1 planta en tratamiento' : '$n plantas en tratamiento';
    }
    final total = provider.totalPlantas;
    return total == 1 ? '1 planta al día' : '$total plantas al día';
  }

  Widget _cuerpo(BuildContext context, PlantaProvider provider, bool isDark) {
    if (provider.cargando && provider.plantas.isEmpty) {
      return const LoadingView(message: 'Cargando tu jardín...');
    }

    if (provider.error != null && provider.plantas.isEmpty) {
      return ErrorView(
        message: provider.error!,
        onRetry: () => provider.cargar(),
      );
    }

    if (provider.plantas.isEmpty) {
      return EmptyState(
        icon: Icons.local_florist,
        title: 'Tu jardín está vacío',
        message: 'Registra tu primera planta para empezar a cuidarla.',
        buttonText: 'Registrar planta',
        onButtonPressed: _abrirRegistro,
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.cargar(silencioso: true),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: provider.plantas.length,
        itemBuilder: (context, index) {
          final planta = provider.plantas[index];
          return PlantaCard(
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
            color:
            isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Se borrarán también sus diagnósticos y tareas. '
              '¿Quieres borrar ${planta.apodo}?',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 14,
            color:
            isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        actionsPadding: const EdgeInsets.all(8),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar',
                      style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    final provider = context.read<PlantaProvider>();
                    final messenger = ScaffoldMessenger.of(context);
                    final ok = await provider.eliminar(planta.id);
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? '${planta.apodo} se eliminó del jardín'
                              : provider.error ?? 'No se pudo eliminar',
                        ),
                        backgroundColor:
                        ok ? AppColors.textSecondary : AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Eliminar',
                      style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}