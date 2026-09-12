import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../models/especie.dart';
import '../../providers/guia_provider.dart';
import '../../widgets/common/animated_tab_bar.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';

/// GET /guide/species/{slug}
///
/// Fusiona el diseño visual anterior (header con gradiente, tabs animados,
/// cards por sección) con los datos dinámicos que manda el backend.
class EspecieDetalleScreen extends StatefulWidget {
  final String slug;

  const EspecieDetalleScreen({Key? key, required this.slug}) : super(key: key);

  @override
  State<EspecieDetalleScreen> createState() => _EspecieDetalleScreenState();
}

class _EspecieDetalleScreenState extends State<EspecieDetalleScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  int _lastLength = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GuiaProvider>().cargarDetalle(widget.slug);
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  TabController _controller(int length) {
    if (_tabController == null || _lastLength != length) {
      _tabController?.dispose();
      _tabController = TabController(length: length, vsync: this);
      _lastLength = length;
    }
    return _tabController!;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<GuiaProvider>();
    final especie = provider.detalle;

    if (provider.cargandoDetalle) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const LoadingView(message: 'Cargando ficha...'),
      );
    }

    if (provider.errorDetalle != null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: ErrorView(
          message: provider.errorDetalle!,
          onRetry: () => provider.cargarDetalle(widget.slug),
        ),
      );
    }

    if (especie == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const SizedBox.shrink(),
      );
    }

    final secciones = especie.secciones;
    final len = secciones.isEmpty ? 1 : secciones.length;
    final controller = _controller(len);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          especie.nombreComun,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header con gradiente
          _buildHeader(especie, isDark),

          const SizedBox(height: 12),

          // AnimatedTabBar con secciones dinámicas del backend
          if (secciones.isEmpty)
            const SizedBox.shrink()
          else
            AnimatedTabBar(
              controller: controller,
              indicatorColor: AppColors.primaryLight,
              labelColor: Colors.white,
              unselectedLabelColor: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
              tabs: secciones
                  .map<AnimatedTab>((s) => AnimatedTab(
                icon: _icono(s.seccion),
                label: _labelCorto(s.titulo),
              ))
                  .toList(),
            ),

          const SizedBox(height: 12),

          // Contenido de la sección
          Expanded(
            child: secciones.isEmpty
                ? _buildEmpty()
                : TabBarView(
              controller: controller,
              physics: const NeverScrollableScrollPhysics(),
              children: secciones
                  .map<Widget>((s) => _buildContenido(s, isDark))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HEADER (gradiente verde con imagen, nombre, badges)
  // ═══════════════════════════════════════════════════════════
  Widget _buildHeader(EspecieDetalle especie, bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icono o imagen
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: especie.imagenUrl == null
                ? const Icon(Icons.eco, size: 32, color: AppColors.primary)
                : Image.network(
              especie.imagenUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.eco,
                size: 32,
                color: AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Nombre
          Text(
            especie.nombreComun,
            style: AppTextStyles.headlineLarge.copyWith(
              color: Colors.white,
              fontSize: 22,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 2),

          // Nombre científico
          Text(
            especie.nombreCientifico,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontStyle: FontStyle.italic,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          // Badges (chips de info)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _badgeHeader(Icons.water_drop_outlined, especie.riegoTexto),
              _badgeHeader(
                Icons.bar_chart,
                'Dificultad ${especie.dificultad.etiqueta}',
              ),
              if (especie.luzRecomendada != null)
                _badgeHeader(Icons.wb_sunny_outlined, especie.luzRecomendada!),
              if (especie.familia != null)
                _badgeHeader(Icons.category_outlined, especie.familia!),
            ],
          ),

          const SizedBox(height: 10),

          // Resumen
          Text(
            especie.resumen,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          // Aviso de no diagnosticable
          if (!especie.diagnosticable) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Sin diagnóstico por cámara aún',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
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

  Widget _badgeHeader(IconData icono, String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CONTENIDO DE SECCIÓN
  // ═══════════════════════════════════════════════════════════
  Widget _buildContenido(SeccionGuia seccion, bool isDark) {
    final bloques = seccion.contenido
        .split(RegExp(r'\n\s*\n'))
        .map<String>((b) => b.trim())
        .where((String b) => b.isNotEmpty)
        .toList();

    if (bloques.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Sin información para esta sección.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: bloques.asMap().entries.map<Widget>((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildBloque(entry.value, isDark, entry.key),
          );
        }).toList(),
      ),
    );
  }

  /// Detecta si un bloque es lista (bullets o numerado) y lo renderiza
  /// como tal. Si no, lo renderiza como párrafo simple con números
  /// destacados.
  Widget _buildBloque(String bloque, bool isDark, int index) {
    final lineas = bloque
        .split('\n')
        .map<String>((l) => l.trim())
        .where((String l) => l.isNotEmpty)
        .toList();

    // ¿Es lista? (más de 1 línea y todas empiezan con bullet o número)
    final esLista = lineas.length > 1 &&
        lineas.every((l) =>
        l.startsWith('-') ||
            l.startsWith('•') ||
            l.startsWith('*') ||
            RegExp(r'^\d+[\.\)]').hasMatch(l));

    if (esLista) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lineas.map<Widget>((linea) {
            final numMatch =
            RegExp(r'^(\d+)[\.\)]\s*(.+)$').firstMatch(linea);
            if (numMatch != null) {
              return _itemNumerado(
                numMatch.group(1)!,
                numMatch.group(2)!,
                isDark,
              );
            }
            final texto = linea.replaceFirst(RegExp(r'^[-•*]\s*'), '');
            return _itemCheck(texto, isDark);
          }).toList(),
        ),
      );
    }

    // Párrafo simple con números destacados (sin icono)
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _textoConNumerosDestacados(bloque, isDark),
    );
  }

  /// Renderiza el texto con los números (incluyendo rangos) en negrita verde
  Widget _textoConNumerosDestacados(String texto, bool isDark) {
    final partes = <TextSpan>[];

    // Regex que detecta:
    // - Rangos: "10 a 15 días", "10-15 días", "10 a 15 cm"
    // - Números con unidad: "25 litros", "40 cm", "6 horas"
    // - Números sueltos: "3", "10"
    final regex = RegExp(
      r'(\d+\s*(?:a|-|–)\s*\d+\s*(?:litros?|cm|m|metros?|horas?|días?|semanas?|meses?|%|grados?|°C|kg|g|gramos?|ml|mililitros?|años?))'
      r'|(\d+\s*(?:litros?|cm|m|metros?|horas?|días?|semanas?|meses?|%|grados?|°C|kg|g|gramos?|ml|mililitros?|años?))'
      r'|(\b\d+\b)',
      caseSensitive: false,
    );

    int lastMatchEnd = 0;
    for (final match in regex.allMatches(texto)) {
      if (match.start > lastMatchEnd) {
        partes.add(TextSpan(
          text: texto.substring(lastMatchEnd, match.start),
        ));
      }
      partes.add(TextSpan(
        text: match.group(0),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ));
      lastMatchEnd = match.end;
    }
    if (lastMatchEnd < texto.length) {
      partes.add(TextSpan(text: texto.substring(lastMatchEnd)));
    }

    return RichText(
      text: TextSpan(
        style: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          fontSize: 13,
          height: 1.5,
        ),
        children: partes,
      ),
    );
  }

  Widget _itemNumerado(String numero, String texto, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                numero,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                texto,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCheck(String texto, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 12,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Esta especie todavía no tiene información de cultivo.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════
  IconData _icono(String seccion) {
    switch (seccion) {
      case 'Preparacion':
        return Icons.landscape;
      case 'Siembra':
        return Icons.grass;
      case 'Cuidados':
        return Icons.favorite;
      case 'Enfermedades':
        return Icons.warning;
      case 'Cosecha':
        return Icons.agriculture;
      case 'Consejos':
        return Icons.lightbulb_outline;
      default:
        return Icons.article_outlined;
    }
  }

  /// Acorta el título si es muy largo (para que quepa en el tab)
  String _labelCorto(String titulo) {
    if (titulo.length <= 12) return titulo;
    return titulo;
  }
}