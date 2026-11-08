import 'package:flutter/foundation.dart';

import '../core/api/api_exception.dart';
import '../core/utils/json.dart';
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

  /// Las actividades de los 7 dias del selector, una clave por fecha.
  /// Se piden de una sola vez con GET /activities/range: antes cada toque
  /// en el selector disparaba una peticion y la lista parpadeaba.
  Map<String, List<Actividad>> _semana = {};

  /// Dias que cubre [_semana], para saber si una fecha ya esta cargada.
  DateTime? _desde;
  DateTime? _hasta;

  /// Siguiente tarea pendiente del jardin, tal como la devolvio el backend
  /// al completar la ultima. null significa que no queda nada por hacer, y
  /// la pantalla de confirmacion debe decir "todo al dia" en vez de quedarse
  /// vacia. No la calculamos aqui: la fecha depende del clima del dia y del
  /// plan de la receta, que solo conoce el servidor.
  Actividad? _proximaTarea;

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

  /// Cambia el dia mostrado.
  ///
  /// Si la fecha esta dentro de la semana ya cargada, el cambio es inmediato
  /// y sin red. Fuera de ella se pide ese dia suelto.
  Future<void> seleccionarFecha(DateTime fecha, {bool silencioso = false}) async {
    _fecha = fecha;

    final clave = Json.aFechaApi(fecha);
    if (_semana.containsKey(clave)) {
      _actividades = _semana[clave]!;
      _error = null;
      notifyListeners();
      return;
    }

    await cargar(silencioso: silencioso);
  }

  /// GET /activities/range — los 7 dias del selector: dos antes de hoy y
  /// cuatro despues, el mismo rango que pinta la pantalla de Inicio.
  Future<void> cargarSemana({bool silencioso = false}) async {
    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day)
        .subtract(const Duration(days: 2));
    final fin = inicio.add(const Duration(days: 6));

    if (!silencioso) {
      _cargando = true;
      _error = null;
      notifyListeners();
    }

    try {
      _semana = await _service.rango(desde: inicio, hasta: fin);
      _desde = inicio;
      _hasta = fin;
      _actividades = _semana[Json.aFechaApi(_fecha)] ?? const [];
      _error = null;
    } on ApiException catch (e) {
      _error = e.mensaje;
    } catch (_) {
      _error = 'No se pudieron cargar tus actividades.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Cuantas tareas tiene un dia del selector, para marcarlo con un punto.
  /// Devuelve null si ese dia no esta en la semana cargada.
  int? tareasDe(DateTime fecha) {
    final lista = _semana[Json.aFechaApi(fecha)];
    return lista?.where((a) => !a.completada).length;
  }

  bool get semanaCargada => _desde != null && _hasta != null;

  Actividad? get proximaTarea => _proximaTarea;

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
      final actualizada = await _service.completar(id);
      _proximaTarea = actualizada.proximaTarea;
      // Completar un riego reprograma el siguiente y completar la ultima
      // aplicacion crea la tarea de revision: cambian otros dias, no solo
      // el que se esta viendo.
      await cargarSemana(silencioso: true);
      return true;
    } on ApiException catch (e) {
      if (e.conflicto) {
        // Ya estaba completada (doble toque u otra sesion). No hay proxima
        // tarea que mostrar porque el backend no la devolvio.
        _proximaTarea = null;
        await cargarSemana(silencioso: true);
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
      await cargarSemana(silencioso: true);
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
    _semana = {};
    _desde = null;
    _hasta = null;
    _proximaTarea = null;
    _fecha = DateTime.now();
    _error = null;
    _completando.clear();
    notifyListeners();
  }
}