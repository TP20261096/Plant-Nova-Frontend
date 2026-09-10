import 'dart:io';
import '../models/diagnosis.dart';

class DiagnosisService {
  List<Diagnosis> _diagnoses = [];

  Future<Diagnosis?> analyzePlantImage(String imagePath) async {
    try {
      // Simular tiempo de análisis
      await Future.delayed(const Duration(seconds: 2));

      // Detectar la planta basándose en el nombre del archivo o ruta
      final detectedPlant = _detectPlantFromImage(imagePath);

      // Crear diagnóstico según la planta detectada
      final diagnosis = _createDiagnosisForPlant(detectedPlant, imagePath);

      return diagnosis;
    } catch (e) {
      print('Error en análisis: $e');
      return null;
    }
  }

  // Método temporal para detectar la planta
  String _detectPlantFromImage(String imagePath) {
    final fileName = imagePath.toLowerCase();

    if (fileName.contains('tomate') || fileName.contains('tomato')) {
      return 'Tomate';
    } else if (fileName.contains('pimiento') || fileName.contains('pepper')) {
      return 'Pimiento';
    } else if (fileName.contains('berenjena') || fileName.contains('eggplant')) {
      return 'Berenjena';
    } else if (fileName.contains('repollo') || fileName.contains('cabbage')) {
      return 'Repollo';
    } else if (fileName.contains('citrico') || fileName.contains('citrus') || fileName.contains('naranja') || fileName.contains('limon')) {
      return 'Cítricos';
    } else if (fileName.contains('maiz') || fileName.contains('corn')) {
      return 'Maíz';
    } else if (fileName.contains('lechuga') || fileName.contains('lettuce')) {
      return 'Lechuga';
    } else if (fileName.contains('papa') || fileName.contains('potato')) {
      return 'Papa';
    } else {
      // Por defecto, detectar como planta genérica
      return 'Planta';
    }
  }

  // Crear diagnóstico según la planta detectada
  Diagnosis _createDiagnosisForPlant(String plantName, String imagePath) {
    switch (plantName) {
      case 'Tomate':
        return Diagnosis(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          plantName: 'Tomate',
          plantSpecies: 'Solanum lycopersicum',
          disease: 'Mildiú polvoriento',
          confidence: '92%',
          symptoms: [
            'Manchas blancas en las hojas',
            'Hojas amarillentas',
            'Crecimiento reducido',
          ],
          causes: [
            'Alta humedad',
            'Mala circulación de aire',
            'Temperaturas moderadas',
          ],
          treatment: [
            'Aplicar fungicida orgánico',
            'Mejorar la ventilación',
            'Reducir la humedad',
          ],
          organicTreatment: [
            'Aplicar bicarbonato de sodio diluido',
            'Usar extracto de ajo',
            'Espolvorear azufre orgánico',
          ],
          prevention: [
            'Mantener buena circulación de aire',
            'Evitar mojar las hojas',
            'Rotar cultivos',
          ],
          imageUrl: imagePath,
          date: DateTime.now(),
          status: 'Leve',
        );

      case 'Pimiento':
        return Diagnosis(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          plantName: 'Pimiento',
          plantSpecies: 'Capsicum annuum',
          disease: 'Marchitez por Fusarium',
          confidence: '88%',
          symptoms: [
            'Marchitez de hojas inferiores',
            'Amarillamiento progresivo',
            'Caída de hojas',
          ],
          causes: [
            'Hongo Fusarium en el suelo',
            'Exceso de humedad',
            'Suelo contaminado',
          ],
          treatment: [
            'Eliminar plantas infectadas',
            'Mejorar drenaje del suelo',
            'Aplicar fungicida biológico',
          ],
          organicTreatment: [
            'Aplicar extracto de cola de caballo',
            'Usar trichoderma como control biológico',
            'Solarizar el suelo',
          ],
          prevention: [
            'Rotar cultivos',
            'Usar sustrato esterilizado',
            'Evitar exceso de riego',
          ],
          imageUrl: imagePath,
          date: DateTime.now(),
          status: 'Moderado',
        );

      case 'Berenjena':
        return Diagnosis(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          plantName: 'Berenjena',
          plantSpecies: 'Solanum melongena',
          disease: 'Mildiú polvoriento',
          confidence: '90%',
          symptoms: [
            'Manchas blancas en las hojas',
            'Hojas amarillentas',
            'Crecimiento reducido',
          ],
          causes: [
            'Alta humedad',
            'Mala circulación de aire',
          ],
          treatment: [
            'Aplicar fungicida orgánico',
            'Mejorar la ventilación',
          ],
          organicTreatment: [
            'Aplicar bicarbonato de sodio diluido',
            'Usar extracto de ajo',
          ],
          prevention: [
            'Mantener buena circulación de aire',
            'Evitar mojar las hojas',
          ],
          imageUrl: imagePath,
          date: DateTime.now(),
          status: 'Leve',
        );

      case 'Lechuga':
        return Diagnosis(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          plantName: 'Lechuga',
          plantSpecies: 'Lactuca sativa',
          disease: 'Pulgones',
          confidence: '85%',
          symptoms: [
            'Insectos en el envés de las hojas',
            'Hojas deformadas',
            'Residuos pegajosos',
          ],
          causes: [
            'Falta de depredadores naturales',
            'Exceso de nitrógeno',
            'Clima cálido',
          ],
          treatment: [
            'Aplicar insecticida orgánico',
            'Introducir mariquitas',
            'Limpiar hojas afectadas',
          ],
          organicTreatment: [
            'Aplicar jabón potásico',
            'Usar extracto de neem',
            'Plantar flores que atraigan depredadores',
          ],
          prevention: [
            'Monitorear regularmente',
            'Fomentar biodiversidad',
            'Evitar exceso de fertilizante',
          ],
          imageUrl: imagePath,
          date: DateTime.now(),
          status: 'Moderado',
        );

      default:
        return Diagnosis(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          plantName: plantName,
          plantSpecies: 'Especie no identificada',
          disease: 'Sin enfermedad detectada',
          confidence: '70%',
          symptoms: [
            'No se detectaron síntomas claros',
            'Se recomienda observación',
          ],
          causes: [
            'Pendiente de análisis',
          ],
          treatment: [
            'Mantener cuidados regulares',
            'Observar evolución',
          ],
          organicTreatment: [
            'Continuar con riego regular',
            'Mantener buena ventilación',
          ],
          prevention: [
            'Monitorear regularmente',
            'Mantener condiciones óptimas',
          ],
          imageUrl: imagePath,
          date: DateTime.now(),
          status: 'Saludable',
        );
    }
  }

  Future<List<Diagnosis>> getDiagnoses() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _diagnoses;
  }

  Future<Diagnosis?> getDiagnosisById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _diagnoses.firstWhere((diagnosis) => diagnosis.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveDiagnosis(Diagnosis diagnosis) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _diagnoses.add(diagnosis);
  }
}