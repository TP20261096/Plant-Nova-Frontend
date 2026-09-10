import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/app/theme/app_colors.dart';
import '/app/routes.dart';
import '/providers/auth_provider.dart';
import '/services/onboarding_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    _navigateToNextScreen();
  }

  /// Tiempo minimo que se ve el splash, para que no parpadee cuando el
  /// backend responde rapido.
  static const Duration _minimoEnPantalla = Duration(milliseconds: 1800);

  Future<void> _navigateToNextScreen() async {
    final inicio = DateTime.now();
    final auth = context.read<AuthProvider>();

    final hasSeenOnboarding = await OnboardingService().hasSeenOnboarding();
    // Pregunta al backend si la sesion guardada sigue siendo valida.
    await auth.comprobarSesion();

    final transcurrido = DateTime.now().difference(inicio);
    if (transcurrido < _minimoEnPantalla) {
      await Future.delayed(_minimoEnPantalla - transcurrido);
    }

    if (!mounted) return;

    final String destino;
    if (!hasSeenOnboarding) {
      destino = AppRoutes.onboarding;
    } else if (auth.autenticado) {
      destino = AppRoutes.home;
    } else {
      destino = AppRoutes.login;
    }

    Navigator.pushReplacementNamed(context, destino);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo o icono de la app
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.eco,
                    size: 60,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'PlantNova',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cuida tus plantas naturalmente',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 40),
                // Indicador de carga
                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.8),
                    ),
                    strokeWidth: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}