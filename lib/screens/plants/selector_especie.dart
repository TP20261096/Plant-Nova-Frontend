import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../models/enums.dart';
import '../../models/especie.dart';
import '../../providers/guia_provider.dart';

/// Hoja inferior para elegir la especie al registrar o editar una planta.
///
/// Devuelve la Especie elegida, o [SelectorEspecie.sinEspecie] si el usuario
/// escoge no asignar ninguna. Cerrar sin elegir devuelve null.
class SelectorEspecie extends StatefulWidget {
  final Especie? seleccionada;

  const SelectorEspecie({Key? key, this.seleccionada}) : super(key: key);

  /// Centinela con id vacio: significa "sin especie".
  static const Especie sinEspecie = Especie(
    id: '',
    slug: '',
    nombreComun: '',
    nombreCientifico: '',
    imagenUrl: null,
    resumen: '',
    dificultad: Dificultad.desconocida,
    riegoBaseDias: 0,
    diagnosticable: false,
  );

  @override
  State<SelectorEspecie> createState() => _SelectorEspecieState();
}

class _SelectorEspecieState extends State<SelectorEspecie> {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<GuiaProvider>();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text('Elige la especie',
                    style: AppTextStyles.titleLarge),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _buscarCtrl,
                  decoration: InputDecoration(
                    hintText: 'Buscar cultivo',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: provider.buscar,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: _lista(provider, isDark, scrollController)),
            ],
          ),
        );
      },
    );
  }

  Widget _lista(
      GuiaProvider provider,
      bool isDark,
      ScrollController scrollController,
      ) {
    if (provider.cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(provider.error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => provider.cargar(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      children: [
        _opcionSinEspecie(isDark),
        if (provider.sinResultados)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'No encontramos esa especie',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textTertiary),
            ),
          ),
        ...provider.especies.map((e) => _fila(e, isDark)),
      ],
    );
  }

  Widget _opcionSinEspecie(bool isDark) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: AppColors.primaryBg,
        child: Icon(Icons.help_outline, color: AppColors.primary, size: 20),
      ),
      title: const Text('Sin especie'),
      subtitle: Text(
        'No sé cuál es o no está en la lista',
        style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
      ),
      selected: widget.seleccionada == null,
      onTap: () => Navigator.pop(context, SelectorEspecie.sinEspecie),
    );
  }

  Widget _fila(Especie especie, bool isDark) {
    final elegida = widget.seleccionada?.id == especie.id;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryBg,
        backgroundImage: especie.imagenUrl != null
            ? NetworkImage(especie.imagenUrl!)
            : null,
        child: especie.imagenUrl == null
            ? const Icon(Icons.eco, color: AppColors.primary, size: 20)
            : null,
      ),
      title: Text(especie.nombreComun),
      subtitle: Text(
        especie.nombreCientifico,
        style: AppTextStyles.bodySmall
            .copyWith(fontSize: 11, fontStyle: FontStyle.italic),
      ),
      trailing: especie.diagnosticable
          ? const Icon(Icons.camera_alt_outlined,
          size: 16, color: AppColors.primary)
          : null,
      selected: elegida,
      onTap: () => Navigator.pop(context, especie),
    );
  }
}