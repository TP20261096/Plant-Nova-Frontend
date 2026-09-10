import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'providers/plant_provider.dart';
import 'providers/diagnosis_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/theme_provider.dart';
import 'services/onboarding_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final onboardingService = OnboardingService();
  final hasSeenOnboarding = await onboardingService.hasSeenOnboarding();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => PlantProvider()),
        ChangeNotifierProvider(create: (_) => DiagnosisProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
      ],
      child: PlantNovaApp(hasSeenOnboarding: hasSeenOnboarding),
    ),
  );
}