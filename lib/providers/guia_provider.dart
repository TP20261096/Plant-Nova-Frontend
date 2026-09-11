import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api/api_exception.dart';
import '../models/especie.dart';
import '../services/guia_service.dart';

/// Estado del menu Guia y del selector de especie.
class GuiaProvider extends ChangeNotifier {
  final GuiaService _service = GuiaService();

  List<Especie> _especies = [];
  bool _cargando = false;
  String? _error;
  String _busqueda = '';

  EspecieDetalle? _detalle;
  bool _cargandoDetalle = false;
  String? _errorDetalle;

  /// Evita disparar una peticion por cada tecla que escribe el usuario.
  Timer? _debounce;

  List<Especie> get especies => List.unmodifiable(_especies);
  bool get cargando => _cargando;
  String? get error => _error;
  String get busqueda => _busqueda;
  bool get sinResultados =>
      !_cargando && _error == null && _especies.isEmpty && _busqueda.isNotEmpty;

  EspecieDetalle? get detalle => _detalle;
  bool get cargandoDetalle => _cargandoDetalle;
  String? get errorDetalle => _errorDetalle;

  /// GET /guide/species
  ///
  /// [soloDiagnosticables] se usa cuando el selector viene de una captura y
  /// solo tienen sentido las especies que el modelo reconoce.
  Future<void> cargar({bool? soloDiagnosticables}) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _especies = await _service.especies(
        q: _busqueda,
        soloDiagnosticables: soloDiagnosticables,
      );
      _error = null;
    } on ApiException catch (e) {
      _error = e.mensaje;
    } catch (_) {
      _error = 'No se pudo cargar la guía.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// La llama el campo de busqueda en cada cambio de texto. Espera 400 ms
  /// sin escritura antes de consultar al backend.
  void buscar(String texto, {bool? soloDiagnosticables}) {
    _busqueda = texto;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      cargar(soloDiagnosticables: soloDiagnosticables);
    });
  }

  /// GET /guide/species/{slug}
  Future<void> cargarDetalle(String slug) async {
    _cargandoDetalle = true;
    _errorDetalle = null;
    _detalle = null;
    notifyListeners();

    try {
      _detalle = await _service.detalle(slug);
    } on ApiException catch (e) {
      _errorDetalle = e.mensaje;
    } catch (_) {
      _errorDetalle = 'No se pudo cargar la ficha.';
    } finally {
      _cargandoDetalle = false;
      notifyListeners();
    }
  }

  void limpiarDetalle() {
    _detalle = null;
    _errorDetalle = null;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}