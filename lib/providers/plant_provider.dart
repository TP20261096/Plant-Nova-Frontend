import 'package:flutter/foundation.dart';
import '../models/plant.dart';
import '../models/diagnosis.dart';
import '../services/plant_service.dart';

class PlantProvider extends ChangeNotifier {
  final PlantService _plantService = PlantService();

  List<Plant> _plants = [];
  bool _isLoading = false;
  String? _error;

  List<Plant> get plants => _plants;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get healthyPlantsCount => _plants.where((plant) => plant.status == 'Saludable').length;
  int get plantsNeedingAttention => _plants.where((plant) => plant.status == 'Necesita atención').length;

  Future<void> loadPlants() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _plants = await _plantService.getPlants();
    } catch (e) {
      _error = 'Error al cargar las plantas';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Plant?> getPlantById(String id) async {
    try {
      return await _plantService.getPlantById(id);
    } catch (e) {
      return null;
    }
  }

  Future<void> addPlant(Plant plant) async {
    try {
      // Verificar si ya existe en la lista del provider
      final existsInProvider = _plants.any((p) => p.id == plant.id);

      if (!existsInProvider) {
        await _plantService.addPlant(plant);
        _plants.add(plant);
      }

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Error al agregar la planta';
      notifyListeners();
    }
  }

  Future<void> updatePlant(Plant plant) async {
    try {
      await _plantService.updatePlant(plant);
      final index = _plants.indexWhere((p) => p.id == plant.id);
      if (index != -1) {
        _plants[index] = plant;
      }
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Error al actualizar la planta';
      notifyListeners();
    }
  }

  // Método para cambiar el nombre de una planta
  Future<void> updatePlantName(String plantId, String newName) async {
    try {
      final index = _plants.indexWhere((p) => p.id == plantId);
      if (index != -1) {
        // Actualizar también el nombre en todos los diagnósticos
        final existingDiagnoses = _plants[index].diagnosisHistory ?? [];
        final updatedDiagnoses = existingDiagnoses.map((diagnosis) {
          return Diagnosis(
            id: diagnosis.id,
            plantName: newName, // ← Actualizar nombre en el diagnóstico
            plantSpecies: diagnosis.plantSpecies,
            disease: diagnosis.disease,
            confidence: diagnosis.confidence,
            symptoms: diagnosis.symptoms,
            causes: diagnosis.causes,
            treatment: diagnosis.treatment,
            organicTreatment: diagnosis.organicTreatment,
            prevention: diagnosis.prevention,
            imageUrl: diagnosis.imageUrl,
            date: diagnosis.date,
            status: diagnosis.status,
          );
        }).toList();

        final updatedPlant = Plant(
          id: _plants[index].id,
          name: newName,
          species: _plants[index].species,
          status: _plants[index].status,
          imageUrl: _plants[index].imageUrl,
          lastDiagnosisDate: _plants[index].lastDiagnosisDate,
          nextCare: _plants[index].nextCare,
          wateringFrequency: _plants[index].wateringFrequency,
          lightRequirement: _plants[index].lightRequirement,
          humidity: _plants[index].humidity,
          diagnosisHistory: updatedDiagnoses, // ← Diagnósticos con nombre actualizado
        );

        _plants[index] = updatedPlant;
        await _plantService.updatePlant(updatedPlant);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error al cambiar el nombre';
      notifyListeners();
    }
  }

  Future<void> addDiagnosisToPlant(String plantId, Diagnosis diagnosis) async {
    try {
      final index = _plants.indexWhere((p) => p.id == plantId);
      if (index != -1) {
        final existingDiagnoses = _plants[index].diagnosisHistory ?? [];
        final updatedDiagnoses = [...existingDiagnoses, diagnosis];

        final updatedPlant = Plant(
          id: _plants[index].id,
          name: _plants[index].name,
          species: _plants[index].species,
          status: _plants[index].status,
          imageUrl: _plants[index].imageUrl,
          lastDiagnosisDate: DateTime.now(),
          nextCare: _plants[index].nextCare,
          wateringFrequency: _plants[index].wateringFrequency,
          lightRequirement: _plants[index].lightRequirement,
          humidity: _plants[index].humidity,
          diagnosisHistory: updatedDiagnoses,
        );

        _plants[index] = updatedPlant;
        await _plantService.updatePlant(updatedPlant);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error al agregar diagnóstico';
      notifyListeners();
    }
  }

  Future<void> deletePlant(String id) async {
    try {
      await _plantService.deletePlant(id);
      _plants.removeWhere((plant) => plant.id == id);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Error al eliminar la planta';
      notifyListeners();
    }
  }

  // Método para limpiar todas las plantas
  Future<void> clearAllPlants() async {
    try {
      await _plantService.clearAllPlants();
      _plants.clear();
      notifyListeners();
    } catch (e) {
      _error = 'Error al limpiar el jardín';
      notifyListeners();
    }
  }

  // Generar actividades basadas en diagnósticos
  List<Map<String, dynamic>> generateActivitiesForDate(DateTime date) {
    final activities = <Map<String, dynamic>>[];

    for (final plant in _plants) {
      final diagnoses = plant.diagnosisHistory ?? [];
      if (diagnoses.isEmpty) continue;

      final lastDiagnosis = diagnoses.first;
      final daysSinceDiagnosis = date.difference(lastDiagnosis.date).inDays;

      if (daysSinceDiagnosis == 0) {
        activities.add({
          'id': 'treatment_${plant.id}',
          'title': 'Aplicar tratamiento a ${plant.name}',
          'description': 'Seguir el tratamiento para ${lastDiagnosis.disease}',
          'icon': '💊',
          'type': 'tratamiento',
          'plantId': plant.id,
          'plantName': plant.name,
          'disease': lastDiagnosis.disease,
        });
      } else if (daysSinceDiagnosis == 1) {
        activities.add({
          'id': 'check_${plant.id}',
          'title': 'Revisar evolución de ${plant.name}',
          'description': 'Verificar si hay mejoría en los síntomas',
          'icon': '🔍',
          'type': 'seguimiento',
          'plantId': plant.id,
          'plantName': plant.name,
          'disease': lastDiagnosis.disease,
        });
      } else if (daysSinceDiagnosis % 2 == 0) {
        activities.add({
          'id': 'water_${plant.id}_$daysSinceDiagnosis',
          'title': 'Regar ${plant.name}',
          'description': 'Mantener la humedad adecuada del suelo',
          'icon': '💧',
          'type': 'riego',
          'plantId': plant.id,
          'plantName': plant.name,
        });
      } else if (daysSinceDiagnosis % 3 == 0) {
        activities.add({
          'id': 'fertilize_${plant.id}_$daysSinceDiagnosis',
          'title': 'Fertilizar ${plant.name}',
          'description': 'Aplicar abono orgánico para fortalecer la planta',
          'icon': '🌱',
          'type': 'fertilizacion',
          'plantId': plant.id,
          'plantName': plant.name,
        });
      }

      if (plant.status == 'Necesita atención' || plant.status == 'Enferma') {
        if (daysSinceDiagnosis >= 2 && daysSinceDiagnosis % 2 == 0) {
          activities.add({
            'id': 'monitor_${plant.id}_$daysSinceDiagnosis',
            'title': 'Monitorear ${plant.name}',
            'description': 'Revisar signos de plagas o empeoramiento',
            'icon': '🔬',
            'type': 'monitoreo',
            'plantId': plant.id,
            'plantName': plant.name,
            'disease': lastDiagnosis.disease,
          });
        }
      }
    }

    return activities;
  }
}