import 'package:flutter/foundation.dart';
import '../models/diagnosis.dart';
import '../models/plant.dart';
import '../services/diagnosis_service.dart';

class DiagnosisProvider extends ChangeNotifier {
  final DiagnosisService _diagnosisService = DiagnosisService();

  List<Diagnosis> _diagnoses = [];
  bool _isLoading = false;
  String? _error;
  Diagnosis? _currentDiagnosis;
  String? _selectedImagePath;
  String? _plantId; // ← ID de la planta existente

  List<Diagnosis> get diagnoses => _diagnoses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Diagnosis? get currentDiagnosis => _currentDiagnosis;
  String? get selectedImagePath => _selectedImagePath;
  String? get plantId => _plantId;

  void setSelectedImage(String? imagePath) {
    _selectedImagePath = imagePath;
    notifyListeners();
  }

  void setPlantId(String? plantId) {
    _plantId = plantId;
    notifyListeners();
  }

  void clearSelectedImage() {
    _selectedImagePath = null;
    notifyListeners();
  }

  void clearPlantId() {
    _plantId = null;
    notifyListeners();
  }

  Future<void> analyzePlant(String imagePath) async {
    _isLoading = true;
    _error = null;
    _currentDiagnosis = null;
    notifyListeners();

    try {
      _currentDiagnosis = await _diagnosisService.analyzePlantImage(imagePath);
      if (_currentDiagnosis != null) {
        _currentDiagnosis = Diagnosis(
          id: _currentDiagnosis!.id,
          plantName: _currentDiagnosis!.plantName,
          plantSpecies: _currentDiagnosis!.plantSpecies,
          disease: _currentDiagnosis!.disease,
          confidence: _currentDiagnosis!.confidence,
          symptoms: _currentDiagnosis!.symptoms,
          causes: _currentDiagnosis!.causes,
          treatment: _currentDiagnosis!.treatment,
          organicTreatment: _currentDiagnosis!.organicTreatment,
          prevention: _currentDiagnosis!.prevention,
          imageUrl: imagePath,
          date: _currentDiagnosis!.date,
          status: _currentDiagnosis!.status,
        );
        _diagnoses.insert(0, _currentDiagnosis!);
      }
    } catch (e) {
      _error = 'Error al analizar la planta';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDiagnoses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _diagnoses = await _diagnosisService.getDiagnoses();
    } catch (e) {
      _error = 'Error al cargar el historial';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearCurrentDiagnosis() {
    _currentDiagnosis = null;
    notifyListeners();
  }

  Future<Plant?> saveDiagnosisToGarden() async {
    if (_currentDiagnosis == null) return null;

    try {
      final currentDiagnosis = Diagnosis(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        plantName: _currentDiagnosis!.plantName,
        plantSpecies: _currentDiagnosis!.plantSpecies,
        disease: _currentDiagnosis!.disease,
        confidence: _currentDiagnosis!.confidence,
        symptoms: _currentDiagnosis!.symptoms,
        causes: _currentDiagnosis!.causes,
        treatment: _currentDiagnosis!.treatment,
        organicTreatment: _currentDiagnosis!.organicTreatment,
        prevention: _currentDiagnosis!.prevention,
        imageUrl: _selectedImagePath ?? _currentDiagnosis!.imageUrl,
        date: DateTime.now(),
        status: _currentDiagnosis!.status,
      );

      // Si hay plantId, usar ese ID (planta existente)
      // Si no hay plantId, generar un nuevo ID único
      final plantId = _plantId ?? 'plant_${DateTime.now().millisecondsSinceEpoch}';

      final plant = Plant(
        id: plantId,
        name: currentDiagnosis.plantName,
        species: currentDiagnosis.plantSpecies,
        status: _getStatusFromDiagnosis(currentDiagnosis.status),
        imageUrl: currentDiagnosis.imageUrl,
        lastDiagnosisDate: DateTime.now(),
        nextCare: 'Revisar tratamiento',
        wateringFrequency: 'Cada 2-3 días',
        lightRequirement: 'Luz directa',
        humidity: '50-60%',
        diagnosisHistory: [currentDiagnosis],
      );

      return plant;
    } catch (e) {
      _error = 'Error al guardar en el jardín';
      return null;
    }
  }

  String _getStatusFromDiagnosis(String diagnosisStatus) {
    switch (diagnosisStatus.toLowerCase()) {
      case 'leve':
        return 'Necesita atención';
      case 'moderado':
        return 'Necesita atención';
      case 'grave':
        return 'Enferma';
      case 'saludable':
        return 'Saludable';
      default:
        return 'Necesita atención';
    }
  }
}