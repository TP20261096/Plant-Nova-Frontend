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

/// Menú Perfil con tarjeta estilo perfil social (Instagram layout) y opciones de cuenta.
class PerfilScreen extends StatefulWidget {
  final bool isEmbedded;

  const PerfilScreen({super.key, this.isEmbedded = false});

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
            color:
            isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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
  // TARJETA PRINCIPAL (LAYOUT TIPO INSTAGRAM)
  // ═══════════════════════════════════════════════════════════
  Widget _datos(Perfil perfil, bool isDark) {
    // Los tres contadores los calcula el backend y llegan en GET /profile
    // (HU004). Antes se deducian en el cliente con reflexion sobre campos
    // inexistentes y, cuando fallaba, se asumian dos diagnosticos por
    // planta: lo que veia el usuario no correspondia con sus datos.
    final totalPlantas = perfil.plantasRegistradas;
    final totalDiagnosticos = perfil.diagnosticosRealizados;
    final totalTareas = perfil.tareasPendientes;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryLight,
                        width: 2,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkPrimaryBg
                            : AppColors.primaryBg,
                        shape: BoxShape.circle,
                      ),
                      child: _buildAvatar(perfil, isDark),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 110),
                          child: Text(
                            perfil.nombre,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInstagramStat(
                                '$totalPlantas', 'plantas', isDark),
                            _buildInstagramStat(
                                '$totalDiagnosticos', 'diagnósticos', isDark),
                            _buildInstagramStat(
                                '$totalTareas', 'tareas', isDark),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: AppColors.primaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'cuenta activa',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primaryLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
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
                  color: AppColors.primaryLight.withValues(alpha: 0.4),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
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

  Widget _buildInstagramStat(String valor, String etiqueta, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          valor,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          etiqueta,
          style: TextStyle(
            fontSize: 11.5,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(Perfil perfil, bool isDark) {
    if (perfil.fotoUrl != null && perfil.fotoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          perfil.fotoUrl!,
          fit: BoxFit.cover,
          width: 72,
          height: 72,
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
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryLight,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // OPCIONES
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
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.035),
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
  // ACCIONES Y DIÁLOGOS
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
                  color: AppColors.error.withValues(alpha: 0.1),
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

  Future<void> _dialogoEliminar() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
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
                      color: AppColors.error.withValues(alpha: 0.12),
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