import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/routes.dart';
import '../../providers/plant_provider.dart';
import '../../providers/diagnosis_provider.dart';
import '../../providers/weather_provider.dart';
import '../../widgets/navigation/custom_bottom_navigation.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/home/activity_card.dart';
import '../plants/my_plants_screen.dart';
import '../history/diagnosis_history_screen.dart';
import '../profile/profile_screen.dart';
import '../diagnosis/upload_plant_screen.dart';
import '../garden/jardin_screen.dart';
import '../guide/guia_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  DateTime _selectedDate = DateTime.now();
  final PageController _pageController = PageController(initialPage: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlantProvider>().loadPlants();
      context.read<DiagnosisProvider>().loadDiagnoses();
      context.read<WeatherProvider>().loadWeather();

      // Verificar si viene de guardar diagnóstico
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map && args['navigateTo'] == 'garden') {
        setState(() {
          _currentIndex = 3; // Índice del jardín en el bottom navigation
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildHomeContent(context),
      // const MyPlantsScreen(isEmbedded: true),
      const GuiaScreen(isEmbedded: true),
      const UploadPlantScreen(isEmbedded: true),
      // const DiagnosisHistoryScreen(isEmbedded: true),
      const JardinScreen(isEmbedded: true),
      const ProfileScreen(isEmbedded: true),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  void _onNavigationTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.myPlants);
        break;
      case 2:
      // Limpiar el plantId antes de navegar a analizar
        context.read<DiagnosisProvider>().clearPlantId();
        Navigator.pushNamed(context, AppRoutes.uploadPlant);
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.history);
        break;
      case 4:
        Navigator.pushNamed(context, AppRoutes.profile);
        break;
    }
  }

  Widget _buildHomeContent(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeHeader(),
          _buildDaysSelector(),
          const SizedBox(height: 2),
          _buildActivitiesTitle(context),
          Expanded(
            child: _buildActivitiesForDate(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysSelector() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: PageView.builder(
        controller: _pageController,
        itemCount: 5,
        onPageChanged: (index) {
          setState(() {
            _selectedDate = DateTime.now().add(Duration(days: index - 2));
          });
        },
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index - 2));
          final isSelected = index == 2;
          return _buildDayCard(date, isSelected);
        },
      ),
    );
  }

  Widget _buildDayCard(DateTime date, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary
            : isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getDayName(date),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Colors.white
                  : isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesTitle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateString = _formatSelectedDate(_selectedDate);

    return Container(
      width: double.infinity,
      height: 40,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        'Actividades para $dateString',
        style: AppTextStyles.titleMedium.copyWith(
          fontSize: 14,
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildActivitiesForDate(BuildContext context) {
    final activities = _getActivitiesForDate(_selectedDate);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        if (activities.isEmpty)
          _buildEmptyActivities(context)
        else
          ...activities.map((activity) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: ActivityCard(activity: activity),
            );
          }).toList(),
        const SizedBox(height: 16),
        _buildWeatherCard(context),
        const SizedBox(height: 8),
        _buildPlantStatusSummary(context),
        const SizedBox(height: 8),
        _buildQuickTip(context),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildEmptyActivities(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 70,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 24,
              color: AppColors.primaryLight,
            ),
            const SizedBox(height: 4),
            Text(
              'No hay actividades para este día',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard(BuildContext context) {
    final weatherProvider = context.watch<WeatherProvider>();
    final weather = weatherProvider.weather;

    if (weatherProvider.isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade200,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Cargando clima...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (weather == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade200,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No se pudo obtener el clima',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => weatherProvider.loadWeather(),
                    child: Text(
                      'Reintentar',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade400,
            Colors.blue.shade200,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono del clima
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: _getWeatherIcon(weather.icon, size: 28),
          ),
          const SizedBox(width: 12),

          // Información principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clima en ${weather.cityName}',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${weather.description} · ${weather.temperatureCelsius}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Humedad y viento
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.water_drop,
                    color: Colors.white.withOpacity(0.8),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${weather.humidity}%',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.air,
                    color: Colors.white.withOpacity(0.8),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(weather.windSpeed * 3.6).toStringAsFixed(1)} km/h',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getWeatherIcon(String iconCode, {double size = 24}) {
    switch (iconCode) {
      case '01d':
        return Icon(Icons.wb_sunny, color: Colors.white, size: size);
      case '01n':
        return Icon(Icons.nightlight, color: Colors.white, size: size);
      case '02d':
      case '02n':
        return Icon(Icons.wb_cloudy, color: Colors.white, size: size);
      case '03d':
      case '03n':
      case '04d':
      case '04n':
        return Icon(Icons.cloud, color: Colors.white, size: size);
      case '09d':
      case '09n':
      case '10d':
      case '10n':
        return Icon(Icons.water_drop, color: Colors.white, size: size);
      case '11d':
      case '11n':
        return Icon(Icons.thunderstorm, color: Colors.white, size: size);
      case '13d':
      case '13n':
        return Icon(Icons.snowing, color: Colors.white, size: size);
      case '50d':
      case '50n':
        return Icon(Icons.foggy, color: Colors.white, size: size);
      default:
        return Icon(Icons.wb_sunny, color: Colors.white, size: size);
    }
  }

  Widget _buildPlantStatusSummary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plantProvider = context.watch<PlantProvider>();
    final totalPlants = plantProvider.plants.length;
    final healthyPlants = plantProvider.healthyPlantsCount;
    final attentionPlants = plantProvider.plantsNeedingAttention;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estado de tus cultivos',
                style: AppTextStyles.titleMedium.copyWith(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                },
                child: Text(
                  'Ver todos',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatusItem(
                icon: Icons.eco,
                color: AppColors.success,
                label: 'Saludables',
                value: healthyPlants,
              ),
              const SizedBox(width: 8),
              _buildStatusItem(
                icon: Icons.warning,
                color: AppColors.warning,
                label: 'Atención',
                value: attentionPlants,
              ),
              const SizedBox(width: 8),
              _buildStatusItem(
                icon: Icons.local_florist,
                color: AppColors.primaryLight,
                label: 'Total',
                value: totalPlants,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required Color color,
    required String label,
    required int value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 2),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTip(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkPrimaryBg : AppColors.primaryBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryLight.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.tips_and_updates,
              color: AppColors.warning,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Consejo del día',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 12,
                    color: AppColors.primaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Riega tus plantas temprano en la mañana para evitar la evaporación.',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 10,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
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

  List<Map<String, dynamic>> _getActivitiesForDate(DateTime date) {
    final plantProvider = context.read<PlantProvider>();

    // Obtener actividades basadas en diagnósticos
    final diagnosticActivities = plantProvider.generateActivitiesForDate(date);

    // Si hay actividades de diagnósticos, usarlas
    if (diagnosticActivities.isNotEmpty) {
      return diagnosticActivities;
    }

    // Si no hay plantas con diagnósticos, usar actividades generales
    final dayOfWeek = date.weekday;
    final activities = <Map<String, dynamic>>[];

    if (dayOfWeek == 1 || dayOfWeek == 4) {
      activities.add({
        'id': 'riego_general',
        'title': 'Regar cultivos',
        'description': 'Regar todas las plantas del jardín',
        'icon': '💧',
        'type': 'riego',
      });
    }

    if (dayOfWeek == 2 || dayOfWeek == 5) {
      activities.add({
        'id': 'monitoreo_general',
        'title': 'Monitorear plagas',
        'description': 'Revisar hojas y frutos en busca de insectos',
        'icon': '🔍',
        'type': 'monitoreo',
      });
    }

    if (dayOfWeek == 3) {
      activities.add({
        'id': 'fertilizacion_general',
        'title': 'Fertilizar',
        'description': 'Aplicar compost a los cultivos',
        'icon': '🌱',
        'type': 'fertilizacion',
      });
    }

    if (dayOfWeek == 6) {
      activities.add({
        'id': 'cosecha_general',
        'title': 'Cosechar',
        'description': 'Recolectar frutos y verduras maduras',
        'icon': '🧺',
        'type': 'cosecha',
      });
    }

    return activities;
  }

  String _getDayName(DateTime date) {
    const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return days[date.weekday - 1];
  }

  String _formatSelectedDate(DateTime date) {
    final isToday = date.day == DateTime.now().day &&
        date.month == DateTime.now().month &&
        date.year == DateTime.now().year;

    if (isToday) {
      return 'hoy';
    }

    final isYesterday = date.day == DateTime.now().subtract(const Duration(days: 1)).day &&
        date.month == DateTime.now().subtract(const Duration(days: 1)).month;

    if (isYesterday) {
      return 'ayer';
    }

    final isTomorrow = date.day == DateTime.now().add(const Duration(days: 1)).day &&
        date.month == DateTime.now().add(const Duration(days: 1)).month;

    if (isTomorrow) {
      return 'mañana';
    }

    return '${_getDayName(date)} ${date.day}';
  }
}