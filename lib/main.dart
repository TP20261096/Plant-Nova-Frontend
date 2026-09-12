import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/planta_provider.dart';
import 'providers/guia_provider.dart';
import 'providers/actividad_provider.dart';
import 'providers/diagnostico_provider.dart';
import 'providers/perfil_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Ya no leemos el onboarding aca: la app siempre arranca en el splash y es
  // el splash quien decide a donde ir, porque ahora ademas tiene que
  // comprobar si la sesion guardada sigue viva.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => PlantaProvider()),
        ChangeNotifierProvider(create: (_) => GuiaProvider()),
        ChangeNotifierProvider(create: (_) => ActividadProvider()),
        ChangeNotifierProvider(create: (_) => DiagnosticoProvider()),
        ChangeNotifierProvider(create: (_) => PerfilProvider()),
      ],
      child: const PlantNovaApp(),
    ),
  );
}