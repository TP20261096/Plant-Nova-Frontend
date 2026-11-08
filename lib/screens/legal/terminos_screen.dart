import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

/// Terminos, condiciones y tratamiento de datos.
///
/// Se abre desde el registro y desde Configuracion > Privacidad. El
/// contenido describe lo que la aplicacion hace de verdad: si cambia el
/// comportamiento, hay que actualizar este texto.
class TerminosScreen extends StatelessWidget {
  const TerminosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Términos y condiciones'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _parrafo(
            isDark,
            'Al crear una cuenta en PlantNova aceptas las condiciones '
            'descritas a continuación. Te recomendamos leerlas antes de '
            'continuar.',
          ),
          _seccion(isDark, 'Qué hace la aplicación'),
          _parrafo(
            isDark,
            'PlantNova analiza fotografías de plantas con un modelo de '
            'visión computacional para identificar posibles enfermedades y '
            'sugerir tratamientos y cuidados. El resultado es orientativo y '
            'no sustituye el criterio de un ingeniero agrónomo. Las '
            'decisiones sobre el cultivo son responsabilidad del usuario.',
          ),
          _seccion(isDark, 'Datos que se recogen'),
          _vineta(isDark, 'Nombre y correo electrónico, para identificar tu '
              'cuenta y permitirte iniciar sesión.'),
          _vineta(isDark, 'Distrito de Lima Metropolitana, para obtener el '
              'clima con el que se calcula el riego de tus plantas.'),
          _vineta(isDark, 'Fotografías que tomas o eliges, junto con el '
              'diagnóstico que genera el modelo.'),
          _vineta(isDark, 'Datos de tus plantas: nombre, ubicación en el '
              'hogar, etapa y registro de riegos y tratamientos.'),
          _seccion(isDark, 'Permisos del dispositivo'),
          _vineta(isDark, 'Cámara: solo se usa cuando eliges tomar una '
              'fotografía para analizar una planta.'),
          _vineta(isDark, 'Galería: solo se usa cuando eliges una imagen ya '
              'guardada para analizarla.'),
          _parrafo(
            isDark,
            'La aplicación no accede a tu ubicación. El clima se obtiene a '
            'partir del distrito que registras en tu perfil.',
          ),
          _seccion(isDark, 'Uso y conservación'),
          _parrafo(
            isDark,
            'Tus imágenes y diagnósticos se almacenan de forma privada y '
            'solo son accesibles desde tu cuenta. No se comparten con '
            'terceros ni se usan con fines publicitarios.',
          ),
          _seccion(isDark, 'Tus derechos'),
          _parrafo(
            isDark,
            'Puedes editar tus datos desde la sección Mi perfil y eliminar '
            'tu cuenta en cualquier momento. Al eliminarla se borran de '
            'forma permanente tus plantas, diagnósticos, actividades e '
            'imágenes, sin posibilidad de recuperarlos.',
          ),
          _parrafo(
            isDark,
            'El tratamiento de datos personales se rige por la Ley N.º 29733, '
            'Ley de Protección de Datos Personales, y su reglamento.',
          ),
          const SizedBox(height: 16),
          _parrafo(
            isDark,
            'PlantNova es un proyecto académico desarrollado como trabajo de '
            'fin de carrera. Versión 1.0.0.',
            tenue: true,
          ),
        ],
      ),
    );
  }

  Widget _seccion(bool isDark, String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 8),
      child: Text(
        texto,
        style: AppTextStyles.titleMedium.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _parrafo(bool isDark, String texto, {bool tenue = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texto,
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: 13,
          height: 1.55,
          fontStyle: tenue ? FontStyle.italic : FontStyle.normal,
          color: tenue
              ? AppColors.textTertiary
              : (isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _vineta(bool isDark, String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•  ',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 13,
              color: AppColors.primary,
            ),
          ),
          Expanded(
            child: Text(
              texto,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                height: 1.5,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
