import 'package:flutter/material.dart';

/// Geometria del texto de la app: tamano, peso y espaciado.
///
/// Estas constantes NO fijan color a proposito. Antes cada una llevaba
/// incrustado un color del tema claro (AppColors.textPrimary, #1B1B1B), asi
/// que cualquier Text que no hiciera .copyWith(color: ...) quedaba en texto
/// oscuro sobre fondo oscuro en modo noche. El color lo aporta el textTheme
/// de AppTheme, que si distingue entre claro y oscuro, y cada pantalla solo
/// declara un color cuando quiere apartarse de ese valor.
class AppTextStyles {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodyLarge = TextStyle(fontSize: 16);

  static const TextStyle bodyMedium = TextStyle(fontSize: 14);

  static const TextStyle bodySmall = TextStyle(fontSize: 12);

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
}
