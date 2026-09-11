import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../models/perfil.dart';
import '../../providers/auth_provider.dart';
import '../../providers/perfil_provider.dart';
import '../../widgets/common/primary_button.dart';

/// PATCH /profile
///
/// Reemplaza a EditProfileScreen, que guardaba nombre, descripcion y foto en
/// SharedPreferences. De esos campos, el backend solo conoce el nombre; la
/// descripcion no existe en el contrato, asi que desaparece.
class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({Key? key}) : super(key: key);

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();

  String? _distrito;
  bool _notificaciones = true;
  bool _iniciado = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PerfilProvider>();
      provider.cargarDistritos();

      final perfil = provider.perfil;
      if (perfil != null) {
        setState(() {
          _nombreCtrl.text = perfil.nombre;
          _distrito = perfil.distrito;
          _notificaciones = perfil.notificaciones;
          _iniciado = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<PerfilProvider>();
    final perfil = provider.perfil;
    if (perfil == null) return;

    // Solo lo que cambio: PATCH admite campos parciales y mandar el objeto
    // entero obligaria al backend a revalidar cosas que nadie toco.
    final form = PerfilForm(
      nombre: _nombreCtrl.text.trim() == perfil.nombre
          ? null
          : _nombreCtrl.text.trim(),
      distrito: _distrito == perfil.distrito ? null : _distrito,
      notificaciones:
      _notificaciones == perfil.notificaciones ? null : _notificaciones,
    );

    if (form.vacio) {
      Navigator.pop(context);
      return;
    }

    final ok = await provider.actualizar(form);
    if (!mounted) return;

    if (ok) {
      // El saludo del inicio y la barra superior leen del usuario
      // autenticado, no del perfil: hay que sincronizarlo.
      final actualizado = provider.perfil;
      if (actualizado != null) {
        context.read<AuthProvider>().actualizarUsuario(actualizado.usuario);
      }
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'No se pudo guardar'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      provider.limpiarError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<PerfilProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Editar perfil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: !_iniciado
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? 'Ingresa tu nombre'
                    : null,
              ),
              const SizedBox(height: 20),
              _selectorDistrito(provider),
              const SizedBox(height: 20),
              SwitchListTile(
                value: _notificaciones,
                onChanged: (v) => setState(() => _notificaciones = v),
                title: const Text('Notificaciones'),
                subtitle: Text(
                  'Avisos de riego y tratamientos',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                ),
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                text: 'Guardar cambios',
                isLoading: provider.guardando,
                onPressed: _guardar,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _selectorDistrito(PerfilProvider provider) {
    final distritos = provider.distritos;

    if (distritos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline,
                size: 18, color: AppColors.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No se pudo cargar la lista de distritos. Inténtalo más tarde.',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: distritos.contains(_distrito) ? _distrito : null,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Distrito',
            prefixIcon: Icon(Icons.place_outlined),
          ),
          hint: const Text('Elige tu distrito'),
          items: distritos
              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
              .toList(),
          onChanged: (v) => setState(() => _distrito = v),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Se usa para mostrarte dónde comprar los insumos de los '
                'tratamientos cerca de ti.',
            style: AppTextStyles.bodySmall
                .copyWith(fontSize: 11, color: AppColors.textTertiary),
          ),
        ),
      ],
    );
  }
}