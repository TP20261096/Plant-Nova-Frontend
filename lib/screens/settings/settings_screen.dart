import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../models/enums.dart';
import '../../models/perfil.dart';
import '../../providers/perfil_provider.dart';
import '../../providers/theme_provider.dart';
import '../legal/terminos_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// El perfil del backend manda sobre la copia local: es lo que mantiene
  /// las preferencias si el usuario entra desde otro telefono. La copia en
  /// el dispositivo solo sirve para no parpadear mientras llega.
  Future<void> _loadSettings() async {
    // El perfil se lee antes del await: despues, el context podria ya no
    // ser valido si el usuario salio de la pantalla.
    final perfil = context.read<PerfilProvider>().perfil;
    final themeProvider = context.read<ThemeProvider>();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = perfil?.notificaciones ??
          (prefs.getBool('notifications_enabled') ?? true);
    });

    // El tema guardado en el perfil manda sobre el del dispositivo, salvo
    // que el usuario lo tenga en automatico.
    if (perfil != null && perfil.tema != Tema.sistema) {
      final oscuroEnServidor = perfil.tema == Tema.oscuro;
      if (themeProvider.isDarkMode != oscuroEnServidor) {
        themeProvider.setDarkMode(oscuroEnServidor);
      }
    }
  }

  /// Guarda la preferencia en el backend y, si falla, revierte el control
  /// para no mostrar un estado que el servidor no tiene.
  Future<void> _guardarEnPerfil(PerfilForm form, VoidCallback revertir) async {
    final provider = context.read<PerfilProvider>();
    final ok = await provider.actualizar(form);
    if (ok || !mounted) return;

    setState(revertir);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            provider.error ?? 'No se pudo guardar la preferencia',
            textAlign: TextAlign.center,
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    provider.limpiarError();
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
                _guardarEnPerfil(
                  PerfilForm(notificaciones: value),
                  () => _notificationsEnabled = !value,
                );
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
                // El tema tambien vive en el perfil (PATCH /profile), para
                // que acompane al usuario entre dispositivos.
                _guardarEnPerfil(
                  PerfilForm(tema: value ? Tema.oscuro : Tema.claro),
                  () => themeProvider.setDarkMode(!value),
                );

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

          const SizedBox(height: 24),

          _seccionTitulo('INFORMACIÓN', isDark),
          const SizedBox(height: 10),

          // Box 3: Privacidad
          _boxContenedor(
            isDark: isDark,
            child: _filaNavegacion(
              isDark: isDark,
              icono: Icons.shield_outlined,
              colorIcono: AppColors.primaryLight,
              titulo: 'Privacidad',
              subtitulo: 'Términos, datos y permisos',
              // El mismo texto que se acepta al registrarse: un solo sitio
              // que mantener cuando cambie lo que la app hace con los datos.
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TerminosScreen()),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Box 4: Acerca de
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
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.035),
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
              color: colorIcono.withValues(alpha: 0.12),
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
            activeThumbColor: Colors.white,
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
                  color: colorIcono.withValues(alpha: 0.12),
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
                color: const Color(0xFF7E57C2).withValues(alpha: 0.12),
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