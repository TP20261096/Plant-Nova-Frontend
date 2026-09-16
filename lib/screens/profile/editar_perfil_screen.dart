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
  const EditarPerfilScreen({Key? key}) : super(key: key);

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _distrito;
  bool _notificaciones = true;
  bool _iniciado = false;
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
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    final provider = context.read<PerfilProvider>();
    await provider.cargarDistritos();

    final perfil = provider.perfil;
    if (!mounted) return;

    setState(() {
      if (perfil != null) {
        _nombreCtrl.text = perfil.nombre;
        _distrito = perfil.distrito;
        _notificaciones = perfil.notificaciones;
      }
      _iniciado = true;
    });
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<PerfilProvider>();
    final perfil = provider.perfil;
    if (perfil == null) return;

    // 1. Si el usuario seleccionó o recortó una nueva foto, se sube al backend
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

    // 2. Modificación de campos de texto
    final form = PerfilForm(
      nombre: _nombreCtrl.text.trim() == perfil.nombre
          ? null
          : _nombreCtrl.text.trim(),
      distrito: _distrito == perfil.distrito ? null : _distrito,
      notificaciones:
      _notificaciones == perfil.notificaciones ? null : _notificaciones,
    );

    if (!form.vacio) {
      final ok = await provider.actualizar(form);
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.error ?? 'No se pudieron guardar los cambios',
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
      Navigator.pop(context, true);
    }
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
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primaryLight),
                title: Text(
                  'Tomar foto',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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
                leading: const Icon(Icons.photo_library, color: AppColors.primaryLight),
                title: Text(
                  'Elegir de galería',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
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
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Editar perfil',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
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
              const SizedBox(height: 28),
              TextFormField(
                controller: _nombreCtrl,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => (v ?? '').trim().isEmpty
                    ? 'Ingresa tu nombre'
                    : null,
              ),
              const SizedBox(height: 20),
              _selectorDistrito(provider, isDark),
              const SizedBox(height: 20),
              SwitchListTile(
                value: _notificaciones,
                onChanged: (v) => setState(() => _notificaciones = v),
                title: Text(
                  'Notificaciones',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Avisos de riego y tratamientos',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primaryLight,
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
                child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
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

  Widget _selectorDistrito(PerfilProvider provider, bool isDark) {
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
            const Icon(Icons.info_outline, size: 18, color: AppColors.warning),
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
          dropdownColor: isDark ? AppColors.darkSurface : AppColors.surface,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            fontSize: 14,
          ),
          decoration: const InputDecoration(
            labelText: 'Distrito',
            prefixIcon: Icon(Icons.place_outlined),
          ),
          hint: const Text('Elige tu distrito'),
          items: distritos.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: (v) => setState(() => _distrito = v),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Se usa para mostrarte dónde comprar los insumos de los tratamientos cerca de ti.',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// EDITOR DE IMAGEN CIRCULAR (zoom + recorte)
// ═══════════════════════════════════════════════════════════

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
        title: const Text('Ajustar foto', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveEditedImage,
            child: _isSaving
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
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
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
                color: Colors.white.withOpacity(0.7),
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