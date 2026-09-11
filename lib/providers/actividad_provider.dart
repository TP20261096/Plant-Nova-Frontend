import 'package:flutter/foundation.dart';

import '../core/api/api_exception.dart';
import '../models/actividad.dart';
import '../services/actividad_service.dart';

/// Estado del menu Inicio.
///
/// Reemplaza a PlantProvider.generateActivitiesForDate(), que inventaba las
/// tareas en el cliente con aritmetica de modulos sobre la fecha del
/// diagnostico. Ahora las programa el backend y aca solo se listan.
class ActividadProvider extends ChangeNotifier {
  final ActividadService _service = ActividadService();

  DateTime _fecha = DateTime.now();
  List<Actividad> _actividades = [];
  bool _cargando = false;
  String? _error;

  /// Ids que se estan marcando ahora mismo, para deshabilitar su boton y
  /// evitar dobles toques que terminarian en un 409.
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

  /// Cambia el dia y recarga. Si es el mismo dia no hace nada.
  Future<void> seleccionarFecha(DateTime fecha) async {
    if (fecha.year == _fecha.year &&
        fecha.month == _fecha.month &&
        fecha.day == _fecha.day) {
      return;
    }
    _fecha = fecha;
    await cargar();
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
  ///
  /// Devuelve true si se marco. Recarga la lista despues, porque completar un
  /// riego reprograma el siguiente y puede cambiar lo que se muestra.
  ///
  /// Quien llame a esto tambien deberia recargar el jardin: las fechas de
  /// riego de la planta cambiaron.
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
      // 409 significa que ya estaba completada, normalmente por un doble
      // toque o por otra sesion. No es un fallo real: recargamos y listo.
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