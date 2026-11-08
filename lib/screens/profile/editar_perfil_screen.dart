import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../models/perfil.dart';
import '../../providers/auth_provider.dart';
import '../../providers/perfil_provider.dart';
import '../../widgets/common/primary_button.dart';

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // Del dialogo de cambio de contrasena: viven en el State para que su
  // destruccion la gestione Flutter al desmontar la pantalla.
  final _passActualCtrl = TextEditingController();
  final _passNuevaCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  bool _iniciado = false;
  String? _distrito;
  File? _nuevaFotoFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passActualCtrl.dispose();
    _passNuevaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final provider = context.read<PerfilProvider>();
    final perfil = provider.perfil;
    if (!mounted) return;

    setState(() {
      if (perfil != null) {
        _nombreCtrl.text = perfil.nombre;
        _emailCtrl.text = perfil.email;
        _distrito = perfil.distrito;
      }
      _iniciado = true;
    });

    // La lista llega del backend: el distrito se valida contra ella y un
    // texto libre devuelve 400. Por eso es un selector y no un campo.
    await provider.cargarDistritos();
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<PerfilProvider>();
    final perfil = provider.perfil;
    if (perfil == null) return;

    if (_nuevaFotoFile != null) {
      final subidaOk = await provider.cambiarFoto(_nuevaFotoFile!);
      if (!subidaOk && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.error ?? 'No se pudo subir la foto',
              textAlign: TextAlign.center,
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final form = PerfilForm(
      nombre: _nombreCtrl.text.trim() == perfil.nombre
          ? null
          : _nombreCtrl.text.trim(),
      distrito: _distrito == perfil.distrito ? null : _distrito,
    );

    if (!form.vacio) {
      final ok = await provider.actualizar(form);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.error ??
                  'No se pudieron guardar los cambios. Inténtalo de nuevo',
              textAlign: TextAlign.center,
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final actualizado = provider.perfil;
    if (actualizado != null && mounted) {
      context.read<AuthProvider>().actualizarUsuario(actualizado.usuario);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      Navigator.pop(context, true);
    }
  }

  /// Los controladores del dialogo pertenecen al State, no al metodo.
  ///
  /// Creandolos y destruyendolos aqui dentro, el dispose ocurria mientras el
  /// dialogo aun salia de pantalla y sus campos de texto seguian montados:
  /// Flutter abortaba con "_dependents.isEmpty is not true" despues de que
  /// el backend ya habia respondido 204 y la contrasena si habia cambiado.
  /// Selector de distrito.
  ///
  /// El distrito decide el clima de referencia con el que el backend
  /// calcula el riego de todas las plantas, asi que cambiarlo los recalcula
  /// y esa peticion tarda algo mas de lo normal.
  Widget _selectorDistrito(bool isDark) {
    final distritos = context.watch<PerfilProvider>().distritos;

    if (distritos.isEmpty) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Distrito',
          prefixIcon: Icon(Icons.place_outlined),
        ),
        child: Text(
          _distrito ?? 'Cargando distritos...',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 14,
            color: AppColors.textTertiary,
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      // Si el distrito guardado no esta en la lista (porque cambio el
      // catalogo), se muestra vacio en vez de reventar.
      initialValue: distritos.contains(_distrito) ? _distrito : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Distrito',
        prefixIcon: const Icon(Icons.place_outlined),
        helperText: 'Define el clima con el que se calcula tu riego',
        helperStyle: TextStyle(
          fontSize: 11,
          color: isDark
              ? AppColors.darkTextTertiary
              : AppColors.textTertiary,
        ),
      ),
      hint: const Text('Elige tu distrito'),
      items: distritos
          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
          .toList(),
      onChanged: (valor) => setState(() => _distrito = valor),
    );
  }

  Future<void> _dialogoPassword() async {
    final actualCtrl = _passActualCtrl..clear();
    final nuevaCtrl = _passNuevaCtrl..clear();
    final formKeyDialog = GlobalKey<FormState>();

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
              key: formKeyDialog,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.12),
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
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
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
                    validator: (v) => (v ?? '').isEmpty
                        ? 'Ingresa tu contraseña actual'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nuevaCtrl,
                    obscureText: ocultarNueva,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
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
                            if (formKeyDialog.currentState!.validate()) {
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

    final passwordActual = actualCtrl.text;
    final passwordNueva = nuevaCtrl.text;

    if (ok != true || !mounted) return;

    final provider = context.read<PerfilProvider>();
    final exito = await provider.cambiarPassword(
      actual: passwordActual,
      nueva: passwordNueva,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          exito
              ? 'Contraseña actualizada correctamente'
              : provider.error ?? 'No se pudo cambiar',
          textAlign: TextAlign.center,
        ),
        backgroundColor: exito ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
    provider.limpiarError();
  }

  Future<void> _elegirFoto() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.primaryBg,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Cambiar foto de perfil',
                style: AppTextStyles.titleLarge.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt,
                    color: AppColors.primaryLight),
                title: Text(
                  'Tomar foto',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final XFile? foto = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 85,
                  );
                  if (foto != null) _abrirEditor(foto.path);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library,
                    color: AppColors.primaryLight),
                title: Text(
                  'Elegir de galería',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final XFile? foto = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (foto != null) _abrirEditor(foto.path);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirEditor(String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ImageEditorScreen(
          imagePath: imagePath,
          onSave: (croppedPath) {
            setState(() {
              _nuevaFotoFile = File(croppedPath);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<PerfilProvider>();

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Editar perfil',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: !_iniciado
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding:
        const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _avatarEditable(isDark, provider.perfil),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Toca para cambiar foto',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _nombreCtrl,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  labelText: 'Nombre de usuario',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? 'Ingresa tu nombre'
                    : null,
              ),
              const SizedBox(height: 18),

              TextFormField(
                controller: _emailCtrl,
                enabled: false,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextTertiary
                      : AppColors.textTertiary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: const Icon(Icons.mail_outline),
                  suffixIcon: const Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                  helperText:
                  'El correo de tu cuenta no se puede modificar',
                  helperStyle: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              _selectorDistrito(isDark),
              const SizedBox(height: 24),

              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF383838)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.primaryLight,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Cambiar contraseña',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Actualiza tu clave de acceso',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11.5,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : const Color(0xFFBDBDBD),
                  ),
                  onTap: _dialogoPassword,
                ),
              ),
              const SizedBox(height: 36),

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

  Widget _avatarEditable(bool isDark, Perfil? perfil) {
    return Center(
      child: GestureDetector(
        onTap: _elegirFoto,
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkPrimaryBg : AppColors.primaryBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryLight, width: 3),
              ),
              child: _buildAvatarPreview(perfil),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    width: 3,
                  ),
                ),
                child: const Icon(Icons.camera_alt,
                    size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPreview(Perfil? perfil) {
    if (_nuevaFotoFile != null) {
      return ClipOval(
        child: Image.file(
          _nuevaFotoFile!,
          fit: BoxFit.cover,
          width: 120,
          height: 120,
        ),
      );
    }

    if (perfil?.fotoUrl != null && perfil!.fotoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          perfil.fotoUrl!,
          fit: BoxFit.cover,
          width: 120,
          height: 120,
          errorBuilder: (_, __, ___) => _avatarIniciales(perfil),
        ),
      );
    }

    return _avatarIniciales(perfil);
  }

  Widget _avatarIniciales(Perfil? perfil) {
    return Center(
      child: Text(
        perfil?.iniciales ?? 'U',
        style: const TextStyle(
          fontSize: 44,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryLight,
        ),
      ),
    );
  }
}

