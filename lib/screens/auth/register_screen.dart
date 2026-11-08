import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/perfil_provider.dart';
import '../legal/terminos_screen.dart';
import '../../widgets/common/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

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
  bool _aceptaTerminos = false;
  String? _distrito;

  @override
  void initState() {
    super.initState();
    // La lista de distritos es publica: se puede pedir sin haber entrado.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PerfilProvider>().cargarDistritos();
    });
  }

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

    if (_distrito == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Elige tu distrito'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    if (!_aceptaTerminos) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Debes aceptar los términos y condiciones'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.registrar(
      nombre: _nombreCtrl.text,
      email: _emailCtrl.text,
      password: _passCtrl.text,
      distrito: _distrito!,
    );

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Cuenta creada con éxito'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } else {
      // El mensaje se lee ANTES de limpiarlo: al reves, limpiarError lo
      // pone en null y siempre se mostraba el texto generico, de modo que
      // el aviso de correo duplicado nunca llegaba a verse.
      final mensaje = auth.error ?? 'No se pudo crear la cuenta.';
      auth.limpiarError();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(mensaje),
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
    final estiloInput = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: AppColors.textPrimary,
    );

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
                Text(
                  'Crea tu cuenta',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.displayMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Empieza a cuidar tu huerto urbano',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 40),

                // Campo: Nombre
                TextFormField(
                  controller: _nombreCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  style: estiloInput,
                  decoration: _campo('Nombre', Icons.person_outline),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? 'El nombre es obligatorio'
                      : null,
                ),
                const SizedBox(height: 18),

                // Campo: Correo
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  style: estiloInput,
                  decoration: _campo('Correo', Icons.mail_outline),
                  validator: (v) {
                    final texto = (v ?? '').trim();
                    if (texto.isEmpty) return 'Ingrese su correo electrónico';
                    if (!texto.contains('@') || !texto.contains('.')) {
                      return 'Ingrese un correo electrónico válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Campo: Contraseña
                TextFormField(
                  controller: _passCtrl,
                  obscureText: !_verPassword,
                  textInputAction: TextInputAction.next,
                  style: estiloInput,
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
                    if (texto.isEmpty) return 'Ingrese su contraseña';
                    if (texto.length < 8) {
                      return 'La contraseña debe tener como mínimo 8 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Campo: Confirmar contraseña
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: !_verPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _registrar(),
                  style: estiloInput,
                  decoration: _campo(
                    'Repite la contraseña',
                    Icons.lock_outline,
                  ),
                  validator: (v) => v != _passCtrl.text
                      ? 'Las contraseñas no coinciden'
                      : null,
                ),
                const SizedBox(height: 18),

                _selectorDistrito(),
                const SizedBox(height: 24),

                _casillaTerminos(),
                const SizedBox(height: 20),

                PrimaryButton(
                  text: 'Crear cuenta',
                  isLoading: cargando,
                  onPressed: _registrar,
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿Ya tienes cuenta? ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
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

  /// Aceptacion explicita antes de crear la cuenta. El enlace abre el
  /// texto completo sin sacar al usuario del formulario, para que no pierda
  /// lo que ya escribio.
  /// Distrito de residencia.
  ///
  /// Se pide al crear la cuenta porque fija el clima con el que el backend
  /// calcula el riego: sin el, las primeras plantas se programarian con el
  /// de Lima centro. Es un selector y no texto libre porque el backend
  /// valida contra su catalogo y rechaza cualquier otra cosa.
  Widget _selectorDistrito() {
    final distritos = context.watch<PerfilProvider>().distritos;

    if (distritos.isEmpty) {
      return InputDecorator(
        decoration: _campo('Distrito', Icons.place_outlined),
        child: Text(
          'Cargando distritos...',
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: 14,
            color: AppColors.textTertiary,
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _distrito,
      isExpanded: true,
      decoration: _campo('Distrito', Icons.place_outlined),
      hint: const Text('Elige tu distrito'),
      items: distritos
          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
          .toList(),
      onChanged: (valor) => setState(() => _distrito = valor),
      validator: (v) => v == null ? 'Elige tu distrito' : null,
    );
  }

  Widget _casillaTerminos() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _aceptaTerminos,
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (valor) =>
                setState(() => _aceptaTerminos = valor ?? false),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'He leído y acepto los ',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TerminosScreen(),
                    ),
                  ),
                  child: Text(
                    'términos y condiciones',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

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