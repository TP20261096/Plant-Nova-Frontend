import 'package:flutter/material.dart';

class Diagnosis {
  final String id;
  final String plantName;
  final String plantSpecies;
  final String disease;
  final String confidence;
  final List<String> symptoms;
  final List<String> causes;
  final List<String> treatment;
  final List<String> organicTreatment;
  final List<String> prevention;
  final String? imageUrl;
  final DateTime date;
  final String status;

  const Diagnosis({
    required this.id,
    required this.plantName,
    required this.plantSpecies,
    required this.disease,
    required this.confidence,
    required this.symptoms,
    required this.causes,
    required this.treatment,
    required this.organicTreatment,
    required this.prevention,
    this.imageUrl,
    required this.date,
    required this.status,
  });

  factory Diagnosis.fromJson(Map<String, dynamic> json) {
    return Diagnosis(
      id: json['id'] as String,
      plantName: json['plantName'] as String,
      plantSpecies: json['plantSpecies'] as String,
      disease: json['disease'] as String,
      confidence: json['confidence'] as String,
      symptoms: List<String>.from(json['symptoms'] as List),
      causes: List<String>.from(json['causes'] as List),
      treatment: List<String>.from(json['treatment'] as List),
      organicTreatment: List<String>.from(json['organicTreatment'] as List),
      prevention: List<String>.from(json['prevention'] as List),
      imageUrl: json['imageUrl'] as String?,
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plantName': plantName,
      'plantSpecies': plantSpecies,
      'disease': disease,
      'confidence': confidence,
      'symptoms': symptoms,
      'causes': causes,
      'treatment': treatment,
      'organicTreatment': organicTreatment,
      'prevention': prevention,
      'imageUrl': imageUrl,
      'date': date.toIso8601String(),
      'status': status,
    };
  }

  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case 'saludable':
        return const Color(0xFF4CAF50);
      case 'leve':
        return const Color(0xFFF9A825);
      case 'grave':
        return const Color(0xFFD84315);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}