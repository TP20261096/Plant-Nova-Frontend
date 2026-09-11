import 'package:flutter/foundation.dart';

import '../core/api/api_exception.dart';
import '../models/planta.dart';
import '../services/planta_service.dart';

/// Estado del menu Jardin.
///
/// Guarda la lista de plantas y el detalle de la que se esta viendo. No
/// calcula nada del riego ni del estado: eso lo hace el backend y aca solo
/// se muestra.
class PlantaProvider extends ChangeNotifier {
  final PlantaService _service = PlantaService();

  List<Planta> _plantas = [];
  bool _cargando = false;
  String? _error;

  PlantaDetalle? _detalle;
  bool _cargandoDetalle = false;
  String? _errorDetalle;

  List<Planta> get plantas => List.unmodifiable(_plantas);
  bool get cargando => _cargando;
  String? get error => _error;
  bool get vacio => !_cargando && _error == null && _plantas.isEmpty;

  PlantaDetalle? get detalle => _detalle;
  bool get cargandoDetalle => _cargandoDetalle;
  String? get errorDetalle => _errorDetalle;

  /// Contadores para las tarjetas de resumen del Jardin.
  int get totalPlantas => _plantas.length;
  int get sanas =>
      _plantas.where((p) => p.estado.valor == 'Sana').length;
  int get enTratamiento =>
      _plantas.where((p) => p.estado.valor == 'En_tratamiento').length;
  int get conRiegoAtrasado => _plantas.where((p) => p.riegoAtrasado).length;

  /// GET /plants
  ///
  /// [silencioso] evita mostrar el spinner cuando es un refresco en segundo
  /// plano (por ejemplo al volver de completar un riego). La lista se
  /// reemplaza recien cuando llegan los datos nuevos.
  Future<void> cargar({bool silencioso = false}) async {
    if (!silencioso) {
      _cargando = true;
      _error = null;
      notifyListeners();
    }

    try {
      _plantas = await _service.listar();
      _error = null;
    } on ApiException catch (e) {
      _error = e.mensaje;
    } catch (_) {
      _error = 'No se pudo cargar tu jardín.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// GET /plants/{id}
  Future<void> cargarDetalle(String id) async {
    _cargandoDetalle = true;
    _errorDetalle = null;
    _detalle = null;
    notifyListeners();

    try {
      _detalle = await _service.obtener(id);
    } on ApiException catch (e) {
      _errorDetalle = e.mensaje;
    } catch (_) {
      _errorDetalle = 'No se pudo cargar la planta.';
    } finally {
      _cargandoDetalle = false;
      notifyListeners();
    }
  }

  void limpiarDetalle() {
    _detalle = null;
    _errorDetalle = null;
  }

  /// POST /plants
  ///
  /// Devuelve la planta creada, o null si fallo. La pantalla de resultado de
  /// diagnostico necesita el id para vincular despues.
  Future<PlantaDetalle?> crear(PlantaForm form) async {
    try {
      final creada = await _service.crear(form);
      // Recargamos en vez de insertar a mano: el backend calcula estado y
      // riego al crear, y esos valores no los conocemos desde aca.
      await cargar(silencioso: true);
      return creada;
    } on ApiException catch (e) {
      _error = e.mensaje;
      notifyListeners();
      return null;
    } catch (_) {
      _error = 'No se pudo registrar la planta.';
      notifyListeners();
      return null;
    }
  }

  /// PUT /plants/{id}
  ///
  /// [cambios] viene de PlantaForm.toJsonParcial(). Si esta vacio no se llama
  /// al backend: mandar un cuerpo sin campos devuelve 400.
  Future<bool> actualizar(String id, Map<String, dynamic> cambios) async {
    if (cambios.isEmpty) return true;

    try {
      _detalle = await _service.actualizar(id, cambios);
      await cargar(silencioso: true);
      return true;
    } on ApiException catch (e) {
      _errorDetalle = e.mensaje;
      notifyListeners();
      return false;
    } catch (_) {
      _errorDetalle = 'No se pudo guardar los cambios.';
      notifyListeners();
      return false;
    }
  }

  /// DELETE /plants/{id}
  ///
  /// Quitamos la planta de la lista de inmediato para que la pantalla
  /// responda al toque, y si el backend falla la devolvemos a su sitio.
  Future<bool> eliminar(String id) async {
    final indice = _plantas.indexWhere((p) => p.id == id);
    final respaldo = indice == -1 ? null : _plantas[indice];

    if (indice != -1) {
      _plantas.removeAt(indice);
      notifyListeners();
    }

    try {
      await _service.eliminar(id);
      if (_detalle?.id == id) _detalle = null;
      return true;
    } on ApiException catch (e) {
      if (respaldo != null) _plantas.insert(indice, respaldo);
      _error = e.mensaje;
      notifyListeners();
      return false;
    } catch (_) {
      if (respaldo != null) _plantas.insert(indice, respaldo);
      _error = 'No se pudo eliminar la planta.';
      notifyListeners();
      return false;
    }
  }

  void limpiarError() {
    if (_error == null && _errorDetalle == null) return;
    _error = null;
    _errorDetalle = null;
    notifyListeners();
  }

  /// Al cerrar sesion hay que botar todo: la siguiente cuenta no debe ver
  /// las plantas de la anterior.
  void limpiar() {
    _plantas = [];
    _detalle = null;
    _error = null;
    _errorDetalle = null;
    _cargando = false;
    _cargandoDetalle = false;
    notifyListeners();
  }
}