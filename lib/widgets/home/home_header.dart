import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final usuario = context.watch<AuthProvider>().usuario;
    final nombre = (usuario?.nombre ?? '').trim().split(' ').first;

    return Container(
      width: double.infinity,
      // ✅ Más espacio vertical
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: RichText(
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
    );
  }

  String _saludo() {
    final hora = DateTime.now().hour;
    if (hora >= 5 && hora < 12) return 'Buenos días';
    if (hora >= 12 && hora < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }
}