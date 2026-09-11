import 'package:flutter/material.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/diagnosis/upload_plant_screen.dart';
import '../screens/diagnosis/analyzing_screen.dart';
import '../screens/diagnosis/diagnosis_result_screen.dart';
import '../screens/plants/my_plants_screen.dart';
import '../screens/plants/plant_detail_screen.dart';
import '../screens/plants/add_plant_screen.dart';
import '../screens/history/diagnosis_history_screen.dart';
import '../screens/treatments/treatments_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/diagnosis/diagnostico_resultado_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';

class AppRoutes {
  /// Permite navegar sin BuildContext. Lo usa el aviso de sesion expirada,
  /// que puede dispararse desde cualquier peticion en curso.
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  static const String splash = '/';
  static const String login = '/login';
  static const String registro = '/registro';
  static const String diagnosticoResultado = '/diagnostico-resultado';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String uploadPlant = '/upload-plant';
  static const String analyzing = '/analyzing';
  static const String diagnosisResult = '/diagnosis-result';
  static const String myPlants = '/my-plants';
  static const String plantDetail = '/plant-detail';
  static const String addPlant = '/add-plant';
  static const String history = '/history';
  static const String treatments = '/treatments';
  static const String profile = '/profile';
  static const String settings = '/settings';

  // Transición suave (slide desde abajo + fade)
  static Route<T> _slideRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.05);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: SlideTransition(
            position: animation.drive(tween),
            child: child,
          ),
        );
      },
    );
  }

  // Transición de fade simple (para splash y onboarding)
  static Route<T> _fadeRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  // Rutas con transiciones personalizadas
  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    onboarding: (context) => const OnboardingScreen(),
    login: (context) => const LoginScreen(),
    registro: (context) => const RegisterScreen(),
    diagnosticoResultado: (context) => const DiagnosticoResultadoScreen(),
    home: (context) => const HomeScreen(),
    uploadPlant: (context) => const UploadPlantScreen(),
    analyzing: (context) => const AnalyzingScreen(),
    diagnosisResult: (context) => const DiagnosisResultScreen(),
    myPlants: (context) => const MyPlantsScreen(),
    plantDetail: (context) => const PlantDetailScreen(),
    addPlant: (context) => const AddPlantScreen(),
    history: (context) => const DiagnosisHistoryScreen(),
    treatments: (context) => const TreatmentsScreen(),
    profile: (context) => const ProfileScreen(),
    settings: (context) => const SettingsScreen(),
  };

  // Métodos para navegar con transiciones
  static Future<T?> pushSlide<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(context, _slideRoute<T>(page));
  }

  static Future<T?> pushFade<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(context, _fadeRoute<T>(page));
  }

  static Future<T?> pushSlideNamed<T>(
      BuildContext context,
      String routeName, {
        Object? arguments,
      }) {
    final builder = routes[routeName];
    if (builder != null) {
      return Navigator.push<T>(
        context,
        _slideRoute<T>(builder(context)),
      );
    }
    return Future.value(null);
  }
}