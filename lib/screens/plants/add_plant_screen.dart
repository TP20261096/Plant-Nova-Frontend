import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/secondary_button.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({Key? key}) : super(key: key);

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _wateringController = TextEditingController();
  final _lightController = TextEditingController();
  final _humidityController = TextEditingController();

  String _status = 'Saludable';

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _wateringController.dispose();
    _lightController.dispose();
    _humidityController.dispose();
    super.dispose();
  }

  void _savePlant() {
    if (_formKey.currentState!.validate()) {
      // Aquí se guardaría la planta
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Planta agregada correctamente'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir planta'),
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
              Text(
                'Información de la planta',
                style: AppTextStyles.headlineMedium,
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej: Monstera',
                  prefixIcon: Icon(Icons.local_florist),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _speciesController,
                decoration: const InputDecoration(
                  labelText: 'Especie',
                  hintText: 'Ej: Monstera deliciosa',
                  prefixIcon: Icon(Icons.science),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa la especie';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  prefixIcon: Icon(Icons.favorite),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Saludable',
                    child: Text('Saludable'),
                  ),
                  DropdownMenuItem(
                    value: 'Necesita atención',
                    child: Text('Necesita atención'),
                  ),
                  DropdownMenuItem(
                    value: 'Enferma',
                    child: Text('Enferma'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _status = value!;
                  });
                },
              ),
              const SizedBox(height: 24),

              Text(
                'Cuidados',
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _wateringController,
                decoration: const InputDecoration(
                  labelText: 'Frecuencia de riego',
                  hintText: 'Ej: Cada 7-10 días',
                  prefixIcon: Icon(Icons.water_drop),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _lightController,
                decoration: const InputDecoration(
                  labelText: 'Iluminación',
                  hintText: 'Ej: Luz indirecta brillante',
                  prefixIcon: Icon(Icons.wb_sunny),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _humidityController,
                decoration: const InputDecoration(
                  labelText: 'Humedad',
                  hintText: 'Ej: 60-80%',
                  prefixIcon: Icon(Icons.opacity),
                ),
              ),
              const SizedBox(height: 32),

              PrimaryButton(
                text: 'Guardar planta',
                icon: Icons.save,
                onPressed: _savePlant,
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                text: 'Cancelar',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}