import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _language = 'Español';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _language = prefs.getString('language') ?? 'Español';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Configuración',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _seccionTitulo('PREFERENCIAS', isDark),
          const SizedBox(height: 10),

          // Box 1: Notificaciones
          _boxContenedor(
            isDark: isDark,
            child: _filaSwitch(
              isDark: isDark,
              icono: Icons.notifications_outlined,
              colorIcono: const Color(0xFF43A047),
              titulo: 'Notificaciones',
              subtitulo: 'Recibir recordatorios de cuidado',
              valor: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                _saveSetting('notifications_enabled', value);
              },
            ),
          ),

          const SizedBox(height: 10),

          // Box 2: Tema dinámico (cambia título y subtítulo según el estado)
          _boxContenedor(
            isDark: isDark,
            child: _filaSwitch(
              isDark: isDark,
              icono: themeProvider.isDarkMode
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
              colorIcono: const Color(0xFFE5A000),
              titulo: themeProvider.isDarkMode ? 'Modo oscuro' : 'Modo claro',
              subtitulo: themeProvider.isDarkMode
                  ? 'Apariencia oscura activada'
                  : 'Apariencia clara activada',
              valor: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.setDarkMode(value);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value ? 'Tema oscuro activado' : 'Tema claro activado',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
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
              },
            ),
          ),

          const SizedBox(height: 10),

          // Box 3: Idioma
          _boxContenedor(
            isDark: isDark,
            child: _filaNavegacion(
              isDark: isDark,
              icono: Icons.language_outlined,
              colorIcono: const Color(0xFF29B6F6),
              titulo: 'Idioma',
              subtitulo: _language,
              onTap: () => _showLanguageDialog(isDark),
            ),
          ),

          const SizedBox(height: 24),

          _seccionTitulo('INFORMACIÓN', isDark),
          const SizedBox(height: 10),

          // Box 4: Privacidad
          _boxContenedor(
            isDark: isDark,
            child: _filaNavegacion(
              isDark: isDark,
              icono: Icons.shield_outlined,
              colorIcono: AppColors.primaryLight,
              titulo: 'Privacidad',
              subtitulo: 'Política de privacidad y datos',
              onTap: () => _showPrivacyDialog(isDark),
            ),
          ),

          const SizedBox(height: 10),

          // Box 5: Acerca de
          _boxContenedor(
            isDark: isDark,
            child: _filaNavegacion(
              isDark: isDark,
              icono: Icons.info_outline_rounded,
              colorIcono: const Color(0xFF7E57C2),
              titulo: 'Acerca de PlantNova',
              subtitulo: 'Versión 1.0.0',
              onTap: () => _showAboutDialog(isDark),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ESTRUCTURA VISUAL EN BOXES
  // ═══════════════════════════════════════════════════════════

  Widget _seccionTitulo(String titulo, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        titulo,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _boxContenedor({required bool isDark, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.035),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }

  Widget _filaSwitch({
    required bool isDark,
    required IconData icono,
    required Color colorIcono,
    required String titulo,
    required String subtitulo,
    required bool valor,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colorIcono.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: colorIcono, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11.5,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: valor,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: isDark ? const Color(0xFFB0B0B0) : Colors.white,
            inactiveTrackColor:
            isDark ? const Color(0xFF4A4A4A) : const Color(0xFFE0E0E0),
          ),
        ],
      ),
    );
  }

  Widget _filaNavegacion({
    required bool isDark,
    required IconData icono,
    required Color colorIcono,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorIcono.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: colorIcono, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : const Color(0xFFC0C0C0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MODALES ESTILIZADOS
  // ═══════════════════════════════════════════════════════════

  void _showLanguageDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF29B6F6).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.language_rounded,
                color: Color(0xFF29B6F6),
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Seleccionar idioma',
              style: AppTextStyles.titleMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Elige el idioma principal para toda la aplicación.',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 12.5,
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            _opcionIdiomaItem(
              titulo: 'Español',
              subtitulo: 'Predeterminado',
              bandera: '🇪🇸',
              seleccionado: _language == 'Español',
              isDark: isDark,
              onTap: () {
                setState(() => _language = 'Español');
                _saveSetting('language', 'Español');
                Navigator.of(dialogCtx).pop();
              },
            ),
            const SizedBox(height: 10),
            _opcionIdiomaItem(
              titulo: 'English',
              subtitulo: 'Inglés',
              bandera: '🇺🇸',
              seleccionado: _language == 'English',
              isDark: isDark,
              onTap: () {
                setState(() => _language = 'English');
                _saveSetting('language', 'English');
                Navigator.of(dialogCtx).pop();
              },
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color: isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _opcionIdiomaItem({
    required String titulo,
    required String subtitulo,
    required String bandera,
    required bool seleccionado,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final borderColor = seleccionado
        ? AppColors.primaryLight
        : (isDark ? const Color(0xFF333333) : const Color(0xFFE8E8E8));

    final bgColor = seleccionado
        ? AppColors.primaryLight.withOpacity(isDark ? 0.12 : 0.08)
        : (isDark ? AppColors.darkBackground : const Color(0xFFF9F9F9));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: seleccionado ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : const Color(0xFFEEEEEE),
                  ),
                ),
                child: Text(
                  bandera,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: seleccionado ? FontWeight.bold : FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: seleccionado ? AppColors.primaryLight : Colors.transparent,
                  border: Border.all(
                    color: seleccionado
                        ? AppColors.primaryLight
                        : (isDark ? const Color(0xFF666666) : const Color(0xFFBDBDBD)),
                    width: 1.5,
                  ),
                ),
                child: seleccionado
                    ? const Icon(
                  Icons.check,
                  size: 14,
                  color: Colors.white,
                )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: AppColors.primaryLight,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Privacidad',
              style: AppTextStyles.titleMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'PlantNova respeta tu privacidad. Las imágenes que subes se utilizan únicamente para el diagnóstico de tus cultivos y no se comparten con terceros.',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                height: 1.4,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Entendido',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF7E57C2).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF7E57C2),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Acerca de PlantNova',
              style: AppTextStyles.titleMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Versión 1.0.0',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'PlantNova es una aplicación diseñada para ayudarte a cuidar tus cultivos de manera natural y efectiva.',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                height: 1.4,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}