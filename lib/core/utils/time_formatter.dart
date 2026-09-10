class TimeFormatter {
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      return 'Ahora';
    }

    if (difference.inMinutes < 1) {
      return 'Hace un momento';
    }

    if (difference.inMinutes < 60) {
      if (difference.inMinutes == 1) {
        return 'Hace 1 minuto';
      }
      return 'Hace ${difference.inMinutes} minutos';
    }

    if (difference.inHours < 24) {
      if (difference.inHours == 1) {
        return 'Hace 1 hora';
      }
      return 'Hace ${difference.inHours} horas';
    }

    if (difference.inDays < 30) {
      if (difference.inDays == 1) {
        return 'Hace 1 día';
      }
      return 'Hace ${difference.inDays} días';
    }

    if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      if (months == 1) {
        return 'Hace 1 mes';
      }
      return 'Hace $months meses';
    }

    final years = (difference.inDays / 365).floor();
    if (years == 1) {
      return 'Hace 1 año';
    }
    return 'Hace $years años';
  }
}