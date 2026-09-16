import 'package:flutter/foundation.dart';

import '../core/api/api_exception.dart';
import '../models/actividad.dart';
import '../services/actividad_service.dart';

/// Estado del menu Inicio.
class ActividadProvider extends ChangeNotifier {
  final ActividadService _service = ActividadService();

  DateTime _fecha = DateTime.now();
  List<Actividad> _actividades = [];
  bool _cargando = false;
  String? _error;

  final Set<String> _completando = {};

  DateTime get fecha => _fecha;
  List<Actividad> get actividades => List.unmodifiable(_actividades);
  bool get cargando => _cargando;
  String? get error => _error;

  bool estaCompletando(String? id) => id != null && _completando.contains(id);

  int get pendientes =>
      _actividades.where((a) => !a.completada && !a.proyectada).length;
  int get atrasadas => _actividades.where((a) => a.atrasada).length;

  bool get esHoy {
    final hoy = DateTime.now();
    return _fecha.year == hoy.year &&
        _fecha.month == hoy.month &&
        _fecha.day == hoy.day;
  }

  /// Cambia el dia y recarga. Si es el mismo dia, fuerza la recarga igualmente.
  Future<void> seleccionarFecha(DateTime fecha, {bool silencioso = false}) async {
    _fecha = fecha;
    await cargar(silencioso: silencioso);
  }

  /// GET /activities?fecha=
  Future<void> cargar({bool silencioso = false}) async {
    if (!silencioso) {
      _cargando = true;
      _error = null;
      notifyListeners();
    }

    try {
      _actividades = await _service.listar(fecha: _fecha);
      _error = null;
    } on ApiException catch (e) {
      _error = e.mensaje;
      _actividades = [];
    } catch (_) {
      _error = 'No se pudieron cargar tus actividades.';
      _actividades = [];
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// PATCH /activities/{id}/complete
  Future<bool> completar(Actividad actividad) async {
    final id = actividad.id;
    if (id == null || !actividad.sePuedeCompletar) return false;
    if (_completando.contains(id)) return false;

    _completando.add(id);
    notifyListeners();

    try {
      await _service.completar(id);
      await cargar(silencioso: true);
      return true;
    } on ApiException catch (e) {
      if (e.conflicto) {
        await cargar(silencioso: true);
        return true;
      }
      _error = e.mensaje;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'No se pudo completar la tarea.';
      notifyListeners();
      return false;
    } finally {
      _completando.remove(id);
      notifyListeners();
    }
  }

  /// POST /activities
  Future<bool> crear(ActividadForm form) async {
    try {
      await _service.crear(form);
      await cargar(silencioso: true);
      return true;
    } on ApiException catch (e) {
      _error = e.mensaje;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'No se pudo crear la tarea.';
      notifyListeners();
      return false;
    }
  }

  void limpiarError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  void limpiar() {
    _actividades = [];
    _fecha = DateTime.now();
    _error = null;
    _completando.clear();
    notifyListeners();
  }
}