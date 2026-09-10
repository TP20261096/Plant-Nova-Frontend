/// Usuario tal como lo devuelve /auth/register, /auth/login y /auth/me.
///
/// Es la version minima de la cuenta. Los datos de configuracion
/// (foto, distrito, notificaciones) llegan por GET /profile y van en otro
/// modelo, porque ese endpoint devuelve mas campos.
class Usuario {
  final String id;
  final String email;
  final String nombre;

  const Usuario({
    required this.id,
    required this.email,
    required this.nombre,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String,
      email: json['email'] as String,
      nombre: (json['nombre'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'nombre': nombre,
  };

  /// Iniciales para el avatar cuando no hay foto: "Ana Perez" -> "AP".
  String get iniciales {
    final partes = nombre.trim().split(RegExp(r'\s+'))
      ..removeWhere((p) => p.isEmpty);
    if (partes.isEmpty) return email.isNotEmpty ? email[0].toUpperCase() : '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes[1][0]).toUpperCase();
  }
}