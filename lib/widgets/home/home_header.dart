import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';

/// Saludo del menu Inicio.
///
/// Antes leia el nombre de SharedPreferences con la clave 'user_name', que
/// nadie escribia nunca: el saludo siempre decia "Usuario". Ahora sale del
/// usuario autenticado, y se actualiza solo si cambia el nombre en Perfil.
class HomeHeader extends StatelessWidget {
  const HomeHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final usuario = context.watch<AuthProvider>().usuario;

    // Solo el primer nombre: "Emerson Rodriguez Vela" no entra en una linea.
    final nombre = (usuario?.nombre ?? '').trim().split(' ').first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${_saludo()}, ',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: nombre.isEmpty ? 'Usuario' : nombre,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '¿Cómo están tus cultivos hoy?',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _saludo() {
    final hora = DateTime.now().hour;
    if (hora >= 5 && hora < 12) return 'Buenos días';
    if (hora >= 12 && hora < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }
}