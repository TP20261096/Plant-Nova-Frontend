import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'routes.dart';
import '../providers/theme_provider.dart';

class PlantNovaApp extends StatelessWidget {
  final bool hasSeenOnboarding;

  const PlantNovaApp({
    Key? key,
    required this.hasSeenOnboarding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'PlantNova',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: hasSeenOnboarding ? AppRoutes.home : AppRoutes.splash,
          routes: AppRoutes.routes,
        );
      },
    );
  }
}