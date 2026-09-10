import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/routes.dart';
import '../../models/plant.dart';
import '../../widgets/plant/plant_status_badge.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/secondary_button.dart';

class PlantDetailScreen extends StatelessWidget {
  const PlantDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final plant = ModalRoute.of(context)?.settings.arguments as Plant;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: plant.imageUrl != null
                  ? Image.network(
                plant.imageUrl!,
                fit: BoxFit.cover,
              )
                  : Container(
                color: AppColors.primaryBg,
                child: const Icon(
                  Icons.local_florist,
                  size: 80,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre y especie
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plant.name,
                              style: AppTextStyles.displayMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              plant.species,
                              style: AppTextStyles.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                      PlantStatusBadge(status: plant.status),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Información de cuidado
                  _buildCareInfo(context, plant),
                  const SizedBox(height: 24),

                  // Último diagnóstico
                  _buildLastDiagnosis(context, plant),
                  const SizedBox(height: 24),

                  // Botones de acción
                  PrimaryButton(
                    text: 'Analizar nuevamente',
                    icon: Icons.camera_alt,
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.uploadPlant);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          text: 'Editar',
                          icon: Icons.edit,
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.addPlant,
                              arguments: plant,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SecondaryButton(
                          text: 'Eliminar',
                          icon: Icons.delete,
                          onPressed: () {
                            _showDeleteConfirmation(context, plant);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareInfo(BuildContext context, Plant plant) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cuidados',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: 16),
          if (plant.wateringFrequency != null)
            _buildCareItem(
              icon: Icons.water_drop,
              label: 'Riego',
              value: plant.wateringFrequency!,
            ),
          if (plant.lightRequirement != null)
            _buildCareItem(
              icon: Icons.wb_sunny,
              label: 'Iluminación',
              value: plant.lightRequirement!,
            ),
          if (plant.humidity != null)
            _buildCareItem(
              icon: Icons.opacity,
              label: 'Humedad',
              value: plant.humidity!,
            ),
          if (plant.nextCare != null)
            _buildCareItem(
              icon: Icons.event,
              label: 'Próximo cuidado',
              value: plant.nextCare!,
            ),
        ],
      ),
    );
  }

  Widget _buildCareItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLastDiagnosis(BuildContext context, Plant plant) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Último diagnóstico',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: 12),
          if (plant.lastDiagnosisDate != null)
            Row(
              children: [
                const Icon(
                  Icons.history,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Hace ${DateTime.now().difference(plant.lastDiagnosisDate!).inDays} días',
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            )
          else
            Text(
              'Aún no hay diagnósticos',
              style: AppTextStyles.bodyMedium,
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Plant plant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar planta'),
        content: Text('¿Estás seguro de que quieres eliminar a ${plant.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Aquí se eliminaría la planta
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${plant.name} eliminada correctamente'),
                  backgroundColor: AppColors.error,
                ),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}