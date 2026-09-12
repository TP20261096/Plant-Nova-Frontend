import 'package:flutter/material.dart';
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
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

/// Menu Perfil. Fusiona el diseno visual anterior con los datos reales
/// del backend (PerfilProvider).
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
        title: const Text('Mi perfil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (widget.isEmbedded) ...[
            Text(
              'Mi perfil',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineMedium.copyWith(
                fontSize: 24,
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
          // ── Fila: avatar + info, con badge flotante a la derecha ──
          Stack(
            children: [
              // Contenido: avatar + nombre/email/distrito
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkPrimaryBg
                          : AppColors.primaryBg,
                      shape: BoxShape.circle,
                    ),
                    child: _buildAvatar(perfil, isDark),
                  ),
                  const SizedBox(width: 16),

                  // Nombre + email + distrito
                  Expanded(
                    child: Padding(
                      // Espacio a la derecha para que el texto no quede
                      // debajo del badge flotante
                      padding: const EdgeInsets.only(right: 105),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            perfil.nombre,
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
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

              // Badge flotante en la esquina superior derecha
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.primaryLight.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_florist,
                        color: AppColors.primaryLight,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${perfil.plantasRegistradas} '
                            '${perfil.plantasRegistradas == 1 ? "planta" : "plantas"}',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.primaryLight,
                          fontSize: 13,
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

          // ── Botón "Editar perfil" ──
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

          // Aviso de distrito faltante
          if (!perfil.tieneDistrito) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
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
                      'Elige tu distrito para ver dónde comprar los insumos '
                          'de los tratamientos cerca de ti.',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
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
  /// Avatar: foto del backend si existe, sino iniciales.
  Widget _buildAvatar(Perfil perfil, bool isDark) {
    // Aquí necesitas cargar la foto local
    // Pero como build es síncrono, lo mejor es:

    // Opción A: Cargarla en el provider
    // Opción B: Usar un FutureBuilder
    // Opción C: Pasarla desde el Provider

    // Por ahora, si el perfil tiene fotoUrl, la usa:
    if (perfil.fotoUrl != null && perfil.fotoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          perfil.fotoUrl!,
          fit: BoxFit.cover,
          width: 70,
          height: 70,
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
        style: const TextStyle(
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
        Text(
          'Opciones',
          style: AppTextStyles.titleLarge.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        _item(
          isDark,
          icono: Icons.lock_outline,
          titulo: 'Cambiar contraseña',
          subtitulo: 'Necesitas tu contraseña actual',
          onTap: _dialogoPassword,
        ),
        _item(
          isDark,
          icono: Icons.settings_outlined,
          titulo: 'Configuración',
          subtitulo: 'Apariencia de la aplicación',
          onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
        ),

        const SizedBox(height: 12),

        _item(
          isDark,
          icono: Icons.logout,
          titulo: 'Cerrar sesión',
          color: AppColors.textSecondary,
          onTap: _cerrarSesion,
        ),
        _item(
          isDark,
          icono: Icons.delete_forever_outlined,
          titulo: 'Eliminar cuenta',
          subtitulo: 'Borra todo de forma permanente',
          color: AppColors.error,
          onTap: _dialogoEliminar,
        ),
      ],
    );
  }

  Widget _item(
      bool isDark, {
        required IconData icono,
        required String titulo,
        String? subtitulo,
        Color? color,
        required VoidCallback onTap,
      }) {
    final tituloColor =
        color ?? (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary);

    return Card(
      color: isDark ? AppColors.darkSurface : AppColors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isDark ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icono, color: color ?? AppColors.primaryLight),
        title: Text(
          titulo,
          style: AppTextStyles.titleMedium.copyWith(
            fontSize: 14,
            color: tituloColor,
          ),
        ),
        subtitle: subtitulo == null
            ? null
            : Text(
          subtitulo,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 11,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          size: 20,
          color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
        ),
        onTap: onTap,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ACCIONES
  // ═══════════════════════════════════════════════════════════

  Future<void> _cerrarSesion() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Quieres salir de tu cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text(
              'Salir',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;
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

    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: const Text('Cambiar contraseña'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: actualCtrl,
                obscureText: true,
                decoration:
                const InputDecoration(labelText: 'Contraseña actual'),
                validator: (v) => (v ?? '').isEmpty ? 'Ingrésala' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nuevaCtrl,
                obscureText: true,
                decoration:
                const InputDecoration(labelText: 'Contraseña nueva'),
                validator: (v) {
                  final texto = v ?? '';
                  if (texto.length < 8) return 'Mínimo 8 caracteres';
                  if (texto == actualCtrl.text) {
                    return 'Debe ser distinta a la actual';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(d, true);
            },
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) {
      actualCtrl.dispose();
      nuevaCtrl.dispose();
      return;
    }

    final provider = context.read<PerfilProvider>();
    final exito = await provider.cambiarPassword(
      actual: actualCtrl.text,
      nueva: nuevaCtrl.text,
    );
    actualCtrl.dispose();
    nuevaCtrl.dispose();

    if (!mounted) return;
    _avisar(
      exito
          ? 'Contraseña actualizada'
          : provider.error ?? 'No se pudo cambiar',
      error: !exito,
    );
    provider.limpiarError();
  }

  Future<void> _dialogoEliminar() async {
    final ctrl = TextEditingController();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text('Eliminar cuenta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Se borrarán tu cuenta, tus plantas, sus diagnósticos, las '
                    'actividades y las fotos. No se puede deshacer.',
              ),
              const SizedBox(height: 14),
              const Text(
                'Escribe ELIMINAR para confirmar:',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: ctrl,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) => setStateDialog(() {}),
                decoration: const InputDecoration(hintText: 'ELIMINAR'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: ctrl.text.trim().toUpperCase() == 'ELIMINAR'
                  ? () => Navigator.pop(d, true)
                  : null,
              child: const Text(
                'Eliminar',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );

    ctrl.dispose();
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