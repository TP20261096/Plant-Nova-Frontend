import 'package:flutter/material.dart';  // ← Agrega este import
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _onboardingKey = 'has_seen_onboarding';
  static const String _userNameKey = 'user_name';
  static const String _themeKey = 'theme_mode';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _languageKey = 'language';

  static StorageService? _instance;
  static SharedPreferences? _prefs;

  // Constructor privado para singleton
  StorageService._();

  // Método para obtener la instancia
  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      _prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // Onboarding
  Future<bool> hasSeenOnboarding() async {
    return _prefs?.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingSeen() async {
    await _prefs?.setBool(_onboardingKey, true);
  }

  // Usuario
  Future<String?> getUserName() async {
    return _prefs?.getString(_userNameKey);
  }

  Future<void> setUserName(String name) async {
    await _prefs?.setString(_userNameKey, name);
  }

  // Tema
  Future<String?> getThemeMode() async {
    return _prefs?.getString(_themeKey);
  }

  Future<void> setThemeMode(String mode) async {
    await _prefs?.setString(_themeKey, mode);
  }

  // Notificaciones
  Future<bool> getNotificationsEnabled() async {
    return _prefs?.getBool(_notificationsKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs?.setBool(_notificationsKey, enabled);
  }

  // Idioma
  Future<String?> getLanguage() async {
    return _prefs?.getString(_languageKey);
  }

  Future<void> setLanguage(String language) async {
    await _prefs?.setString(_languageKey, language);
  }
}