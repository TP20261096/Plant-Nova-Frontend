import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _verPassword = false;

  @override
  void initState() {
    super.initState();
    // Si llegamos aca por sesion expirada, mostramos ese aviso una sola vez.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final error = context.read<AuthProvider>().error;
      if (error != null && mounted) _mostrarError(error);
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.iniciarSesion(_emailCtrl.text, _passCtrl.text);

    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } else {
      _mostrarError(auth.error ?? 'No se pudo iniciar sesion.');
    }
  }

  void _mostrarError(String mensaje) {
    context.read<AuthProvider>().limpiarError();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final cargando = context.watch<AuthProvider>().cargando;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _logo(),
                  const SizedBox(height: 32),
                  Text('Bienvenido de vuelta',
                      style: AppTextStyles.displayMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('Ingresa para ver tu huerto',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    decoration: _campo('Correo', Icons.mail_outline),
                    validator: (v) {
                      final texto = (v ?? '').trim();
                      if (texto.isEmpty) return 'Ingresa tu correo';
                      if (!texto.contains('@') || !texto.contains('.')) {
                        return 'Correo no valido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: !_verPassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _entrar(),
                    decoration: _campo(
                      'Contrasena',
                      Icons.lock_outline,
                      sufijo: IconButton(
                        icon: Icon(
                          _verPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textTertiary,
                        ),
                        onPressed: () =>
                            setState(() => _verPassword = !_verPassword),
                      ),
                    ),
                    validator: (v) =>
                    (v ?? '').isEmpty ? 'Ingresa tu contrasena' : null,
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: 'Iniciar sesion',
                    isLoading: cargando,
                    onPressed: _entrar,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('No tienes cuenta?', style: AppTextStyles.bodyMedium),
                      TextButton(
                        onPressed: cargando
                            ? null
                            : () => Navigator.pushNamed(
                            context, AppRoutes.registro),
                        child: const Text(
                          'Registrate',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _logo() {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.primaryBg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.eco, size: 44, color: AppColors.primary),
      ),
    );
  }

  InputDecoration _campo(String etiqueta, IconData icono, {Widget? sufijo}) {
    return InputDecoration(
      labelText: etiqueta,
      prefixIcon: Icon(icono, color: AppColors.textTertiary),
      suffixIcon: sufijo,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}