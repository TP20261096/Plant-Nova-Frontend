import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/routes.dart';
import '../../providers/plant_provider.dart';
import '../../providers/diagnosis_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isEmbedded;

  const ProfileScreen({
    Key? key,
    this.isEmbedded = false,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Usuario';
  String _userDescription = 'Amante de los cultivos gaa';
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ?? 'Usuario';
        _userDescription = prefs.getString('user_description') ?? 'Amante de los cultivos';
        _profileImagePath = prefs.getString('profile_image');
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plantProvider = context.watch<PlantProvider>();
    final diagnosisProvider = context.watch<DiagnosisProvider>();

    return Scaffold(
      appBar: widget.isEmbedded
          ? null
          : AppBar(
        title: const Text('Mi perfil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isEmbedded) ...[
                // Título centrado
                Container(
                  width: double.infinity,
                  child: Text(
                    'Mi perfil',
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              _buildUserInfo(context, isDark),
              const SizedBox(height: 24),
              _buildStatistics(context, plantProvider, diagnosisProvider),
              const SizedBox(height: 24),
              _buildMenuOptions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkPrimaryBg : AppColors.primaryBg,
                  shape: BoxShape.circle,
                ),
                child: _profileImagePath != null
                    ? ClipOval(
                  child: Image.file(
                    File(_profileImagePath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.person,
                        size: 35,
                        color: AppColors.primaryLight,
                      );
                    },
                  ),
                )
                    : const Icon(
                  Icons.person,
                  size: 35,
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userDescription,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                // Navegar a la pantalla de edición y esperar el resultado
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );

                // Recargar datos después de volver
                if (result == true) {
                  await _loadUserData();
                }
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Editar perfil'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
                side: const BorderSide(color: AppColors.primaryLight),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(
      BuildContext context,
      PlantProvider plantProvider,
      DiagnosisProvider diagnosisProvider,
      ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            value: plantProvider.plants.length.toString(),
            label: 'Cultivos',
            icon: Icons.local_florist,
            isDark: isDark,
          ),
          _buildStatItem(
            value: diagnosisProvider.diagnoses.length.toString(),
            label: 'Diagnósticos',
            icon: Icons.history,
            isDark: isDark,
          ),
          _buildStatItem(
            value: plantProvider.healthyPlantsCount.toString(),
            label: 'Saludables',
            icon: Icons.favorite,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryLight, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.titleLarge.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opciones',
          style: AppTextStyles.titleLarge.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildMenuItem(
          context,
          icon: Icons.settings,
          title: 'Configuración',
          subtitle: 'Preferencias de la aplicación',
          isDark: isDark,
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.settings);
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.info,
          title: 'Acerca de PlantNova',
          subtitle: 'Información de la aplicación',
          isDark: isDark,
          onTap: () {
            _showAboutDialog(context);
          },
        ),
        _buildMenuItem(
          context,
          icon: Icons.help,
          title: 'Ayuda',
          subtitle: 'Preguntas frecuentes',
          isDark: isDark,
          onTap: () {
            // Aquí se abriría la pantalla de ayuda
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required bool isDark,
        required VoidCallback onTap,
      }) {
    return Card(
      color: isDark ? AppColors.darkSurface : AppColors.surface,
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryLight),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        title: Text(
          'Acerca de PlantNova',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Versión 1.0.0',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'PlantNova es una aplicación diseñada para ayudarte a cuidar tus cultivos de manera natural y efectiva.',
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Utiliza tecnología de inteligencia artificial para identificar enfermedades y proporcionar tratamientos orgánicos.',
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(
                color: AppColors.primaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}