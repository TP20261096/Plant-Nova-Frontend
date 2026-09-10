import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../models/plant_guide.dart';
import '../../widgets/common/animated_tab_bar.dart';

class PlantGuideDetailScreen extends StatefulWidget {
  final PlantGuide guide;

  const PlantGuideDetailScreen({Key? key, required this.guide}) : super(key: key);

  @override
  State<PlantGuideDetailScreen> createState() => _PlantGuideDetailScreenState();
}

class _PlantGuideDetailScreenState extends State<PlantGuideDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final guide = widget.guide;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          guide.name,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header
          _buildPlantHeader(isDark, guide),

          const SizedBox(height: 12),

          // TabBar animado personalizado
          AnimatedTabBar(
            controller: _tabController,
            indicatorColor: AppColors.primaryLight,
            labelColor: Colors.white,
            unselectedLabelColor: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
            tabs: const [
              AnimatedTab(
                icon: Icons.landscape,
                label: 'Preparación',
              ),
              AnimatedTab(
                icon: Icons.grass,
                label: 'Siembra',
              ),
              AnimatedTab(
                icon: Icons.favorite,
                label: 'Cuidados',
              ),
              AnimatedTab(
                icon: Icons.warning,
                label: 'Enfermedades',
              ),
              AnimatedTab(
                icon: Icons.agriculture,
                label: 'Cosecha',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Contenido
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPreparationTab(isDark, guide),
                _buildPlantingTab(isDark, guide),
                _buildCareTab(isDark, guide),
                _buildDiseasesTab(isDark, guide),
                _buildHarvestTab(isDark, guide),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Header con la foto y descripción de la planta
  Widget _buildPlantHeader(bool isDark, PlantGuide guide) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                guide.icon,
                style: const TextStyle(fontSize: 30),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            guide.name,
            style: AppTextStyles.headlineLarge.copyWith(
              color: Colors.white,
              fontSize: 22,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            guide.scientificName,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontStyle: FontStyle.italic,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            child: Text(
              guide.plantingSeason,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            guide.description,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // TAB 1: PREPARACIÓN
  // ═══════════════════════════════════════════════
  Widget _buildPreparationTab(bool isDark, PlantGuide guide) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Requisitos del suelo', Icons.landscape, isDark),
          const SizedBox(height: 12),
          _buildRequirementCard('Suelo', guide.requirements['Suelo'] ?? 'No especificado', isDark),
          const SizedBox(height: 12),
          _buildRequirementCard('pH recomendado', '6.0 - 7.0', isDark),
          const SizedBox(height: 24),
          _buildSectionTitle('Condiciones ambientales', Icons.thermostat, isDark),
          const SizedBox(height: 12),
          _buildRequirementCard('Temperatura', guide.requirements['Temperatura'] ?? 'No especificado', isDark),
          const SizedBox(height: 12),
          _buildRequirementCard('Humedad', guide.requirements['Humedad'] ?? 'No especificado', isDark),
          const SizedBox(height: 12),
          _buildRequirementCard('Luz', guide.requirements['Luz'] ?? 'No especificado', isDark),
          const SizedBox(height: 24),
          _buildSectionTitle('Materiales necesarios', Icons.checklist, isDark),
          const SizedBox(height: 12),
          _buildMaterialsList(isDark),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // TAB 2: SIEMBRA
  // ═══════════════════════════════════════════════
  Widget _buildPlantingTab(bool isDark, PlantGuide guide) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Temporada de siembra', Icons.calendar_today, isDark),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.event,
            title: 'Mejor época',
            content: guide.plantingSeason,
            isDark: isDark,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Pasos para sembrar', Icons.format_list_numbered, isDark),
          const SizedBox(height: 12),
          _buildStepsList(isDark),
          const SizedBox(height: 24),
          _buildSectionTitle('Consejos de siembra', Icons.tips_and_updates, isDark),
          const SizedBox(height: 12),
          _buildTipsCard(isDark),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // TAB 3: CUIDADOS
  // ═══════════════════════════════════════════════
  Widget _buildCareTab(bool isDark, PlantGuide guide) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Riego', Icons.water_drop, isDark),
          const SizedBox(height: 12),
          _buildRequirementCard('Frecuencia', guide.requirements['Riego'] ?? 'No especificado', isDark),
          const SizedBox(height: 24),
          _buildSectionTitle('Fertilización', Icons.grass, isDark),
          const SizedBox(height: 12),
          _buildRequirementCard('Frecuencia', guide.requirements['Fertilización'] ?? 'No especificado', isDark),
          const SizedBox(height: 24),
          _buildSectionTitle('Cuidados especiales', Icons.favorite, isDark),
          const SizedBox(height: 12),
          _buildCareTipsList(isDark, guide),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // TAB 4: ENFERMEDADES
  // ═══════════════════════════════════════════════
  Widget _buildDiseasesTab(bool isDark, PlantGuide guide) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Enfermedades comunes', Icons.warning, isDark),
          const SizedBox(height: 12),
          _buildDiseasesList(isDark, guide),
          const SizedBox(height: 24),
          _buildSectionTitle('Tratamientos orgánicos', Icons.eco, isDark),
          const SizedBox(height: 12),
          _buildOrganicTreatments(isDark, guide),
          const SizedBox(height: 24),
          _buildSectionTitle('Prevención', Icons.shield, isDark),
          const SizedBox(height: 12),
          _buildPreventionTips(isDark),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // TAB 5: COSECHA
  // ═══════════════════════════════════════════════
  Widget _buildHarvestTab(bool isDark, PlantGuide guide) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Información de cosecha', Icons.agriculture, isDark),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.schedule,
            title: 'Tiempo de cosecha',
            content: guide.harvestTime,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.calendar_today,
            title: 'Temporada',
            content: guide.plantingSeason,
            isDark: isDark,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Señales de madurez', Icons.visibility, isDark),
          const SizedBox(height: 12),
          _buildMaturitySigns(isDark),
          const SizedBox(height: 24),
          _buildSectionTitle('Método de cosecha', Icons.cut, isDark),
          const SizedBox(height: 12),
          _buildHarvestMethod(isDark),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // WIDGETS REUTILIZABLES
  // ═══════════════════════════════════════════════

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkPrimaryBg : AppColors.primaryBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryLight, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementCard(String title, String value, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.primaryBg,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkPrimaryBg : AppColors.primaryBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryLight, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsList(bool isDark) {
    final materials = [
      'Semillas certificadas',
      'Sustrato o tierra preparada',
      'Macetas o contenedores',
      'Herramientas de jardinería',
      'Compost orgánico',
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.primaryBg,
        ),
      ),
      child: Column(
        children: materials.map((material) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    material,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStepsList(bool isDark) {
    final steps = [
      'Preparar el suelo con compost',
      'Sembrar las semillas a la profundidad adecuada',
      'Regar suavemente',
      'Mantener la humedad constante',
      'Proteger de condiciones extremas',
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final step = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryLight.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    step,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTipsCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.warning.withOpacity(0.15)
            : AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb,
              color: AppColors.warning,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Siembra en un día nublado o al atardecer para evitar el estrés de las plántulas.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareTipsList(bool isDark, PlantGuide guide) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.primaryBg,
        ),
      ),
      child: Column(
        children: guide.careTips.map((tip) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tip,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDiseasesList(bool isDark, PlantGuide guide) {
    return Column(
      children: guide.commonDiseases.map((disease) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.warning.withOpacity(0.15)
                : AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning,
                  color: AppColors.warning,
                  size: 14,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  disease,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOrganicTreatments(bool isDark, PlantGuide guide) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.primaryBg,
        ),
      ),
      child: Column(
        children: guide.organicTreatments.map((treatment) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.eco,
                    color: AppColors.primaryLight,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    treatment,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPreventionTips(bool isDark) {
    final tips = [
      'Rotar cultivos anualmente',
      'Mantener buena circulación de aire',
      'Limpiar herramientas regularmente',
      'Eliminar plantas enfermas',
      'Usar semillas certificadas',
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.primaryBg,
        ),
      ),
      child: Column(
        children: tips.map((tip) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield,
                    size: 14,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tip,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMaturitySigns(bool isDark) {
    final signs = [
      'Color característico de la variedad',
      'Tamaño adecuado',
      'Textura firme',
      'Fácil desprendimiento',
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.primaryBg,
        ),
      ),
      child: Column(
        children: signs.map((sign) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.visibility,
                    color: AppColors.primaryLight,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    sign,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHarvestMethod(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkPrimaryBg : AppColors.primaryBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryLight.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.cut,
                  color: AppColors.primaryLight,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Recomendaciones:',
                style: AppTextStyles.titleMedium.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Text(
              '• Cosecha temprano en la mañana\n'
                  '• Usa herramientas limpias y afiladas\n'
                  '• Maneja con cuidado para evitar daños\n'
                  '• Almacena en lugar fresco y seco',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}