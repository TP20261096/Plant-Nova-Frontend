import 'package:flutter/foundation.dart';

import '../core/api/api_exception.dart';
import '../models/perfil.dart';
import '../services/perfil_service.dart';

class PerfilProvider extends ChangeNotifier {
  final PerfilService _service = PerfilService();

  Perfil? _perfil;
  List<String> _distritos = [];
  bool _cargando = false;
  bool _guardando = false;
  String? _error;

  Perfil? get perfil => _perfil;
  List<String> get distritos => List.unmodifiable(_distritos);
  bool get cargando => _cargando;
  bool get guardando => _guardando;
  String? get error => _error;

  /// GET /profile
  Future<void> cargar({bool silencioso = false}) async {
    if (!silencioso) {
      _cargando = true;
      _error = null;
      notifyListeners();
    }

    try {
      _perfil = await _service.obtener();
      _error = null;
    } on ApiException catch (e) {
      _error = e.mensaje;
    } catch (_) {
      _error = 'No se pudo cargar tu perfil.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// GET /profile/districts
  ///
  /// Se piden una sola vez: la lista de distritos no cambia entre pantallas.
  Future<void> cargarDistritos() async {
    if (_distritos.isNotEmpty) return;
    try {
      _distritos = await _service.distritos();
      notifyListeners();
    } catch (_) {
      // Si falla, el selector queda vacio y la pantalla lo indica. No es
      // motivo para romper toda la edicion del perfil.
    }
  }

  /// PATCH /profile
  Future<bool> actualizar(PerfilForm form) async {
    if (form.vacio) return true;

    _guardando = true;
    _error = null;
    notifyListeners();

    try {
      _perfil = await _service.actualizar(form);
      return true;
    } on ApiException catch (e) {
      _error = e.mensaje;
      return false;
    } catch (_) {
      _error = 'No se pudieron guardar los cambios.';
      return false;
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }

  /// PUT /profile/password
  Future<bool> cambiarPassword({
    required String actual,
    required String nueva,
  }) async {
    _guardando = true;
    _error = null;
    notifyListeners();

    try {
      await _service.cambiarPassword(actual: actual, nueva: nueva);
      return true;
    } on ApiException catch (e) {
      // El 401 aca no significa sesion caida sino contrasena incorrecta.
      _error = e.codigo == 401
          ? 'La contraseña actual no es correcta.'
          : e.mensaje;
      return false;
    } catch (_) {
      _error = 'No se pudo cambiar la contraseña.';
      return false;
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }

  /// DELETE /profile
  Future<bool> eliminarCuenta() async {
    _guardando = true;
    _error = null;
    notifyListeners();

    try {
      await _service.eliminarCuenta();
      return true;
    } on ApiException catch (e) {
      _error = e.mensaje;
      return false;
    } catch (_) {
      _error = 'No se pudo eliminar la cuenta.';
      return false;
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }

  void limpiarError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void limpiar() {
    _perfil = null;
    _error = null;
    notifyListeners();
  }
}