/// Utilidades de parseo para los modelos.
///
/// El objetivo es que un campo inesperado (un null donde esperabamos texto,
/// un entero donde esperabamos decimal) no reviente la pantalla entera.
class Json {
  Json._();

  /// Texto obligatorio. Si viene null devuelve [siNulo] en vez de lanzar.
  static String texto(dynamic valor, {String siNulo = ''}) {
    if (valor == null) return siNulo;
    return valor.toString();
  }

  static String? textoNulo(dynamic valor) {
    if (valor == null) return null;
    final s = valor.toString();
    return s.isEmpty ? null : s;
  }

  static int entero(dynamic valor, {int siNulo = 0}) {
    if (valor == null) return siNulo;
    if (valor is int) return valor;
    if (valor is num) return valor.round();
    return int.tryParse(valor.toString()) ?? siNulo;
  }

  static int? enteroNulo(dynamic valor) {
    if (valor == null) return null;
    return entero(valor);
  }

  /// El backend manda confianza como 78.76, pero un 80 exacto puede llegar
  /// como entero. Hay que aceptar los dos.
  static double decimal(dynamic valor, {double siNulo = 0}) {
    if (valor == null) return siNulo;
    if (valor is num) return valor.toDouble();
    return double.tryParse(valor.toString()) ?? siNulo;
  }

  static bool booleano(dynamic valor, {bool siNulo = false}) {
    if (valor == null) return siNulo;
    if (valor is bool) return valor;
    final s = valor.toString().toLowerCase();
    return s == 'true' || s == '1';
  }

  /// Acepta tanto "2026-08-01" como "2026-09-09T15:00:00Z".
  static DateTime? fecha(dynamic valor) {
    if (valor == null) return null;
    return DateTime.tryParse(valor.toString())?.toLocal();
  }

  static DateTime fechaObligatoria(dynamic valor) {
    return fecha(valor) ?? DateTime.now();
  }

  /// Convierte una fecha al formato que espera el backend: 2026-08-01.
  static String aFechaApi(DateTime fecha) {
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');
    return '${fecha.year}-$mes-$dia';
  }

  /// Lista de objetos. Si el campo falta o no es una lista, devuelve vacia.
  static List<T> lista<T>(dynamic valor, T Function(Map<String, dynamic>) mapa) {
    if (valor is! List) return <T>[];
    return valor
        .whereType<Map>()
        .map((e) => mapa(Map<String, dynamic>.from(e)))
        .toList();
  }

  static List<String> listaTexto(dynamic valor) {
    if (valor is! List) return <String>[];
    return valor.map((e) => e.toString()).toList();
  }
}