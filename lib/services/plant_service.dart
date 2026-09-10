import '../models/plant.dart';

class PlantService {
  // Lista en memoria
  List<Plant> _plants = [];

  Future<List<Plant>> getPlants() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_plants);
  }

  Future<Plant?> getPlantById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _plants.firstWhere((plant) => plant.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> addPlant(Plant plant) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Solo agregar si no existe
    final exists = _plants.any((p) => p.id == plant.id);
    if (!exists) {
      _plants.add(plant);
    }
  }

  Future<void> updatePlant(Plant plant) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _plants.indexWhere((p) => p.id == plant.id);
    if (index != -1) {
      _plants[index] = plant;
    }
  }

  Future<void> deletePlant(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _plants.removeWhere((plant) => plant.id == id);
  }

  // Método para limpiar todas las plantas
  Future<void> clearAllPlants() async {
    _plants.clear();
  }
}