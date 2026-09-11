import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../providers/guia_provider.dart';
import '../../widgets/common/error_view.dart';
import '../../widgets/common/loading_view.dart';
import '../../widgets/plant/especie_card.dart';
import 'especie_detalle_screen.dart';

/// Menu Guia. Reemplaza a MyPlantsScreen, que pese al nombre era esta
/// pantalla y leia de mock_guides.dart.
class GuiaScreen extends StatefulWidget {
  final bool isEmbedded;

  const GuiaScreen({Key? key, this.isEmbedded = false}) : super(key: key);

  @override
  State<GuiaScreen> createState() => _GuiaScreenState();
}

class _GuiaScreenState extends State<GuiaScreen> {
  final _buscarCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GuiaProvider>().cargar();
    });
  }

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  void _abrirDetalle(String slug) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => EspecieDetalleScreen(slug: slug),
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (context, animation, _, child) {
          final tween = Tween(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic));
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: SlideTransition(
                position: animation.drive(tween), child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<GuiaProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
        title: const Text('Guías de cultivo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  Text(
                    'Guías de cultivo',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aprende a cuidar cada tipo de cultivo',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                controller: _buscarCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar cultivo',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  filled: true,
                  fillColor:
                  isDark ? AppColors.darkSurface : AppColors.surface,
                  suffixIcon: _buscarCtrl.text.isEmpty
                      ? null
                      : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _buscarCtrl.clear();
                      provider.buscar('');
                      setState(() {});
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (texto) {
                  provider.buscar(texto);
                  setState(() {}); // solo para mostrar u ocultar la X
                },
              ),
            ),
            Expanded(child: _cuerpo(provider, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _cuerpo(GuiaProvider provider, bool isDark) {
    if (provider.cargando && provider.especies.isEmpty) {
      return const LoadingView(message: 'Cargando guías...');
    }

    if (provider.error != null && provider.especies.isEmpty) {
      return ErrorView(
        message: provider.error!,
        onRetry: () => provider.cargar(),
      );
    }

    if (provider.especies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            provider.busqueda.isEmpty
                ? 'Todavía no hay guías disponibles.'
                : 'No encontramos cultivos con ese nombre.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textTertiary),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.cargar(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: provider.especies.length,
        itemBuilder: (context, index) {
          final especie = provider.especies[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: EspecieCard(
              especie: especie,
              onTap: () => _abrirDetalle(especie.slug),
            ),
          );
        },
      ),
    );
  }
}