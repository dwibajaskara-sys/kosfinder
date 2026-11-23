import 'package:flutter/foundation.dart';
import '../models/kos.dart';
import '../repositories/kos_repository.dart';

enum KosState { initial, loading, loaded, error }

/// Provider state management untuk penjelajahan dan pencarian kos publik (US01, US03).
class KosProvider extends ChangeNotifier {
  final KosRepository _repository;

  KosProvider({KosRepository? repository})
      : _repository = repository ?? KosRepository();

  KosState _state = KosState.initial;
  List<Kos> _kosList = [];
  String? _errorMessage;
  String _searchQuery = '';

  KosState get state => _state;
  List<Kos> get kosList => _kosList;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  bool get isLoading => _state == KosState.loading;
  bool get hasError => _state == KosState.error;
  bool get isEmpty => _state == KosState.loaded && _kosList.isEmpty;

  /// Mengatur kata kunci pencarian area (US03-AC1).
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Menghapus kata kunci pencarian area.
  void clearSearchQuery() {
    _searchQuery = '';
    notifyListeners();
  }

  /// Daftar kos yang telah difilter berdasarkan pencarian area case-insensitive (US03-AC1).
  List<Kos> get filteredKosList {
    if (_searchQuery.trim().isEmpty) {
      return _kosList;
    }
    final query = _searchQuery.trim().toLowerCase();
    return _kosList.where((kos) {
      return kos.area.toLowerCase().contains(query);
    }).toList();
  }

  /// Bernilai true jika database memiliki kos tetapi tidak ada hasil yang cocok dengan pencarian (US03-AC4).
  bool get isSearchEmpty =>
      _state == KosState.loaded &&
      _kosList.isNotEmpty &&
      filteredKosList.isEmpty;

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
