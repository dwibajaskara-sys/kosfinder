import 'package:flutter/foundation.dart';
import '../models/kos.dart';
import '../repositories/kos_repository.dart';

enum KosState { initial, loading, loaded, error }

/// Provider state management untuk penjelajahan dan daftar kos publik (US01).
class KosProvider extends ChangeNotifier {
  final KosRepository _repository;

  KosProvider({KosRepository? repository})
      : _repository = repository ?? KosRepository();

  KosState _state = KosState.initial;
  List<Kos> _kosList = [];
  String? _errorMessage;

  KosState get state => _state;
  List<Kos> get kosList => _kosList;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == KosState.loading;
  bool get hasError => _state == KosState.error;
  bool get isEmpty => _state == KosState.loaded && _kosList.isEmpty;

  /// Mengambil daftar kos publik dari Supabase (US01-AC1, US01-AC2, US01-AC3).
  Future<void> fetchKosList() async {
    _state = KosState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _kosList = await _repository.getPublicKosList();
      _state = KosState.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _state = KosState.error;
    } finally {
      notifyListeners();
    }
  }
}
