import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../providers/actividad_provider.dart';
import '../../providers/planta_provider.dart';
import '../../providers/weather_provider.dart';
import '../../widgets/home/actividad_card.dart';
import '../../widgets/home/home_header.dart';
import '../../widgets/navigation/custom_bottom_navigation.dart';
import '../actividades/actividades_dia_screen.dart';
import '../diagnosis/upload_plant_screen.dart';
import '../garden/jardin_screen.dart';
import '../guide/guia_screen.dart';
import '../profile/perfil_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  DateTime _selectedDate = DateTime.now();

  final PageController _pageController = PageController(initialPage: 2);

  /// Máximo de actividades visibles en el inicio
  static const int _maxActividadesInicio = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlantaProvider>().cargar();
      context.read<ActividadProvider>().cargar();
      context.read<WeatherProvider>().loadWeather();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pantallas = [
      _buildHomeContent(context),
      const GuiaScreen(isEmbedded: true),
      const UploadPlantScreen(isEmbedded: true),
      const JardinScreen(isEmbedded: true),
      const PerfilScreen(isEmbedded: true),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pantallas,
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HOME CONTENT
  // ═══════════════════════════════════════════════════════════
  Widget _buildHomeContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await context.read<ActividadProvider>().cargar(silencioso: true);
          await context.read<WeatherProvider>().loadWeather();
          await context.read<PlantaProvider>().cargar(silencioso: true);
        },
        color: AppColors.primaryLight,
        child: SingleChildScrollView(
          // ✅ AlwaysScrollable → siempre se puede scrollear (incluso si el contenido entra)
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. CLIMA
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: _buildWeatherCard(context),
              ),

              // 2. SALUDO
              const HomeHeader(),

              // 3. BOX DE ACTIVIDADES
              Container(
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
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
                    Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Text(
                        _tituloActividades(_selectedDate),
                        style: AppTextStyles.titleMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildDaysSelector(),
                    const SizedBox(height: 4),
                    _buildActivitiesSection(context),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // 4. ESTADO DE CULTIVOS
              _buildPlantStatusSummary(context),

              const SizedBox(height: 4),

              // 5. CONSEJOS
              _buildQuickTip(),

              // ✅ Espacio al final para que se pueda scrollear hasta el fondo
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SECCIÓN ACTIVIDADES
  // ═══════════════════════════════════════════════════════════
  Widget _buildActivitiesSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<ActividadProvider>();
    final todas = provider.actividades;

    final visibles = todas.take(_maxActividadesInicio).toList();
    final hayMas = todas.length > _maxActividadesInicio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cargando
        if (provider.cargando && todas.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryLight,
                  ),
                  strokeWidth: 2,
                ),
              ),
            ),
          )
        // Vacío
        else if (todas.isEmpty)
          _buildEmptyActivities(isDark)
        // Con actividades
        else ...[
            ...visibles.map((actividad) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF3A3A3A)
                          : const Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ActividadCard(actividad: actividad),
                  ),
                ),
              );
            }),
            if (hayMas) ...[
              const SizedBox(height: 6),
              _buildVerTodasButton(context, todas.length),
            ],
          ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BOTÓN "VER TODAS"
  // ═══════════════════════════════════════════════════════════
  Widget _buildVerTodasButton(BuildContext context, int total) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 40,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ActividadesDiaScreen(fecha: _selectedDate),
              ),
            );
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkPrimaryBg : AppColors.primaryBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primaryLight.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Ver todas',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '($total)',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.primaryLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SELECTOR DE DÍAS
  // ═══════════════════════════════════════════════════════════
  Widget _buildDaysSelector() {
    return Container(
      height: 56,
      child: PageView.builder(
        controller: _pageController,
        itemCount: 5,
        onPageChanged: (index) {
          final date = DateTime.now().add(Duration(days: index - 2));
          setState(() => _selectedDate = date);
          context.read<ActividadProvider>().seleccionarFecha(date);
        },
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index - 2));
          return _buildDayCard(date);
        },
      ),
    );
  }

  Widget _buildDayCard(DateTime date) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    final isToday = date.day == now.day &&
        date.month == now.month &&
        date.year == now.year;

    final isSelected = date.day == _selectedDate.day &&
        date.month == _selectedDate.month &&
        date.year == _selectedDate.year;

    final bgColor = isToday
        ? AppColors.primary
        : (isDark ? AppColors.darkSurface : AppColors.surface);

    final dayNameColor = isToday
        ? Colors.white.withOpacity(0.9)
        : (isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary);

    final dayNumberColor = isToday
        ? Colors.white
        : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: isSelected && !isToday
            ? Border.all(color: AppColors.primaryLight, width: 2)
            : null,
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
        children: [
          Text(
            _getDayName(date),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: dayNameColor,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: dayNumberColor,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CLIMA
  // ═══════════════════════════════════════════════════════════
  Widget _buildWeatherCard(BuildContext context) {
    final weatherProvider = context.watch<WeatherProvider>();
    final weather = weatherProvider.weather;

    if (weatherProvider.isLoading && weather == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade400, Colors.blue.shade200],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Cargando clima...',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (weather == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade400, Colors.blue.shade200],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, color: Colors.white, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => weatherProvider.loadWeather(),
                child: const Text(
                  'No se pudo cargar el clima. Toca para reintentar.',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade400, Colors.blue.shade200],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getWeatherIcon(weather.icon),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weather.cityName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  '${weather.description} · ${weather.temperature.toStringAsFixed(1)}°C',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.water_drop,
                    color: Colors.white.withOpacity(0.9),
                    size: 12,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${weather.humidity}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.air,
                    color: Colors.white.withOpacity(0.9),
                    size: 12,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${(weather.windSpeed * 3.6).toStringAsFixed(0)} km/h',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
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

  IconData _getWeatherIcon(String iconCode) {
    switch (iconCode) {
      case '01d':
        return Icons.wb_sunny;
      case '01n':
        return Icons.nightlight;
      case '02d':
      case '02n':
        return Icons.wb_cloudy;
      case '03d':
      case '03n':
      case '04d':
      case '04n':
        return Icons.cloud;
      case '09d':
      case '09n':
      case '10d':
      case '10n':
        return Icons.water_drop;
      case '11d':
      case '11n':
        return Icons.thunderstorm;
      case '13d':
      case '13n':
        return Icons.ac_unit;
      case '50d':
      case '50n':
        return Icons.foggy;
      default:
        return Icons.wb_sunny;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ESTADO DE CULTIVOS
  // ═══════════════════════════════════════════════════════════
  Widget _buildPlantStatusSummary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plantaProvider = context.watch<PlantaProvider>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
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
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Estado de tus cultivos',
              style: AppTextStyles.titleMedium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Row(
            children: [
              _buildStatusItem(
                icon: Icons.eco,
                color: AppColors.success,
                label: 'Sanas',
                value: plantaProvider.sanas,
              ),
              const SizedBox(width: 6),
              _buildStatusItem(
                icon: Icons.healing,
                color: AppColors.warning,
                label: 'Tratamiento',
                value: plantaProvider.enTratamiento,
              ),
              const SizedBox(width: 6),
              _buildStatusItem(
                icon: Icons.water_drop,
                color: AppColors.error,
                label: 'Riego',
                value: plantaProvider.conRiegoAtrasado,
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CONSEJOS
  // ═══════════════════════════════════════════════════════════
  Widget _buildQuickTip() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final consejos = [
      {
        'icon': Icons.water_drop,
        'titulo': 'Riego matutino',
        'texto': 'Riega tus plantas temprano en la mañana para evitar la evaporación.',
      },
      {
        'icon': Icons.wb_sunny,
        'titulo': 'Luz adecuada',
        'texto': 'La mayoría de cultivos necesitan 6-8 horas de luz solar directa al día.',
      },
      {
        'icon': Icons.eco,
        'titulo': 'Abono orgánico',
        'texto': 'Usa compost o humus de lombriz cada 15 días para fortalecer tus plantas.',
      },
      {
        'icon': Icons.content_cut,
        'titulo': 'Poda regular',
        'texto': 'Elimina hojas secas o enfermas para mejorar la circulación de aire.',
      },
      {
        'icon': Icons.bug_report,
        'titulo': 'Monitoreo',
        'texto': 'Revisa el envés de las hojas cada 2-3 días para detectar plagas a tiempo.',
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Consejos para tus plantas',
              style: AppTextStyles.titleMedium.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            height: 68,
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.95),
              itemCount: consejos.length,
              itemBuilder: (context, index) {
                final consejo = consejos[index];
                return _buildTipCard(
                  isDark,
                  icon: consejo['icon'] as IconData,
                  titulo: consejo['titulo'] as String,
                  texto: consejo['texto'] as String,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(
      bool isDark, {
        required IconData icon,
        required String titulo,
        required String texto,
      }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkPrimaryBg : AppColors.primaryBg,
        borderRadius: BorderRadius.circular(10),
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
            child: Icon(
              icon,
              color: AppColors.warning,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  titulo,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 12,
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  texto,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    height: 1.2,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
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

  // ═══════════════════════════════════════════════════════════
  // EMPTY ACTIVITIES
  // ═══════════════════════════════════════════════════════════
  Widget _buildEmptyActivities(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available,
            size: 32,
            color: AppColors.primaryLight,
          ),
          const SizedBox(height: 8),
          Text(
            'No hay actividades para este día',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            'Descansa o adelanta otras tareas',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 10,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════
  String _tituloActividades(DateTime date) {
    final now = DateTime.now();

    final isToday = date.day == now.day &&
        date.month == now.month &&
        date.year == now.year;
    if (isToday) return 'Actividades de hoy';

    final ayer = now.subtract(const Duration(days: 1));
    final isYesterday = date.day == ayer.day &&
        date.month == ayer.month &&
        date.year == ayer.year;
    if (isYesterday) return 'Actividades de ayer';

    final manana = now.add(const Duration(days: 1));
    final isTomorrow = date.day == manana.day &&
        date.month == manana.month &&
        date.year == manana.year;
    if (isTomorrow) return 'Actividades de mañana';

    final nombreDia = _getDayNameCompleto(date);
    return 'Actividades del $nombreDia ${date.day}';
  }

  String _getDayName(DateTime date) {
    const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return dias[date.weekday - 1];
  }

  String _getDayNameCompleto(DateTime date) {
    const dias = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    return dias[date.weekday - 1];
  }
}