import 'package:flutter/material.dart';
import '/app/routes.dart';
import '/app/theme/app_colors.dart';
import '/services/onboarding_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final OnboardingService _onboardingService = OnboardingService();

  int _paginaActual = 0;

  // Contenido de cada slide. Editalo a tu gusto.
  static const List<_OnboardingItem> _items = [
    _OnboardingItem(
      icon: Icons.eco,
      titulo: 'Bienvenido a PlantNova',
      descripcion:
      'Tu asistente personal para cuidar y mantener saludables tus plantas.',
    ),
    _OnboardingItem(
      icon: Icons.camera_alt,
      titulo: 'Diagnostica con IA',
      descripcion:
      'Sube una foto de tu planta y detecta enfermedades o plagas al instante.',
    ),
    _OnboardingItem(
      icon: Icons.water_drop,
      titulo: 'Cuidados personalizados',
      descripcion:
      'Recibe recordatorios de riego y guías adaptadas a cada una de tus plantas.',
    ),
    _OnboardingItem(
      icon: Icons.rocket_launch,
      titulo: '¡Empecemos!',
      descripcion:
      'Crea tu cuenta o inicia sesión para comenzar a cuidar tus plantas.',
    ),
  ];

  bool get _esUltimaPagina => _paginaActual == _items.length - 1;

  Future<void> _finalizarOnboarding() async {
    await _onboardingService.setOnboardingSeen();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
          (_) => false,
    );
  }

  void _siguiente() {
    if (_esUltimaPagina) {
      _finalizarOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Botón "Saltar" arriba a la derecha
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _esUltimaPagina ? null : _finalizarOnboarding,
                  child: Text(
                    _esUltimaPagina ? '' : 'Saltar',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // Carrusel de slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) {
                  setState(() => _paginaActual = index);
                },
                itemBuilder: (context, index) {
                  return _OnboardingSlide(item: _items[index]);
                },
              ),
            ),

            // Indicadores de puntos
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _items.length,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _paginaActual == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _paginaActual == index
                        ? AppColors.primary
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Botón principal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _siguiente,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _esUltimaPagina ? 'Empezar' : 'Siguiente',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Widget interno para cada slide
// ──────────────────────────────────────────────────────────────

class _OnboardingSlide extends StatelessWidget {
  final _OnboardingItem item;

  const _OnboardingSlide({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícono dentro de un círculo
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              size: 80,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 40),

          Text(
            item.titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            item.descripcion,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Modelo de datos para cada slide
// ──────────────────────────────────────────────────────────────

class _OnboardingItem {
  final IconData icon;
  final String titulo;
  final String descripcion;

  const _OnboardingItem({
    required this.icon,
    required this.titulo,
    required this.descripcion,
  });
}