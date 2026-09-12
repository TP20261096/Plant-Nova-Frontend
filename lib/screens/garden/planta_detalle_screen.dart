import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/utils/time_formatter.dart';
import '../../models/planta.dart';
import '../../providers/diagnostico_provider.dart';
import '../../providers/planta_provider.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';

/// Detalle de una planta con el diseño del frontend anterior + datos
/// del backend actual.
class PlantaDetalleScreen extends StatefulWidget {
  final String plantaId;

  const PlantaDetalleScreen({Key? key, required this.plantaId})
      : super(key: key);

  @override
  State<PlantaDetalleScreen> createState() => _PlantaDetalleScreenState();
}

class _PlantaDetalleScreenState extends State<PlantaDetalleScreen> {
  final _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  bool _subiendoFoto = false;
  String _plantName = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlantaProvider>().cargarDetalle(widget.plantaId);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    context.read<PlantaProvider>().limpiarDetalle();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<PlantaProvider>();
    final planta = provider.detalle;

    // Actualiza el nombre local cuando cargue la planta
    if (planta != null && _plantName.isEmpty) {
      _plantName = planta.apodo;
      _nameController.text = planta.apodo;
    }

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          _plantName.isEmpty ? 'Planta' : _plantName,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (planta != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _changeName(planta),
            ),
        ],
      ),
      body: _cuerpo(provider, planta, isDark),
    );
  }

  Widget _cuerpo(
      PlantaProvider provider,
      PlantaDetalle? planta,
      bool isDark,
      ) {
    if (provider.cargandoDetalle) {
      return const LoadingView(message: 'Cargando planta...');
    }

    if (provider.errorDetalle != null) {
      return ErrorView(
        message: provider.errorDetalle!,
        onRetry: () => provider.cargarDetalle(widget.plantaId),
      );
    }

    if (planta == null) return const SizedBox.shrink();

    final diagnosticos = planta.diagnosticos;

    return RefreshIndicator(
      onRefresh: () => provider.cargarDetalle(widget.plantaId),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header con gradiente + foto + nombre + especie + estado
            _buildPlantHeader(isDark, planta),
            const SizedBox(height: 20),

            // 2. Card de riego
            _tarjetaRiego(planta, isDark),
            const SizedBox(height: 12),

            // 3. Info del backend (ubicación, etapa, etc.)
            _datos(planta, isDark),

            // 4. Cuidados (si aplica)
            if (planta.riegoNota != null || planta.otrosCuidados != null) ...[
              const SizedBox(height: 12),
              _cuidados(planta, isDark),
            ],

            const SizedBox(height: 20),

            // 5. Diagnósticos (sin botón "Nuevo")
            Text(
              'Diagnósticos',
              style: AppTextStyles.titleLarge.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Lista de diagnósticos
            if (diagnosticos.isEmpty)
              _buildEmptyDiagnoses(isDark)
            else
              ...diagnosticos.asMap().entries.map((entry) {
                return _buildDiagnosisCard(
                  context,
                  entry.value,
                  isDark,
                  diagnosticNumber: entry.key + 1,
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HEADER (gradiente verde según estado + foto + nombre)
  // ═══════════════════════════════════════════════════════════
  Widget _buildPlantHeader(bool isDark, PlantaDetalle planta) {
    final Color statusColor = planta.estado.color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor,
            statusColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Foto clickeable (abre el menú para cambiar la foto)
          GestureDetector(
            onTap: _subiendoFoto ? null : _menuFoto,
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: _buildPlantImageDetail(planta.fotoUrl),
                  ),
                ),
                // Botón de cámara flotante
                if (!_subiendoFoto)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: statusColor,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: statusColor,
                      ),
                    ),
                  ),
                if (_subiendoFoto)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Nombre
          Text(
            _plantName,
            style: AppTextStyles.headlineLarge.copyWith(
              color: Colors.white,
              fontSize: 22,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // Especie
          Text(
            planta.especieVisible,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Estado
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            child: Text(
              planta.estado.etiqueta,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantImageDetail(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Center(
        child: Icon(
          Icons.local_florist,
          color: AppColors.primary,
          size: 50,
        ),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(
            Icons.local_florist,
            color: AppColors.primary,
            size: 50,
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TARJETA DE RIEGO
  // ═══════════════════════════════════════════════════════════
  Widget _tarjetaRiego(PlantaDetalle planta, bool isDark) {
    final atrasado = planta.riegoAtrasado;
    final color = atrasado ? AppColors.error : AppColors.info;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.water_drop, color: color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planta.textoRiego,
                  style: AppTextStyles.titleMedium.copyWith(color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  planta.riegoFrecuenciaDias == 0
                      ? 'Sin frecuencia calculada'
                      : 'Cada ${planta.riegoFrecuenciaDias} '
                      '${planta.riegoFrecuenciaDias == 1 ? 'día' : 'días'}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DATOS (ubicación, etapa, etc.)
  // ═══════════════════════════════════════════════════════════
  Widget _datos(PlantaDetalle planta, bool isDark) {
    return _tarjeta(
      isDark,
      child: Column(
        children: [
          _fila(
            Icons.place_outlined,
            'Ubicación',
            planta.ubicacion.etiqueta,
          ),
          _fila(
            Icons.timeline_outlined,
            'Etapa',
            planta.etapa.etiqueta,
          ),
          _fila(
            Icons.event_outlined,
            'Sembrada',
            planta.fechaSiembra == null
                ? 'Sin especificar'
                : _fecha(planta.fechaSiembra!),
          ),
          _fila(
            Icons.water_drop_outlined,
            'Último riego',
            planta.ultimoRiego == null
                ? 'Sin registrar'
                : _fecha(planta.ultimoRiego!),
          ),
        ],
      ),
    );
  }

  Widget _fila(IconData icono, String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icono, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 12),
          Text(
            etiqueta,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CUIDADOS
  // ═══════════════════════════════════════════════════════════
  Widget _cuidados(PlantaDetalle planta, bool isDark) {
    return _tarjeta(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cuidados', style: AppTextStyles.titleMedium),
          if (planta.riegoNota != null) ...[
            const SizedBox(height: 10),
            Text(planta.riegoNota!, style: AppTextStyles.bodyMedium),
          ],
          if (planta.otrosCuidados != null) ...[
            const SizedBox(height: 10),
            Text(planta.otrosCuidados!, style: AppTextStyles.bodyMedium),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DIAGNÓSTICOS
  // ═══════════════════════════════════════════════════════════
  Widget _buildEmptyDiagnoses(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.health_and_safety,
            size: 40,
            color: AppColors.primaryLight,
          ),
          const SizedBox(height: 8),
          Text(
            'Aún no hay diagnósticos',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _startNewDiagnosis,
            icon: const Icon(Icons.camera_alt, size: 18),
            label: const Text('Analizar planta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisCard(
      BuildContext context,
      DiagnosticoResumen diagnosis,
      bool isDark, {
        required int diagnosticNumber,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _abrirDiagnostico(diagnosis.id),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: diagnosis.estado.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.health_and_safety,
                        color: diagnosis.estado.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getDiagnosticLabel(diagnosticNumber),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: diagnosticNumber == 1
                                  ? AppColors.primaryLight
                                  : isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                              fontWeight: diagnosticNumber == 1
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            diagnosis.nombreEnfermedad,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            TimeFormatter.formatRelativeTime(
                              diagnosis.createdAt,
                            ),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextTertiary
                                  : AppColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      diagnosis.confianzaTexto,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: diagnosis.estado.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Ver diagnóstico completo y tratamientos',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDiagnosticLabel(int number) {
    switch (number) {
      case 1:
        return 'Primer diagnóstico';
      case 2:
        return 'Segundo diagnóstico';
      case 3:
        return 'Tercer diagnóstico';
      case 4:
        return 'Cuarto diagnóstico';
      case 5:
        return 'Quinto diagnóstico';
      default:
        return 'Diagnóstico #$number';
    }
  }

  // ═══════════════════════════════════════════════════════════
  // ACCIONES
  // ═══════════════════════════════════════════════════════════
  void _startNewDiagnosis() {
    Navigator.pushNamed(
      context,
      AppRoutes.uploadPlant,
      arguments: {'plantId': widget.plantaId},
    );
  }

  void _changeName(PlantaDetalle planta) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
          isDark ? AppColors.darkSurface : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.all(16),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          actionsPadding: const EdgeInsets.all(8),
          title: Text(
            'Cambiar nombre',
            style: AppTextStyles.titleLarge.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          content: TextField(
            controller: _nameController,
            textAlign: TextAlign.center,
            autofocus: true,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.textPrimary,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: 'Ej: Mi tomate',
              hintStyle: TextStyle(
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.textTertiary,
                fontSize: 14,
              ),
              filled: true,
              fillColor: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.primaryBg,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryLight,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_nameController.text.trim().isNotEmpty) {
                        final newName = _nameController.text.trim();
                        final provider = context.read<PlantaProvider>();
                        final messenger = ScaffoldMessenger.of(context);

                        // 1) Actualizar apodo en el backend
                        await provider.actualizar(
                          widget.plantaId,
                          {'apodo': newName},
                        );

                        // 2) Recargar detalle completo para recuperar diagnósticos
                        await provider.cargarDetalle(widget.plantaId);

                        if (!mounted) return;

                        setState(() {
                          _plantName = newName;
                        });

                        Navigator.pop(dialogContext);

                        messenger.showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Nombre actualizado correctamente',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14),
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
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Guardar',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _menuFoto() {
    showModalBottomSheet(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(sheet);
                _subirFoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(sheet);
                _subirFoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _subirFoto(ImageSource origen) async {
    final XFile? elegida;
    try {
      elegida = await _picker.pickImage(
        source: origen,
        imageQuality: 85,
        maxWidth: 1600,
      );
    } catch (_) {
      if (!mounted) return;
      _avisar('No se pudo acceder a la cámara o la galería', error: true);
      return;
    }

    if (elegida == null || !mounted) return;

    setState(() => _subiendoFoto = true);
    final provider = context.read<PlantaProvider>();
    final ok = await provider.cambiarFoto(widget.plantaId, File(elegida.path));

    if (!mounted) return;
    setState(() => _subiendoFoto = false);

    if (ok) {
      _avisar('Foto actualizada');
    } else {
      _avisar(provider.errorDetalle ?? 'No se pudo subir la foto',
          error: true);
      provider.limpiarError();
    }
  }

  Future<void> _abrirDiagnostico(String id) async {
    final provider = context.read<DiagnosticoProvider>();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final ok = await provider.cargar(id);

    if (!mounted) return;
    Navigator.pop(context);

    if (!ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            provider.error ?? 'No se pudo abrir el diagnóstico',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      provider.limpiarError();
      return;
    }

    Navigator.pushNamed(context, AppRoutes.diagnosticoResultado);
  }

  void _avisar(String mensaje, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: error ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════
  Widget _tarjeta(bool isDark, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  String _fecha(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')}/'
          '${f.month.toString().padLeft(2, '0')}/${f.year}';
}