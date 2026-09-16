import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../models/perfil.dart';
import '../../providers/actividad_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/diagnostico_provider.dart';
import '../../providers/perfil_provider.dart';
import '../../providers/planta_provider.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';
import 'editar_perfil_screen.dart';

/// Menú Perfil. Conecta los datos de PerfilProvider con un diseño
/// limpio y tipografía homogénea basada en AppTextStyles.
class PerfilScreen extends StatefulWidget {
  final bool isEmbedded;

  const PerfilScreen({Key? key, this.isEmbedded = false}) : super(key: key);

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PerfilProvider>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<PerfilProvider>();

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.background,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
        title: Text(
          'Mi perfil',
          style: AppTextStyles.titleMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(child: _cuerpo(provider, isDark)),
    );
  }

  Widget _cuerpo(PerfilProvider provider, bool isDark) {
    if (provider.cargando && provider.perfil == null) {
      return const LoadingView(message: 'Cargando tu perfil...');
    }

    if (provider.error != null && provider.perfil == null) {
      return ErrorView(
        message: provider.error!,
        onRetry: () => provider.cargar(),
      );
    }

    final perfil = provider.perfil;
    if (perfil == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: () => provider.cargar(silencioso: true),
      color: AppColors.primaryLight,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (widget.isEmbedded) ...[
            Text(
              'Mi perfil',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
          ],
          _datos(perfil, isDark),
          const SizedBox(height: 24),
          _opciones(perfil, isDark),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TARJETA DE DATOS DEL USUARIO
  // ═══════════════════════════════════════════════════════════
  Widget _datos(Perfil perfil, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkPrimaryBg
                          : AppColors.primaryBg,
                      shape: BoxShape.circle,
                    ),
                    child: _buildAvatar(perfil, isDark),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            perfil.nombre,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            perfil.email,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (perfil.tieneDistrito) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.place_outlined,
                                  size: 14,
                                  color: AppColors.primaryLight,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    perfil.distrito!,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.primaryLight,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryLight.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.eco_rounded,
                        color: AppColors.primaryLight,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${perfil.plantasRegistradas} '
                            '${perfil.plantasRegistradas == 1 ? "planta" : "plantas"}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primaryLight,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EditarPerfilScreen(),
                  ),
                );
                if (result == true && mounted) {
                  await context
                      .read<PerfilProvider>()
                      .cargar(silencioso: true);
                }
              },
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(
                'Editar perfil',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryLight,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
                side: BorderSide(
                  color: AppColors.primaryLight.withOpacity(0.4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (!perfil.tieneDistrito) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Elige tu distrito para ver dónde comprar los insumos de los tratamientos cerca de ti.',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 12,
                        height: 1.35,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(Perfil perfil, bool isDark) {
    if (perfil.fotoUrl != null && perfil.fotoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          perfil.fotoUrl!,
          fit: BoxFit.cover,
          width: 68,
          height: 68,
          errorBuilder: (_, __, ___) => _avatarIniciales(perfil),
        ),
      );
    }
    return _avatarIniciales(perfil);
  }

  Widget _avatarIniciales(Perfil perfil) {
    return Center(
      child: Text(
        perfil.iniciales,
        style: AppTextStyles.headlineMedium.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryLight,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // OPCIONES INDIVIDUALES EN BOXES
  // ═══════════════════════════════════════════════════════════
  Widget _opciones(Perfil perfil, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'CUENTAS Y PREFERENCIAS',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
            ),
          ),
        ),
        const SizedBox(height: 10),

        _boxOpcionIndividual(
          isDark: isDark,
          icono: Icons.lock_outline_rounded,
          colorIcono: AppColors.primaryLight,
          titulo: 'Cambiar contraseña',
          subtitulo: 'Actualiza tu clave de acceso',
          onTap: _dialogoPassword,
        ),
        const SizedBox(height: 10),
        _boxOpcionIndividual(
          isDark: isDark,
          icono: Icons.settings_outlined,
          colorIcono: const Color(0xFF43A047),
          titulo: 'Configuración',
          subtitulo: 'Apariencia y tema visual',
          onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
        ),
        const SizedBox(height: 10),
        _boxOpcionIndividual(
          isDark: isDark,
          icono: Icons.logout_rounded,
          colorIcono: const Color(0xFF5C6AC4),
          titulo: 'Cerrar sesión',
          subtitulo: 'Salir de este dispositivo',
          onTap: _cerrarSesion,
        ),
        const SizedBox(height: 10),
        _boxOpcionIndividual(
          isDark: isDark,
          icono: Icons.delete_outline_rounded,
          colorIcono: AppColors.error,
          colorTexto: AppColors.error,
          titulo: 'Eliminar cuenta',
          subtitulo: 'Borrado permanente e irreversible',
          onTap: _dialogoEliminar,
        ),
      ],
    );
  }

  Widget _boxOpcionIndividual({
    required bool isDark,
    required IconData icono,
    required Color colorIcono,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
    Color? colorTexto,
  }) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
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
                          color: colorTexto ??
                              (isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitulo,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 12,
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
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ACCIONES Y DIÁLOGOS ESTILIZADOS
  // ═══════════════════════════════════════════════════════════

  Future<void> _cerrarSesion() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;

        return AlertDialog(
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
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Cerrar sesión',
                style: AppTextStyles.titleMedium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '¿Estás seguro de que deseas salir de tu cuenta?',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF424242)
                              : const Color(0xFFE0E0E0),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Salir',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmado != true || !mounted) return;
    HapticFeedback.lightImpact();
    await _salir();
  }

  Future<void> _salir() async {
    context.read<PlantaProvider>().limpiar();
    context.read<ActividadProvider>().limpiar();
    context.read<DiagnosticoProvider>().limpiar();
    context.read<PerfilProvider>().limpiar();
    await context.read<AuthProvider>().cerrarSesion();

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  Future<void> _dialogoPassword() async {
    final actualCtrl = TextEditingController();
    final nuevaCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool ocultarActual = true;
    bool ocultarNueva = true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          final isDark = Theme.of(dialogCtx).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: AppColors.primaryLight,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cambiar contraseña',
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
                  Text(
                    'Ingresa tu contraseña actual y define una nueva de al menos 8 caracteres.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 12.5,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: actualCtrl,
                    obscureText: ocultarActual,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Contraseña actual',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          ocultarActual
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () => setStateDialog(
                                () => ocultarActual = !ocultarActual),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkBackground
                          : const Color(0xFFF7F7F7),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF383838)
                              : const Color(0xFFE0E0E0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primaryLight,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (v) =>
                    (v ?? '').isEmpty ? 'Ingresa tu contraseña actual' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nuevaCtrl,
                    obscureText: ocultarNueva,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Contraseña nueva',
                      prefixIcon: const Icon(Icons.key_outlined, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          ocultarNueva
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                        ),
                        onPressed: () => setStateDialog(
                                () => ocultarNueva = !ocultarNueva),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkBackground
                          : const Color(0xFFF7F7F7),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF383838)
                              : const Color(0xFFE0E0E0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primaryLight,
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (v) {
                      final texto = v ?? '';
                      if (texto.length < 8) return 'Mínimo 8 caracteres';
                      if (texto == actualCtrl.text) {
                        return 'Debe ser distinta a la actual';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF424242)
                                  : const Color(0xFFE0E0E0),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              Navigator.of(dialogCtx).pop(true);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Actualizar',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    actualCtrl.dispose();
    nuevaCtrl.dispose();

    if (ok != true || !mounted) return;

    final provider = context.read<PerfilProvider>();
    final exito = await provider.cambiarPassword(
      actual: actualCtrl.text,
      nueva: nuevaCtrl.text,
    );

    if (!mounted) return;
    _avisar(
      exito
          ? 'Contraseña actualizada correctamente'
          : provider.error ?? 'No se pudo cambiar',
      error: !exito,
    );
    provider.limpiarError();
  }

  Future<void> _dialogoEliminar() async {
    // 1. Obtenemos el tema usando el contexto de la pantalla antes de abrir el modal
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        // 2. El controller vive dentro del builder para eliminarse cuando el modal realmente desaparece
        final ctrl = TextEditingController();

        return StatefulBuilder(
          builder: (builderCtx, setStateDialog) {
            final puedeEliminar = ctrl.text.trim().toUpperCase() == 'ELIMINAR';

            return AlertDialog(
              backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.error,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Eliminar cuenta',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Se borrarán tu cuenta, tus plantas, sus diagnósticos, actividades y fotos de forma permanente.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 12.5,
                      height: 1.4,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Escribe ELIMINAR para confirmar:',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: ctrl,
                    textCapitalization: TextCapitalization.characters,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                    onChanged: (_) => setStateDialog(() {}),
                    decoration: InputDecoration(
                      hintText: 'ELIMINAR',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: isDark
                            ? const Color(0xFF555555)
                            : const Color(0xFFBDBDBD),
                        letterSpacing: 1.5,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.darkBackground
                          : const Color(0xFFF7F7F7),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF383838)
                              : const Color(0xFFE0E0E0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.error,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            FocusScope.of(dialogCtx).unfocus();
                            Navigator.of(dialogCtx).pop(false);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0xFF424242)
                                  : const Color(0xFFE0E0E0),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: puedeEliminar
                              ? () {
                            FocusScope.of(dialogCtx).unfocus();
                            Navigator.of(dialogCtx).pop(true);
                          }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            disabledBackgroundColor: isDark
                                ? const Color(0xFF333333)
                                : const Color(0xFFE5E5E5),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: isDark
                                ? const Color(0xFF666666)
                                : const Color(0xFFAAAAAA),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Eliminar',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (confirmado != true || !mounted) return;

    final provider = context.read<PerfilProvider>();
    final ok = await provider.eliminarCuenta();

    if (!mounted) return;
    if (ok) {
      await _salir();
    } else {
      _avisar(provider.error ?? 'No se pudo eliminar la cuenta', error: true);
      provider.limpiarError();
    }
  }

  void _avisar(String mensaje, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            mensaje,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
          backgroundColor: error ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }
}