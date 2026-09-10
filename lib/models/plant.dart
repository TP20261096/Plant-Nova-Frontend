import 'package:flutter/material.dart';
import 'diagnosis.dart';

class Plant {
  final String id;
  final String name;
  final String species;
  final String status;
  final String? imageUrl;
  final DateTime? lastDiagnosisDate;
  final String? nextCare;
  final String? wateringFrequency;
  final String? lightRequirement;
  final String? humidity;
  final List<Diagnosis>? diagnosisHistory;

  const Plant({
    required this.id,
    required this.name,
    required this.species,
    required this.status,
    this.imageUrl,
    this.lastDiagnosisDate,
    this.nextCare,
    this.wateringFrequency,
    this.lightRequirement,
    this.humidity,
    this.diagnosisHistory,
  });

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'] as String,
      name: json['name'] as String,
      species: json['species'] as String,
      status: json['status'] as String,
      imageUrl: json['imageUrl'] as String?,
      lastDiagnosisDate: json['lastDiagnosisDate'] != null
          ? DateTime.parse(json['lastDiagnosisDate'] as String)
          : null,
      nextCare: json['nextCare'] as String?,
      wateringFrequency: json['wateringFrequency'] as String?,
      lightRequirement: json['lightRequirement'] as String?,
      humidity: json['humidity'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'status': status,
      'imageUrl': imageUrl,
      'lastDiagnosisDate': lastDiagnosisDate?.toIso8601String(),
      'nextCare': nextCare,
      'wateringFrequency': wateringFrequency,
      'lightRequirement': lightRequirement,
      'humidity': humidity,
    };
  }

  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'saludable':
        return const Color(0xFF4CAF50);
      case 'necesita atención':
        return const Color(0xFFF9A825);
      case 'enferma':
        return const Color(0xFFD84315);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData getStatusIcon() {
    switch (status.toLowerCase()) {
      case 'saludable':
        return Icons.check_circle;
      case 'necesita atención':
        return Icons.warning;
      case 'enferma':
        return Icons.error;
      default:
        return Icons.help;
    }
  }
}