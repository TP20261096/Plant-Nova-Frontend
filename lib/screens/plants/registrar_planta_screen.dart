import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../models/enums.dart';
import '../../models/especie.dart';
import '../../models/planta.dart';
import '../../providers/guia_provider.dart';
import '../../providers/planta_provider.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/secondary_button.dart';
import 'selector_especie.dart';

/// POST /plants
///
/// Reemplaza a AddPlantScreen, que pedia campos que el backend no acepta
/// (estado, iluminacion, humedad) y no guardaba nada.
///
/// Lo que ya no se pregunta, a proposito:
///  - Estado: lo calcula el backend con los diagnosticos.
///  - Frecuencia de riego: sale de la especie y del clima, y se recalcula
///    sola. Si la pidieramos aca quedaria congelada y desactualizada.
class RegistrarPlantaScreen extends StatefulWidget {
  const RegistrarPlantaScreen({Key? key}) : super(key: key);

  @override
  State<RegistrarPlantaScreen> createState() => _RegistrarPlantaScreenState();
}

class _RegistrarPlantaScreenState extends State<RegistrarPlantaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apodoCtrl = TextEditingController();

  Especie? _especie;
  Ubicacion _ubicacion = Ubicacion.balcon;
  Etapa _etapa = Etapa.germinacion;
  DateTime? _fechaSiembra;
  bool _guardando = false;

  @override
  void dispose() {
    _apodoCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirEspecie() async {
    final elegida = await showModalBottomSheet<Especie?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectorEspecie(seleccionada: _especie),
    );
    // null significa que cerro sin elegir; SelectorEspecie devuelve
    // Especie.vacia para "sin especie".
    if (elegida == null) return;
    setState(() {
      _especie = elegida.id.isEmpty ? null : elegida;
    });
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSiembra ?? hoy,
      firstDate: DateTime(hoy.year - 5),
      // No tiene sentido sembrar en el futuro.
      lastDate: hoy,
      locale: const Locale('es'),
    );
    if (fecha != null) setState(() => _fechaSiembra = fecha);
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    final provider = context.read<PlantaProvider>();
    final creada = await provider.crear(PlantaForm(
      apodo: _apodoCtrl.text,
      ubicacion: _ubicacion,
      etapa: _etapa,
      speciesId: _especie?.id,
      fechaSiembra: _fechaSiembra,
    ));

    if (!mounted) return;
    setState(() => _guardando = false);

    if (creada != null) {
      Navigator.pop(context, creada);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'No se pudo registrar la planta'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider.value(
      value: context.read<GuiaProvider>(),
      child: Scaffold(
        backgroundColor:
        isDark ? AppColors.darkBackground : AppColors.background,
        appBar: AppBar(
          title: const Text('Registrar planta'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Información de la planta',
                    style: AppTextStyles.headlineMedium),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _apodoCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Apodo',
                    hintText: 'Ej: Mi tomate del balcón',
                    prefixIcon: Icon(Icons.local_florist),
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? 'Ponle un nombre para reconocerla'
                      : null,
                ),
                const SizedBox(height: 16),

                _selectorEspecie(isDark),
                const SizedBox(height: 16),

                DropdownButtonFormField<Ubicacion>(
                  value: _ubicacion,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                  items: Ubicacion.opciones
                      .map((u) => DropdownMenuItem(
                    value: u,
                    child: Row(
                      children: [
                        Icon(u.icono,
                            size: 18, color: AppColors.textTertiary),
                        const SizedBox(width: 10),
                        Text(u.etiqueta),
                      ],
                    ),
                  ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _ubicacion = v ?? Ubicacion.balcon),
                ),
                const SizedBox(height: 6),
                _ayuda('La ubicación ajusta el riego: una planta en '
                    'interior se seca más lento que una en terraza.'),
                const SizedBox(height: 16),

                DropdownButtonFormField<Etapa>(
                  value: _etapa,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Etapa',
                    prefixIcon: Icon(Icons.timeline_outlined),
                  ),
                  items: Etapa.opciones
                      .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.etiqueta),
                  ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _etapa = v ?? Etapa.germinacion),
                ),
                const SizedBox(height: 16),

                _selectorFecha(isDark),
                const SizedBox(height: 32),

                PrimaryButton(
                  text: 'Guardar planta',
                  icon: Icons.save,
                  isLoading: _guardando,
                  onPressed: _guardar,
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  text: 'Cancelar',
                  onPressed:
                  _guardando ? null : () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectorEspecie(bool isDark) {
    final tiene = _especie != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _elegirEspecie,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Especie',
              prefixIcon: Icon(Icons.eco_outlined),
              suffixIcon: Icon(Icons.keyboard_arrow_down),
            ),
            child: Text(
              tiene ? _especie!.nombreComun : 'Sin especie',
              style: AppTextStyles.bodyMedium.copyWith(
                color: tiene
                    ? (isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary)
                    : AppColors.textTertiary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        _ayuda(tiene
            ? (_especie!.diagnosticable
            ? 'Podrás diagnosticar esta planta con la cámara.'
            : 'Esta especie no se puede diagnosticar con la cámara, '
            'pero sí llevar su riego y sus tareas.')
            : 'Sin especie no hay diagnóstico ni riego calculado. '
            'Puedes elegirla después.'),
      ],
    );
  }

  Widget _selectorFecha(bool isDark) {
    final texto = _fechaSiembra == null
        ? 'Sin especificar'
        : '${_fechaSiembra!.day.toString().padLeft(2, '0')}/'
        '${_fechaSiembra!.month.toString().padLeft(2, '0')}/'
        '${_fechaSiembra!.year}';

    return InkWell(
      onTap: _elegirFecha,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha de siembra (opcional)',
          prefixIcon: const Icon(Icons.event_outlined),
          suffixIcon: _fechaSiembra == null
              ? const Icon(Icons.keyboard_arrow_down)
              : IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _fechaSiembra = null),
          ),
        ),
        child: Text(
          texto,
          style: AppTextStyles.bodyMedium.copyWith(
            color: _fechaSiembra == null
                ? AppColors.textTertiary
                : (isDark
                ? AppColors.darkTextPrimary
                : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _ayuda(String texto) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        texto,
        style: AppTextStyles.bodySmall.copyWith(
          fontSize: 11,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}