import 'package:flutter/material.dart';

class AppColors {
  // Colores principales
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF66BB6A);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryBg = Color(0xFFE8F5E9);

  // Fondos
  static const Color background = Color(0xFFF7FAF7);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // Textos
  static const Color textPrimary = Color(0xFF1B1B1B);
  static const Color textSecondary = Color(0xFF667066);
  static const Color textTertiary = Color(0xFF9E9E9E);

  // Estados
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFD84315);
  static const Color success = Color(0xFF4CAF50);
  static const Color info = Color(0xFF2196F3);

  // Dark theme - Mejorados
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color darkPrimaryBg = Color(0xFF1B3A1B); // Verde oscuro para fondos
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkTextTertiary = Color(0xFF808080);
  static const Color darkBorder = Color(0xFF3A3A3A);

  // ─── Colores de texto resueltos por tema ───────────────────────────
  // Las constantes de arriba son del tema claro. Usarlas directamente en
  // una pantalla que sigue el tema deja texto oscuro sobre fondo oscuro en
  // modo noche. Estos tres helpers eligen la variante correcta.

  static bool _oscuro(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  /// Color del texto principal segun el tema activo.
  static Color texto(BuildContext c) =>
      _oscuro(c) ? darkTextPrimary : textPrimary;

  /// Color del texto secundario segun el tema activo.
  static Color textoSuave(BuildContext c) =>
      _oscuro(c) ? darkTextSecondary : textSecondary;

  /// Color del texto terciario segun el tema activo.
  static Color textoTenue(BuildContext c) =>
      _oscuro(c) ? darkTextTertiary : textTertiary;

  /// Color de los enlaces. Colors.blue sobre una superficie oscura queda en
  /// 3:1; estas dos variantes pasan de 6:1 en su tema.
  static Color enlace(BuildContext c) =>
      _oscuro(c) ? const Color(0xFF82B1FF) : const Color(0xFF1565C0);
}