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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ───── Header (centrado) ─────
                Text(
                  'Crea tu cuenta',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.displayMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Empieza a cuidar tu huerto urbano',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 40),

                // ───── Campo: Nombre ─────
                TextFormField(
                  controller: _nombreCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: _campo('Nombre', Icons.person_outline),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? 'Ingresa tu nombre'
                      : null,
                ),
                const SizedBox(height: 18),

                // ───── Campo: Correo ─────
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
                      return 'Correo no válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // ───── Campo: Contraseña ─────
                TextFormField(
                  controller: _passCtrl,
                  obscureText: !_verPassword,
                  textInputAction: TextInputAction.next,
                  decoration: _campo(
                    'Contraseña',
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
                    if (texto.isEmpty) return 'Ingresa una contraseña';
                    if (texto.length < 8) return 'Mínimo 8 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // ───── Campo: Confirmar contraseña ─────
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: !_verPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _registrar(),
                  decoration: _campo(
                    'Repite la contraseña',
                    Icons.lock_outline,
                  ),
                  validator: (v) => v != _passCtrl.text
                      ? 'Las contraseñas no coinciden'
                      : null,
                ),
                const SizedBox(height: 36),

                // ───── Botón principal ─────
                PrimaryButton(
                  text: 'Crear cuenta',
                  isLoading: cargando,
                  onPressed: _registrar,
                ),
                const SizedBox(height: 20),

                // ───── Enlace a login ─────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿Ya tienes cuenta?',
                      style: AppTextStyles.bodyMedium,
                    ),
                    TextButton(
                      onPressed: cargando
                          ? null
                          : () => Navigator.pushReplacementNamed(
                          context, AppRoutes.login),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Inicia sesión',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // InputDecoration mejorada
  // ─────────────────────────────────────────────────────────────
  InputDecoration _campo(String etiqueta, IconData icono, {Widget? sufijo}) {
    return InputDecoration(
      labelText: etiqueta,
      labelStyle: const TextStyle(
        color: AppColors.textTertiary,
        fontSize: 14,
      ),
      floatingLabelStyle: const TextStyle(
        color: AppColors.primary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 4, right: 8),
        child: Icon(icono, color: AppColors.textTertiary, size: 22),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 48),
      suffixIcon: sufijo,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.6),
      ),
    );
  }
}