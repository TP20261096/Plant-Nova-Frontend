import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../models/especie.dart';
import '../../providers/guia_provider.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';

/// GET /guide/species/{slug}
///
/// Reemplaza a PlantGuideDetailScreen, que tenia cinco pestanas fijas y la
/// mitad del contenido escrito a mano dentro del widget (los mismos
/// materiales y pasos para cualquier cultivo).
///
/// Aca las pestanas se arman con las secciones que manda el backend, en el
/// orden en que llegan. Si agregas una seccion en la base de datos, aparece
/// sola sin tocar codigo.
class EspecieDetalleScreen extends StatefulWidget {
  final String slug;

  const EspecieDetalleScreen({Key? key, required this.slug}) : super(key: key);

  @override
  State<EspecieDetalleScreen> createState() => _EspecieDetalleScreenState();
}

class _EspecieDetalleScreenState extends State<EspecieDetalleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GuiaProvider>().cargarDetalle(widget.slug);
    });
  }

  @override
  void dispose() {
    context.read<GuiaProvider>().limpiarDetalle();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<GuiaProvider>();
    final especie = provider.detalle;

    if (provider.cargandoDetalle) {
      return Scaffold(
        appBar: AppBar(
            backgroundColor: Colors.transparent, elevation: 0),
        body: const LoadingView(message: 'Cargando ficha...'),
      );
    }

    if (provider.errorDetalle != null) {
      return Scaffold(
        appBar: AppBar(
            backgroundColor: Colors.transparent, elevation: 0),
        body: ErrorView(
          message: provider.errorDetalle!,
          onRetry: () => provider.cargarDetalle(widget.slug),
        ),
      );
    }

    if (especie == null) {
      return Scaffold(
        appBar: AppBar(
            backgroundColor: Colors.transparent, elevation: 0),
        body: const SizedBox.shrink(),
      );
    }

    // Si el backend no mandara secciones, un TabBar de longitud 0 revienta.
    final secciones = especie.secciones;

    return DefaultTabController(
      length: secciones.isEmpty ? 1 : secciones.length,
      child: Scaffold(
        backgroundColor:
        isDark ? AppColors.darkBackground : AppColors.background,
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor:
              isDark ? AppColors.darkBackground : AppColors.background,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  especie.nombreComun,
                  style: const TextStyle(fontSize: 16),
                ),
                background: _portada(especie),
              ),
            ),
            SliverToBoxAdapter(child: _cabecera(especie, isDark)),
            if (secciones.isNotEmpty)
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    isScrollable: true,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textTertiary,
                    indicatorColor: AppColors.primary,
                    tabs: secciones
                        .map((s) => Tab(
                      icon: Icon(_icono(s.seccion), size: 18),
                      text: s.titulo,
                    ))
                        .toList(),
                  ),
                  isDark ? AppColors.darkBackground : AppColors.background,
                ),
              ),
          ],
          body: secciones.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Esta especie todavía no tiene información de cultivo.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textTertiary),
              ),
            ),
          )
              : TabBarView(
            children: secciones
                .map((s) => SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Text(
                s.contenido,
                style: AppTextStyles.bodyMedium
                    .copyWith(height: 1.6),
              ),
            ))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _portada(EspecieDetalle especie) {
    if (especie.imagenUrl == null) {
      return Container(
        color: AppColors.primaryBg,
        child: const Center(
          child: Icon(Icons.eco, size: 72, color: AppColors.primaryLight),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          especie.imagenUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.primaryBg,
            child: const Center(
              child: Icon(Icons.eco, size: 72, color: AppColors.primaryLight),
            ),
          ),
        ),
        // Degradado para que el titulo se lea sobre cualquier foto.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.center,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black54],
            ),
          ),
        ),
      ],
    );
  }

  Widget _cabecera(EspecieDetalle especie, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            especie.nombreCientifico,
            style: AppTextStyles.bodyMedium.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _dato(Icons.water_drop_outlined, especie.riegoTexto),
              _dato(Icons.bar_chart, 'Dificultad ${especie.dificultad.etiqueta}'),
              if (especie.luzRecomendada != null)
                _dato(Icons.wb_sunny_outlined, especie.luzRecomendada!),
              if (especie.familia != null)
                _dato(Icons.category_outlined, especie.familia!),
            ],
          ),
          const SizedBox(height: 14),
          Text(especie.resumen,
              style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),
          if (!especie.diagnosticable) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
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
                      'La cámara todavía no reconoce enfermedades de este '
                          'cultivo. Puedes registrarlo y llevar su riego igual.',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _dato(IconData icono, String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryBg.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _icono(String seccion) {
    switch (seccion) {
      case 'Preparacion':
        return Icons.build_outlined;
      case 'Siembra':
        return Icons.grass_outlined;
      case 'Cuidados':
        return Icons.favorite_outline;
      case 'Cosecha':
        return Icons.shopping_basket_outlined;
      case 'Consejos':
        return Icons.lightbulb_outline;
      default:
        return Icons.article_outlined;
    }
  }
}

/// Mantiene el TabBar pegado arriba mientras se desplaza el contenido.
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color fondo;

  _TabBarDelegate(this.tabBar, this.fondo);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(color: fondo, child: tabBar);
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) =>
      oldDelegate.tabBar != tabBar || oldDelegate.fondo != fondo;
}