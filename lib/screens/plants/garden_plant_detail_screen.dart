import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/routes.dart';
import '../../core/utils/time_formatter.dart';
import '../../models/plant.dart';
import '../../models/diagnosis.dart';
import '../../providers/plant_provider.dart';
import '../diagnosis/diagnosis_result_screen.dart';
import 'dart:io';
import 'image_preview_screen.dart';

class GardenPlantDetailScreen extends StatefulWidget {
  final Plant plant;

  const GardenPlantDetailScreen({Key? key, required this.plant}) : super(key: key);

  @override
  State<GardenPlantDetailScreen> createState() => _GardenPlantDetailScreenState();
}

class _GardenPlantDetailScreenState extends State<GardenPlantDetailScreen> {
  late String _plantName;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _plantName = widget.plant.name;
    _nameController.text = _plantName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _changeName() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.all(16),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          actionsPadding: const EdgeInsets.all(8),
          title: Text(
            'Cambiar nombre',
            style: AppTextStyles.titleLarge.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          content: TextField(
            controller: _nameController,
            textAlign: TextAlign.center,
            autofocus: true,
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: 'Ej: Mi tomate',
              hintStyle: TextStyle(
                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                fontSize: 14,
              ),
              filled: true,
              fillColor: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.primaryBg,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryLight,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
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
                      if (_nameController.text.trim().isNotEmpty) {
                        final newName = _nameController.text.trim();

                        context.read<PlantProvider>().updatePlantName(
                          widget.plant.id,
                          newName,
                        );

                        setState(() {
                          _plantName = newName;
                        });

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Nombre actualizado correctamente',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                            backgroundColor: AppColors.success,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Guardar',
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

  // Método para iniciar un nuevo diagnóstico de la misma planta
  void _startNewDiagnosis() {
    // Navegar a la pantalla de captura pasando el ID de la planta
    Navigator.pushNamed(
      context,
      AppRoutes.uploadPlant,
      arguments: {'plantId': widget.plant.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final plantProvider = context.watch<PlantProvider>();
    final currentPlant = plantProvider.plants.firstWhere(
          (p) => p.id == widget.plant.id,
      orElse: () => widget.plant,
    );

    final diagnoses = currentPlant.diagnosisHistory ?? [];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          _plantName,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _changeName,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlantHeader(isDark, currentPlant),
            const SizedBox(height: 24),
            _buildPlantInfo(isDark, currentPlant),
            const SizedBox(height: 24),

            // Título de diagnósticos con botón de nuevo diagnóstico
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Diagnósticos',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                // Botón de nuevo diagnóstico
                ElevatedButton.icon(
                  onPressed: _startNewDiagnosis,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'Nuevo',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (diagnoses.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.health_and_safety,
                      size: 40,
                      color: AppColors.primaryLight,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aún no hay diagnósticos',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _startNewDiagnosis,
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('Analizar planta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...diagnoses.asMap().entries.map((entry) {
                final index = entry.key;
                final diagnosis = entry.value;
                return _buildDiagnosisCard(
                  context,
                  diagnosis,
                  isDark,
                  diagnosticNumber: index + 1, // ← index + 1 para que empiece en 1
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantHeader(bool isDark, Plant plant) {
    final Color statusColor = _getStatusColor(plant.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor,
            statusColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Imagen clickeable con Hero
          GestureDetector(
            onTap: () {
              if (plant.imageUrl != null && plant.imageUrl!.isNotEmpty) {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    opaque: false,
                    barrierColor: Colors.black,
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        ImagePreviewScreen(
                          imageUrl: plant.imageUrl!,
                          heroTag: 'plant_image_${plant.id}',
                          title: _plantName,
                        ),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                  ),
                );
              }
            },
            child: Hero(
              tag: 'plant_image_${plant.id}',
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: _buildPlantImageDetail(plant.imageUrl),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            _plantName,
            style: AppTextStyles.headlineLarge.copyWith(
              color: Colors.white,
              fontSize: 22,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          Text(
            plant.species,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            child: Text(
              plant.status,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

// Método auxiliar para la imagen del detalle
  Widget _buildPlantImageDetail(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Center(
        child: Icon(
          Icons.local_florist,
          color: AppColors.primary,
          size: 50,
        ),
      );
    }

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.local_florist,
              color: AppColors.primary,
              size: 50,
            ),
          );
        },
      );
    }

    final file = File(imageUrl);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.local_florist,
              color: AppColors.primary,
              size: 50,
            ),
          );
        },
      );
    }

    return const Center(
      child: Icon(
        Icons.local_florist,
        color: AppColors.primary,
        size: 50,
      ),
    );
  }

  Widget _buildPlantInfo(bool isDark, Plant plant) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plant.wateringFrequency != null)
            _buildInfoRow(
              Icons.water_drop,
              'Riego',
              plant.wateringFrequency!,
              isDark,
            ),
          if (plant.lightRequirement != null)
            _buildInfoRow(
              Icons.wb_sunny,
              'Iluminación',
              plant.lightRequirement!,
              isDark,
            ),
          if (plant.humidity != null)
            _buildInfoRow(
              Icons.opacity,
              'Humedad',
              plant.humidity!,
              isDark,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryLight, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisCard(
      BuildContext context,
      Diagnosis diagnosis,
      bool isDark, {
        required int diagnosticNumber,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navegar con un parámetro para indicar que viene del jardín
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DiagnosisResultScreen(
                  diagnosis: diagnosis,
                  isFromGarden: true, // ← Indicar que viene del jardín
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: diagnosis.getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.health_and_safety,
                        color: diagnosis.getStatusColor(),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getDiagnosticLabel(diagnosticNumber),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: diagnosticNumber == 1
                                  ? AppColors.primaryLight
                                  : isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                              fontWeight: diagnosticNumber == 1
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            diagnosis.disease,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            TimeFormatter.formatRelativeTime(diagnosis.date),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      diagnosis.confidence,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: diagnosis.getStatusColor(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Ver diagnóstico completo y tratamientos',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDiagnosticLabel(int number) {
    switch (number) {
      case 1:
        return 'Primer diagnóstico';
      case 2:
        return 'Segundo diagnóstico';
      case 3:
        return 'Tercer diagnóstico';
      case 4:
        return 'Cuarto diagnóstico';
      case 5:
        return 'Quinto diagnóstico';
      default:
        return 'Diagnóstico #$number';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'saludable':
        return AppColors.success;
      case 'necesita atención':
        return AppColors.warning;
      case 'enferma':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }
}