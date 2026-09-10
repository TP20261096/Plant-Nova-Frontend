import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../data/mock_guides.dart';
import '../../widgets/plant/plant_guide_card.dart';

class MyPlantsScreen extends StatelessWidget {
  final bool isEmbedded;

  const MyPlantsScreen({
    Key? key,
    this.isEmbedded = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: isEmbedded
          ? null
          : AppBar(
        title: const Text('Guías de cultivo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título y descripción centrados
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Guías de cultivo',
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      // Usar el mismo color que el saludo de home
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aprende a cuidar cada tipo de cultivo',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14,
                      // Usar el mismo color que el subtítulo de home
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: mockPlantGuides.length,
                itemBuilder: (context, index) {
                  final guide = mockPlantGuides[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PlantGuideCard(guide: guide),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}