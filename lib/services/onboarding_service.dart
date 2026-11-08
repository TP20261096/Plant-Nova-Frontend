import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _onboardingKey = 'has_seen_onboarding';

  Future<bool> hasSeenOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingKey) ?? false;
    } catch (_) {
      // Sin preferencias legibles asumimos que no lo ha visto: mostrar el
      // onboarding de mas es preferible a saltarselo en la primera apertura.
      return false;
    }
  }

  Future<void> setOnboardingSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, true);
    } catch (_) {
      // Si no se puede guardar, el onboarding se volvera a mostrar. No es
      // motivo para interrumpir el arranque de la app.
    }
  }
}