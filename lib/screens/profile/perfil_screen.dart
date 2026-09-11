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

/// Menu Perfil. Reemplaza a ProfileScreen, que leia nombre, descripcion y
/// foto de SharedPreferences y contaba las plantas desde la lista local.
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
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
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
                color:
                isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
          ],
          _datos(perfil, isDark),
          const SizedBox(height: 20),
          _opciones(perfil, isDark),
        ],
      ),
    );
  }

  Widget _datos(Perfil perfil, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Sin subida de foto: las iniciales sobre el color de marca son
          // suficientes y evitan un endpoint mas.
          CircleAvatar(
            radius: 38,
            backgroundColor: AppColors.primary,
            child: Text(
              perfil.iniciales,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(perfil.nombre, style: AppTextStyles.titleLarge),
          const SizedBox(height: 2),
          Text(
            perfil.email,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _dato(
                Icons.local_florist,
                '${perfil.plantasRegistradas}',
                perfil.plantasRegistradas == 1 ? 'planta' : 'plantas',
              ),
              _dato(
                Icons.place_outlined,
                perfil.distrito ?? 'Sin definir',
                'distrito',
              ),
            ],
          ),
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
                  const Icon(Icons.info_outline,
                      size: 18, color: AppColors.warning),
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

  Widget _dato(IconData icono, String valor, String etiqueta) {
    return Column(
      children: [
        Icon(icono, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          valor,
          style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          etiqueta,
          style: AppTextStyles.bodySmall
              .copyWith(fontSize: 11, color: AppColors.textTertiary),
        ),
      ],
    );
  }

  Widget _opciones(Perfil perfil, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Opciones', style: AppTextStyles.titleLarge),
        const SizedBox(height: 12),
        _item(
          isDark,
          icono: Icons.edit_outlined,
          titulo: 'Editar perfil',
          subtitulo: 'Nombre, distrito y notificaciones',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditarPerfilScreen()),
          ),
        ),
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
    final tono = color ??
        (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icono, color: color ?? AppColors.primary),
        title: Text(titulo,
            style: AppTextStyles.titleMedium
                .copyWith(fontSize: 14, color: tono)),
        subtitle: subtitulo == null
            ? null
            : Text(subtitulo,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }

  // ------------------------------------------------------------ acciones

  /// Cerrar sesion tiene que vaciar los providers, o la siguiente cuenta que
  /// entre en este telefono vera por un instante el jardin de la anterior.
  Future<void> _cerrarSesion() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Quieres salir de tu cuenta?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(d, true),
              child: const Text('Salir')),
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
                validator: (v) =>
                (v ?? '').isEmpty ? 'Ingrésala' : null,
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
              child: const Text('Cancelar')),
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

  /// Se pide escribir ELIMINAR a proposito: es irreversible y borra plantas,
  /// diagnosticos, actividades e imagenes. Un boton suelto no basta.
  Future<void> _dialogoEliminar() async {
    final ctrl = TextEditingController();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
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
              const Text('Escribe ELIMINAR para confirmar:',
                  style: TextStyle(fontSize: 12)),
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
                child: const Text('Cancelar')),
            TextButton(
              onPressed: ctrl.text.trim().toUpperCase() == 'ELIMINAR'
                  ? () => Navigator.pop(d, true)
                  : null,
              child: const Text('Eliminar',
                  style: TextStyle(color: AppColors.error)),
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
          content: Text(mensaje),
          backgroundColor: error ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}