class _ImageEditorScreen extends StatefulWidget {
  final String imagePath;
  final Function(String) onSave;

  const _ImageEditorScreen({
    required this.imagePath,
    required this.onSave,
  });

  @override
  State<_ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<_ImageEditorScreen> {
  final TransformationController _controller = TransformationController();
  final GlobalKey _repaintKey = GlobalKey();
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveEditedImage() async {
    setState(() => _isSaving = true);

    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('No se pudo capturar la imagen');
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) throw Exception('Error al procesar');

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'perfil_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      widget.onSave(file.path);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', textAlign: TextAlign.center),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final cropSize = screenSize.width * 0.75;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Ajustar foto',
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveEditedImage,
            child: _isSaving
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                valueColor:
                AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                strokeWidth: 2,
              ),
            )
                : const Text(
              'Listo',
              style: TextStyle(
                color: AppColors.primaryLight,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            'Pellizca para hacer zoom y arrastra para ajustar',
            style: TextStyle(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Opacity(
                      opacity: 0.35,
                      child: Image.file(
                        File(widget.imagePath),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                        const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: SizedBox(
                    width: cropSize,
                    height: cropSize,
                    child: RepaintBoundary(
                      key: _repaintKey,
                      child: ClipOval(
                        child: InteractiveViewer(
                          transformationController: _controller,
                          minScale: 1.0,
                          maxScale: 5.0,
                          boundaryMargin: EdgeInsets.zero,
                          constrained: true,
                          child: Image.file(
                            File(widget.imagePath),
                            fit: BoxFit.cover,
                            width: cropSize,
                            height: cropSize,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.black,
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.white,
                                  size: 60,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: IgnorePointer(
                    child: Container(
                      width: cropSize,
                      height: cropSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'La foto se mostrará en un círculo en tu perfil',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}