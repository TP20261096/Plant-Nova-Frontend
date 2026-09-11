import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/api/api_exception.dart';
import '../models/diagnostico.dart';
import '../services/diagnostico_service.dart';

/// Flujo de Captura: elegir foto, analizar, mostrar resultado, vincular.
///
/// Reemplaza a DiagnosisProvider, que adivinaba el cultivo leyendo el nombre
/// del archivo y armaba la planta a mano con datos inventados.
class DiagnosticoProvider extends ChangeNotifier {
  final DiagnosticoService _service = DiagnosticoService();

  File? _imagen;

  /// Planta a la que pertenece la captura, cuando el usuario entra desde el
  /// jardin o desde una actividad de revision. null si viene de la pestana
  /// Captura sin contexto.
  String? _plantId;

  Diagnostico? _actual;
  bool _analizando = false;
  bool _vinculando = false;
  String? _error;

  File? get imagen => _imagen;
  String? get plantId => _plantId;
  Diagnostico? get actual => _actual;
  bool get analizando => _analizando;
  bool get vinculando => _vinculando;
  String? get error => _error;

  void seleccionarImagen(String? ruta) {
    _imagen = ruta == null ? null : File(ruta);
    notifyListeners();
  }

  void fijarPlanta(String? plantId) {
    _plantId = plantId;
    notifyListeners();
  }

  void limpiarPlanta() => fijarPlanta(null);

  /// POST /diagnose
  Future<bool> analizar() async {
    final imagen = _imagen;
    if (imagen == null) {
      _error = 'Primero elige una foto.';
      notifyListeners();
      return false;
    }

    _analizando = true;
    _error = null;
    _actual = null;
    notifyListeners();

    try {
      _actual = await _service.diagnosticar(imagen: imagen, plantId: _plantId);
      return true;
    } on ApiException catch (e) {
      _error = e.mensaje;
      return false;
    } catch (_) {
      _error = 'No se pudo analizar la imagen.';
      return false;
    } finally {
      _analizando = false;
      notifyListeners();
    }
  }

  /// GET /diagnoses/{id} — para abrir un diagnostico del historial de una
  /// planta, que necesita enlaces de imagen recien firmados.
  Future<bool> cargar(String id) async {
    _analizando = true;
    _error = null;
    notifyListeners();

    try {
      _actual = await _service.obtener(id);
      return true;
    } on ApiException catch (e) {
      _error = e.mensaje;
      return false;
    } catch (_) {
      _error = 'No se pudo cargar el diagnóstico.';
      return false;
    } finally {
      _analizando = false;
      notifyListeners();
    }
  }

  /// PATCH /diagnoses/{id}/link
  ///
  /// Despues de esto hay que recargar jardin y actividades: el backend
  /// programa el tratamiento y cambia el estado de la planta.
  Future<bool> vincular(String plantId) async {
    final diagnostico = _actual;
    if (diagnostico == null) return false;

    _vinculando = true;
    _error = null;
    notifyListeners();

    try {
      _actual = await _service.vincular(
        diagnosticoId: diagnostico.id,
        plantId: plantId,
      );
      return true;
    } on ApiException catch (e) {
      _error = e.conflicto
          ? 'Este diagnóstico ya está vinculado a otra planta.'
          : e.mensaje;
      return false;
    } catch (_) {
      _error = 'No se pudo vincular el diagnóstico.';
      return false;
    } finally {
      _vinculando = false;
      notifyListeners();
    }
  }

  void limpiarError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  /// Al salir del flujo: la imagen local y el diagnostico en curso no deben
  /// sobrevivir a la siguiente captura.
  void limpiar() {
    _imagen = null;
    _actual = null;
    _plantId = null;
    _error = null;
    _analizando = false;
    _vinculando = false;
    notifyListeners();
  }
}