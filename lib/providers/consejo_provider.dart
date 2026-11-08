import 'package:flutter/foundation.dart';

import '../core/api/api_exception.dart';
import '../models/consejo.dart';
import '../services/consejo_service.dart';

class ConsejoProvider extends ChangeNotifier {
  final ConsejoService _service = ConsejoService();

  List<Consejo> _consejos = [];
  bool _cargando = false;
  String? _error;

  List<Consejo> get consejos => List.unmodifiable(_consejos);
  bool get cargando => _cargando;
  String? get error => _error;

  /// Los consejos no cambian durante la sesion: se piden una sola vez.
  Future<void> cargar({bool forzar = false}) async {
    if (_consejos.isNotEmpty && !forzar) return;

    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      _consejos = await _service.listar();
      _error = null;
    } on ApiException catch (e) {
      _error = e.mensaje;
    } catch (_) {
      _error = 'No se pudieron cargar los consejos.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
