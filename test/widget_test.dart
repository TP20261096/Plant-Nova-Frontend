// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:plantnova/app/app.dart';
import 'package:plantnova/providers/plant_provider.dart';
import 'package:plantnova/providers/diagnosis_provider.dart';

void main() {
  testWidgets('PlantNova app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PlantProvider()),
          ChangeNotifierProvider(create: (_) => DiagnosisProvider()),
        ],
        child: const PlantNovaApp(hasSeenOnboarding: true),
      ),
    );

    // Wait for animations to complete
    await tester.pumpAndSettle();

    // Verify that the app loads without errors
    expect(find.byType(PlantNovaApp), findsOneWidget);

    // Verify that the home screen is shown (since hasSeenOnboarding is true)
    expect(find.text('PlantNova'), findsWidgets);
  });

  testWidgets('PlantNova shows onboarding for new users', (WidgetTester tester) async {
    // Build our app with hasSeenOnboarding = false
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PlantProvider()),
          ChangeNotifierProvider(create: (_) => DiagnosisProvider()),
        ],
        child: const PlantNovaApp(hasSeenOnboarding: false),
      ),
    );

    // Wait for splash screen animation
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Verify that onboarding screen is shown
    expect(find.text('Conoce mejor tus plantas'), findsOneWidget);
    expect(find.text('Saltar'), findsOneWidget);
  });
}