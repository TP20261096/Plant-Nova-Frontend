/// Error devuelto por el backend o por la red.
///
/// El backend responde siempre {"detail": "mensaje"}, apto para mostrar
/// directamente al usuario, asi que [mensaje] se puede pintar tal cual en un
/// SnackBar sin traducirlo.
class ApiException implements Exception {
  /// Codigo HTTP. 0 significa que la peticion nunca llego (sin red, backend
  /// apagado, URL mal escrita).
  final int codigo;
  final String mensaje;

  const ApiException(this.codigo, this.mensaje);

  /// No hubo respuesta del servidor.
  bool get sinConexion => codigo == 0;

  /// La sesion caduco y el refresh tambien fallo: hay que volver a entrar.
  bool get sesionExpirada => codigo == 401;

  /// Conflicto de estado: ya completada, ya vinculada a otra planta.
  bool get conflicto => codigo == 409;

  bool get noEncontrado => codigo == 404;

  @override
  String toString() => 'ApiException($codigo): $mensaje';
}