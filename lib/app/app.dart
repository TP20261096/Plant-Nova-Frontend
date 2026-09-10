import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'routes.dart';
import 'theme/app_theme.dart';

class PlantNovaApp extends StatefulWidget {
  const PlantNovaApp({Key? key}) : super(key: key);

  @override
  State<PlantNovaApp> createState() => _PlantNovaAppState();
}

class _PlantNovaAppState extends State<PlantNovaApp> {
  AuthProvider? _auth;
  EstadoSesion _estadoPrevio = EstadoSesion.comprobando;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_auth != null) return;
    _auth = context.read<AuthProvider>();
    _estadoPrevio = _auth!.estado;
    _auth!.addListener(_alCambiarSesion);
  }

  /// Si la sesion muere estando el usuario dentro de la app (el refresh
  /// fallo en alguna peticion), lo sacamos al login desde aca. Asi ninguna
  /// pantalla tiene que preocuparse por ese caso.
  void _alCambiarSesion() {
    final estado = _auth!.estado;
    if (estado == _estadoPrevio) return;

    final salio = _estadoPrevio == EstadoSesion.autenticado &&
        estado == EstadoSesion.noAutenticado;
    _estadoPrevio = estado;

    if (salio) {
      AppRoutes.navigatorKey.currentState
          ?.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    }
  }

  @override
  void dispose() {
    _auth?.removeListener(_alCambiarSesion);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'PlantNova',
          debugShowCheckedModeBanner: false,
          navigatorKey: AppRoutes.navigatorKey,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: AppRoutes.splash,
          routes: AppRoutes.routes,
        );
      },
    );
  }
}