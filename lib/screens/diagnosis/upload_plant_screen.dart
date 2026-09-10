import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/routes.dart';
import '../../providers/diagnosis_provider.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/secondary_button.dart';

class UploadPlantScreen extends StatefulWidget {
  final bool isEmbedded;

  const UploadPlantScreen({
    Key? key,
    this.isEmbedded = false,
  }) : super(key: key);

  @override
  State<UploadPlantScreen> createState() => _UploadPlantScreenState();
}

class _UploadPlantScreenState extends State<UploadPlantScreen> {
  final ImagePicker _picker = ImagePicker();
  String? _imagePath;
  bool _isLoading = false;
  String? _plantId; // ← ID de la planta si viene del jardín

  @override
  void initState() {
    super.initState();
    // Obtener el ID de la planta de los argumentos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map) {
        _plantId = args['plantId'] as String?;
        if (_plantId != null) {
          context.read<DiagnosisProvider>().setPlantId(_plantId);
        } else {
          context.read<DiagnosisProvider>().clearPlantId();
        }
      } else {
        // Si no hay argumentos, limpiar el plantId
        context.read<DiagnosisProvider>().clearPlantId();
      }
    });
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() {
          _imagePath = photo.path;
        });
      }
    } catch (e) {
      _showError('No se pudo acceder a la cámara');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
      }
    } catch (e) {
      _showError('No se pudo acceder a la galería');
    }
  }

  void _removeImage() {
    setState(() {
      _imagePath = null;
    });
  }

  void _analyzePlant() {
    if (_imagePath == null) {
      _showError('Por favor selecciona una imagen primero');
      return;
    }

    context.read<DiagnosisProvider>().setSelectedImage(_imagePath);

    // Si viene del jardín, pasar el ID de la planta
    if (_plantId != null) {
      context.read<DiagnosisProvider>().setPlantId(_plantId);
    }

    Navigator.pushNamed(context, AppRoutes.analyzing);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
        title: Text(
          _plantId != null ? 'Nuevo diagnóstico' : 'Analizar planta',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.isEmbedded) ...[
                Text(
                  'Analizar cultivo',
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],

              Text(
                _plantId != null
                    ? 'Sube una nueva foto para el seguimiento'
                    : 'Sube una foto de tu cultivo',
                style: AppTextStyles.headlineMedium.copyWith(
                  fontSize: 18,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                'Asegúrate de que las hojas sean claramente visibles para obtener un mejor diagnóstico.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              _buildImageArea(isDark),

              const SizedBox(height: 24),

              PrimaryButton(
                text: 'Tomar fotografía',
                icon: Icons.camera_alt,
                onPressed: _takePhoto,
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                text: 'Elegir de galería',
                icon: Icons.photo_library,
                onPressed: _pickFromGallery,
              ),

              const SizedBox(height: 32),

              PrimaryButton(
                text: 'Analizar planta',
                icon: Icons.search,
                onPressed: _imagePath != null ? _analyzePlant : null,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageArea(bool isDark) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.primaryBg,
          width: 2,
        ),
      ),
      child: _imagePath == null
          ? _buildEmptyImageArea(isDark)
          : _buildImagePreview(),
    );
  }

  Widget _buildEmptyImageArea(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate,
          size: 64,
          color: AppColors.primaryLight,
        ),
        const SizedBox(height: 16),
        Text(
          'Añade una fotografía',
          style: AppTextStyles.titleMedium.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'La fotografía debe mostrar claramente\nlas hojas de la planta',
          style: AppTextStyles.bodySmall.copyWith(
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              File(_imagePath!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 64,
                    color: AppColors.primaryLight,
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: _removeImage,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}