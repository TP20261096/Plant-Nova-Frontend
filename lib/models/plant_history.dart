import 'diagnosis.dart';

class PlantHistory {
  final String plantId;
  final List<Diagnosis> diagnoses;
  final List<String> careTips;
  final Map<String, DateTime> careSchedule;

  const PlantHistory({
    required this.plantId,
    required this.diagnoses,
    required this.careTips,
    required this.careSchedule,
  });

  factory PlantHistory.empty(String plantId) {
    return PlantHistory(
      plantId: plantId,
      diagnoses: [],
      careTips: [],
      careSchedule: {},
    );
  }
}