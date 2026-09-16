import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/api/api_exception.dart';
import '../models/planta.dart';
import '../services/planta_service.dart';

/// Estado del menu Jardin.
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

  int get totalPlantas => _plantas.length;
  int get sanas =>
      _plantas.where((p) => p.estado.valor.toLowerCase() == 'sana').length;
  int get enTratamiento =>
      _plantas.where((p) => p.estado.valor.toLowerCase() == 'en_tratamiento').length;
  int get conRiegoAtrasado => _plantas.where((p) => p.riegoAtrasado).length;

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
  Future<PlantaDetalle?> crear(PlantaForm form, {File? foto}) async {
    try {
      var creada = await _service.crear(form);

      if (foto != null) {
        try {
          creada = await _service.subirFoto(creada.id, foto);
        } catch (_) {
          _error = 'La planta se registró, pero la foto no se pudo subir.';
        }
      }

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

  Future<bool> cambiarFoto(String id, File imagen) async {
    try {
      _detalle = await _service.subirFoto(id, imagen);
      await cargar(silencioso: true);
      return true;
    } on ApiException catch (e) {
      _errorDetalle = e.mensaje;
      notifyListeners();
      return false;
    } catch (_) {
      _errorDetalle = 'No se pudo subir la foto.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminar(String id) async {
    final indice = _plantas.indexWhere((p) => p.id == id);
    final respaldo = indice == -1 ? null : _plantas[indice];

    // Optimistic UI update: removemos de la lista inmediatamente
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