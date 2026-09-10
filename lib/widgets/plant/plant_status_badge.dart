import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../models/plant.dart';

class PlantStatusBadge extends StatelessWidget {
  final String status;

  const PlantStatusBadge({
    Key? key,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _getStatusColor();
    final IconData statusIcon = _getStatusIcon();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 14,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'saludable':
        return AppColors.success;
      case 'necesita atención':
        return AppColors.warning;
      case 'enferma':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon() {
    switch (status.toLowerCase()) {
      case 'saludable':
        return Icons.check_circle;
      case 'necesita atención':
        return Icons.warning;
      case 'enferma':
        return Icons.error;
      default:
        return Icons.help;
    }
  }
}