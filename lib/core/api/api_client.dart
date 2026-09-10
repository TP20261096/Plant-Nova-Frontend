import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../config/api_config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Unico punto por el que la app habla con el backend.
///
/// Se encarga de tres cosas que si no, habria que repetir en cada pantalla:
///  - poner el header Authorization con el access_token,
///  - cuando el backend responde 401, pedir /auth/refresh y reintentar una vez,
///  - convertir cualquier respuesta de error en una [ApiException] con el
///    texto de "detail" listo para mostrar.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final http.Client _http = http.Client();
  final TokenStorage _tokens = TokenStorage.instance;

  /// Lo llama el cliente cuando el refresh falla y la sesion muere.
  /// AuthProvider lo usa para mandar al usuario al login.
  void Function()? onSesionExpirada;

  /// Si varias peticiones reciben 401 a la vez, todas esperan el mismo
  /// refresh en lugar de disparar cuatro y quemar el refresh_token.
  Future<bool>? _refreshEnCurso;

  /// Endpoints que no llevan token.
  static const Set<String> _publicos = {
    '/auth/register',
    '/auth/login',
    '/auth/refresh',
    '/health',
  };

  // --------------------------------------------------------------- verbos

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _enviar('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body}) =>
      _enviar('POST', path, body: body);

  Future<dynamic> put(String path, {Object? body}) =>
      _enviar('PUT', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) =>
      _enviar('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _enviar('DELETE', path);

  /// Sube un archivo con multipart/form-data. Lo usa POST /diagnose.
  ///
  /// [campo] es el nombre del campo del formulario ("imagen"), [extra] son
  /// los campos de texto que acompanan al archivo (por ejemplo plant_id).
  Future<dynamic> postArchivo(
      String path, {
        required File archivo,
        required String campo,
        Map<String, String> extra = const {},
        bool reintentar = true,
      }) async {
    final peticion = http.MultipartRequest('POST', _uri(path))
      ..headers['Accept'] = 'application/json'
      ..fields.addAll(extra);

    final token = await _tokens.accessToken();
    if (token != null) peticion.headers['Authorization'] = 'Bearer $token';

    peticion.files.add(await http.MultipartFile.fromPath(
      campo,
      archivo.path,
      contentType: _tipoImagen(archivo.path),
    ));

    http.Response respuesta;
    try {
      final streamed =
      await _http.send(peticion).timeout(ApiConfig.timeoutDiagnostico);
      respuesta = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ApiException(0, 'El analisis tardo demasiado. Intenta de nuevo.');
    } catch (e) {
      throw ApiException(0, _mensajeDeRed(e));
    }

    if (respuesta.statusCode == 401 && reintentar) {
      if (await _refrescar()) {
        return postArchivo(path,
            archivo: archivo, campo: campo, extra: extra, reintentar: false);
      }
      await _matarSesion();
    }
    return _procesar(respuesta);
  }

  // ---------------------------------------------------------------- motor

  Future<dynamic> _enviar(
      String metodo,
      String path, {
        Object? body,
        Map<String, dynamic>? query,
        bool reintentar = true,
      }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';

    final necesitaToken = !_publicos.contains(path);
    if (necesitaToken) {
      final token = await _tokens.accessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }

    final uri = _uri(path, query);
    final cuerpo = body == null ? null : jsonEncode(body);

    http.Response respuesta;
    try {
      respuesta = await _ejecutar(metodo, uri, headers, cuerpo)
          .timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw const ApiException(0, 'El servidor no responde. Revisa tu conexion.');
    } catch (e) {
      throw ApiException(0, _mensajeDeRed(e));
    }

    if (respuesta.statusCode == 401 && necesitaToken && reintentar) {
      if (await _refrescar()) {
        return _enviar(metodo, path,
            body: body, query: query, reintentar: false);
      }
      await _matarSesion();
    }

    return _procesar(respuesta);
  }

  Future<http.Response> _ejecutar(
      String metodo,
      Uri uri,
      Map<String, String> headers,
      String? cuerpo,
      ) {
    switch (metodo) {
      case 'GET':
        return _http.get(uri, headers: headers);
      case 'POST':
        return _http.post(uri, headers: headers, body: cuerpo);
      case 'PUT':
        return _http.put(uri, headers: headers, body: cuerpo);
      case 'PATCH':
        return _http.patch(uri, headers: headers, body: cuerpo);
      case 'DELETE':
        return _http.delete(uri, headers: headers);
      default:
        throw ArgumentError('Metodo no soportado: $metodo');
    }
  }

  // -------------------------------------------------------------- refresh

  Future<bool> _refrescar() {
    _refreshEnCurso ??=
        _hacerRefresh().whenComplete(() => _refreshEnCurso = null);
    return _refreshEnCurso!;
  }

  Future<bool> _hacerRefresh() async {
    final refresh = await _tokens.refreshToken();
    if (refresh == null) return false;

    try {
      final respuesta = await _http
          .post(
        _uri('/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh_token': refresh}),
      )
          .timeout(ApiConfig.timeout);

      if (respuesta.statusCode != 200) return false;

      final datos =
      jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
      await _tokens.guardar(
        access: datos['access_token'] as String,
        refresh: datos['refresh_token'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _matarSesion() async {
    await _tokens.limpiar();
    onSesionExpirada?.call();
  }

  // ------------------------------------------------------------ respuesta

  dynamic _procesar(http.Response respuesta) {
    final codigo = respuesta.statusCode;

    if (respuesta.bodyBytes.isEmpty) {
      if (codigo >= 400) throw ApiException(codigo, _mensajeGenerico(codigo));
      return null; // 204 No Content
    }

    dynamic datos;
    try {
      datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    } catch (_) {
      datos = null;
    }

    if (codigo >= 200 && codigo < 300) return datos;

    throw ApiException(codigo, _extraerDetalle(datos, codigo));
  }

  /// El backend manda {"detail": "texto"}, pero FastAPI en un 422 manda
  /// {"detail": [{"loc": [...], "msg": "..."}]}. Hay que cubrir los dos.
  String _extraerDetalle(dynamic datos, int codigo) {
    if (datos is Map && datos['detail'] != null) {
      final detail = datos['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        final primero = detail.first;
        if (primero is Map && primero['msg'] != null) {
          return primero['msg'].toString();
        }
      }
      return detail.toString();
    }
    return _mensajeGenerico(codigo);
  }

  String _mensajeGenerico(int codigo) {
    switch (codigo) {
      case 400:
        return 'Los datos enviados no son validos.';
      case 401:
        return 'Tu sesion expiro. Vuelve a iniciar sesion.';
      case 404:
        return 'No encontramos lo que buscabas.';
      case 409:
        return 'Esa accion ya se realizo.';
      case 413:
        return 'La imagen pesa mas de 10 MB.';
      case 415:
        return 'Formato de imagen no admitido. Usa JPG, PNG o WEBP.';
      case 500:
        return 'Error del servidor. Intenta mas tarde.';
      default:
        return 'Ocurrio un error inesperado ($codigo).';
    }
  }

  String _mensajeDeRed(Object e) {
    if (e is SocketException || e is http.ClientException) {
      return 'No se pudo conectar con el servidor. '
          'Revisa que el backend este corriendo y la URL sea correcta.';
    }
    return 'Error de conexion: $e';
  }

  // -------------------------------------------------------------- helpers

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    Map<String, String>? qp;
    if (query != null) {
      final limpio = <String, String>{};
      query.forEach((clave, valor) {
        if (valor != null) limpio[clave] = valor.toString();
      });
      if (limpio.isNotEmpty) qp = limpio;
    }
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: qp);
  }

  MediaType _tipoImagen(String ruta) {
    final extension = ruta.toLowerCase().split('.').last;
    switch (extension) {
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      default:
        return MediaType('image', 'jpeg');
    }
  }
}