import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../app/routes.dart';
import '../../providers/diagnostico_provider.dart';

class AnalyzingScreen extends StatefulWidget {
  const AnalyzingScreen({Key? key}) : super(key: key);

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen>
    with TickerProviderStateMixin { // ← Cambiado a TickerProviderStateMixin
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  final List<String> _analysisMessages = [
    'Analizando tu planta...',
    'Identificando posibles problemas...',
    'Preparando recomendaciones...',
    'Generando diagnóstico...',
  ];

  int _currentMessageIndex = 0;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 2 * 3.14159).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );

    // Controlador para la barra de progreso (4 segundos)
    _progressController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: Curves.linear,
      ),
    );

    _startAnalysis();
    _startMessageRotation();
  }

  Future<void> _startAnalysis() async {
    final provider = context.read<DiagnosticoProvider>();

    if (provider.imagen == null) {
      Navigator.pop(context);
      return;
    }

    _progressController.forward();

    // La peticion sale de inmediato y la animacion corre en paralelo. Antes
    // se esperaban 4,8 segundos y recien despues se llamaba al servicio, asi
    // que el usuario pagaba la animacion mas el tiempo del modelo.
    final analisis = provider.analizar();
    final minimo = Future.delayed(const Duration(milliseconds: 2500));

    final ok = await analisis;
    await minimo;

    if (!mounted) return;

    setState(() {
      _isComplete = true;
    });
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'No se pudo analizar la imagen'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      provider.limpiarError();
      Navigator.pop(context);
      return;
    }

    Navigator.pushReplacementNamed(context, AppRoutes.diagnosticoResultado);
  }

  void _startMessageRotation() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted && !_isComplete) {
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % _analysisMessages.length;
        });
        _startMessageRotation();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animación principal
            SizedBox(
              width: 250,
              height: 250,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Círculo pulsante
                      Container(
                        width: 200 + (_pulseAnimation.value * 40),
                        height: 200 + (_pulseAnimation.value * 40),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(
                            0.1 * (1 - _pulseAnimation.value),
                          ),
                        ),
                      ),
                      // Icono giratorio o check cuando está listo
                      Transform.rotate(
                        angle: _isComplete ? 0 : _rotateAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _isComplete
                                  ? [
                                AppColors.success,
                                AppColors.primaryLight,
                              ]
                                  : [
                                AppColors.primary,
                                AppColors.primaryLight,
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_isComplete ? AppColors.success : AppColors.primary)
                                    .withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isComplete ? Icons.check : Icons.local_florist,
                            color: Colors.white,
                            size: _isComplete ? 50 : 60,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 40),

            // Mensaje de análisis
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _isComplete ? 'Diagnóstico listo' : _analysisMessages[_currentMessageIndex],
                style: AppTextStyles.titleLarge.copyWith(
                  color: _isComplete
                      ? AppColors.success
                      : isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: _isComplete ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              _isComplete ? 'Abriendo tu reporte...' : 'Esto puede tomar unos segundos...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 40),

            // Barra de progreso sincronizada
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    backgroundColor: isDark ? AppColors.darkSurface : AppColors.primaryBg,
                    value: _isComplete ? 1.0 : _progressAnimation.value,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isComplete ? AppColors.success : AppColors.primaryLight,
                    ),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}