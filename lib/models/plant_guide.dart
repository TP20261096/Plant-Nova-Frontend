import 'package:flutter/material.dart';

class PlantGuide {
  final String id;
  final String name;
  final String scientificName;
  final String description;
  final String imageUrl;
  final String icon;
  final List<String> careTips;
  final Map<String, String> requirements;
  final List<String> commonDiseases;
  final List<String> organicTreatments;
  final String harvestTime;
  final String plantingSeason;

  const PlantGuide({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.description,
    required this.imageUrl,
    required this.icon,
    required this.careTips,
    required this.requirements,
    required this.commonDiseases,
    required this.organicTreatments,
    required this.harvestTime,
    required this.plantingSeason,
  });
}