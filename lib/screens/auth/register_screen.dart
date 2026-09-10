import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _verPassword = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final ok = await auth.registrar(
      nombre: _nombreCtrl.text,
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );

    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } else {
      auth.limpiarError();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(auth.error ?? 'No se pudo crear la cuenta.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cargando = context.watch<AuthProvider>().cargando;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Crea tu cuenta', style: AppTextStyles.displayMedium),
                const SizedBox(height: 8),
                Text('Empieza a cuidar tu huerto urbano',
                    style: AppTextStyles.bodyMedium),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nombreCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: _campo('Nombre', Icons.person_outline),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? 'Ingresa tu nombre'
                      : null,
                ),
                const SizedBox(height: 16),
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
                  textInputAction: TextInputAction.next,
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
                  validator: (v) {
                    final texto = v ?? '';
                    if (texto.isEmpty) return 'Ingresa una contrasena';
                    if (texto.length < 8) return 'Minimo 8 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: !_verPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _registrar(),
                  decoration:
                  _campo('Repite la contrasena', Icons.lock_outline),
                  validator: (v) =>
                  v != _passCtrl.text ? 'Las contrasenas no coinciden' : null,
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  text: 'Crear cuenta',
                  isLoading: cargando,
                  onPressed: _registrar,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Ya tienes cuenta?', style: AppTextStyles.bodyMedium),
                    TextButton(
                      onPressed: cargando
                          ? null
                          : () => Navigator.pushReplacementNamed(
                          context, AppRoutes.login),
                      child: const Text(
                        'Inicia sesion',
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