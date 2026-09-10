import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/routes.dart';
import '../../providers/plant_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/plant/garden_plant_card.dart';

class DiagnosisHistoryScreen extends StatelessWidget {
  final bool isEmbedded;

  const DiagnosisHistoryScreen({
    Key? key,
    this.isEmbedded = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plantProvider = context.watch<PlantProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: isEmbedded
          ? null
          : AppBar(
        title: Text(
          'Mi jardín',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título centrado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Mi jardín',
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tus plantas y sus diagnósticos',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            Expanded(
              child: _buildBody(context, plantProvider, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PlantProvider provider, bool isDark) {
    if (provider.isLoading) {
      return const LoadingView(message: 'Cargando tu jardín...');
    }

    if (provider.error != null) {
      return ErrorView(
        message: provider.error!,
        onRetry: () => provider.loadPlants(),
      );
    }

    if (provider.plants.isEmpty) {
      return EmptyState(
        icon: Icons.local_florist,
        title: 'Tu jardín está vacío',
        message: 'Toma una foto de tu planta para agregarla a tu jardín.',
        buttonText: 'Analizar planta',
        onButtonPressed: () {
          Navigator.pushNamed(context, AppRoutes.uploadPlant);
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadPlants(),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: provider.plants.length,
        itemBuilder: (context, index) {
          final plant = provider.plants[index];
          return GardenPlantCard(
            plant: plant,
            onLongPress: () {
              _showDeleteConfirmation(context, plant, isDark);
            },
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, dynamic plant, bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          titlePadding: const EdgeInsets.all(16),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          actionsPadding: const EdgeInsets.all(8),
          title: Text(
            'Eliminar planta',
            style: AppTextStyles.titleLarge.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontSize: 17,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            '¿Quieres borrar ${plant.name}?',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<PlantProvider>().deletePlant(plant.id);
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${plant.name} eliminada del jardín',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                          ),
                          backgroundColor: AppColors.error,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Aceptar',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}