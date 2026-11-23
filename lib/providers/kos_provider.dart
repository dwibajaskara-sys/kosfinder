import 'package:flutter/foundation.dart';

import '../models/kos.dart';
import '../repositories/kos_repository.dart';

enum KosState { initial, loading, loaded, error }

/// Provider state management untuk penjelajahan, pencarian, dan penyaringan kos publik (US01, US03).
class KosProvider extends ChangeNotifier {
  final KosRepository _repository;

  KosProvider({KosRepository? repository})
      : _repository = repository ?? KosRepository();

  KosState _state = KosState.initial;
  List<Kos> _kosList = [];
  String? _errorMessage;
  String _searchQuery = '';
  int? _maxPrice;
  List<String> _selectedFacilities = [];
  int _requestId = 0;

  KosState get state => _state;
  List<Kos> get kosList => _kosList;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  int? get maxPrice => _maxPrice;
  List<String> get selectedFacilities => _selectedFacilities;

  bool get isLoading => _state == KosState.loading;
  bool get hasError => _state == KosState.error;
  bool get isEmpty => _state == KosState.loaded && _kosList.isEmpty;

  /// Memeriksa apakah ada filter harga atau fasilitas yang sedang aktif.
  bool get isFilterActive => _maxPrice != null || _selectedFacilities.isNotEmpty;

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

  /// Mengatur filter harga maksimum dan checklist fasilitas tetap (US03-AC2, US03-AC3).
  void setFilter({int? maxPrice, List<String>? facilities}) {
    _maxPrice = (maxPrice != null && maxPrice > 0) ? maxPrice : null;
    if (facilities != null) {
      _selectedFacilities = List.from(facilities);
    }
    notifyListeners();
  }

  /// Menghapus seluruh filter harga dan fasilitas.
  void clearFilter() {
    _maxPrice = null;
    _selectedFacilities = [];
    notifyListeners();
  }

  /// Mereset pencarian dan filter secara menyeluruh.
  void resetAll() {
    _searchQuery = '';
    _maxPrice = null;
    _selectedFacilities = [];
    notifyListeners();
  }

  /// Daftar kos yang telah difilter berdasarkan area (case-insensitive),
  /// batas harga maksimum (<= maxPrice), dan kesesuaian fasilitas (US03-AC1, AC2, AC3).
  List<Kos> get filteredKosList {
    return _kosList.where((kos) {
      // 1. Filter Area Case-Insensitive (US03-AC1)
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        if (!kos.area.toLowerCase().contains(query)) {
          return false;
        }
      }

      // 2. Filter Harga Maksimum (US03-AC2: harga <= batas maksimum)
      if (_maxPrice != null && _maxPrice! > 0) {
        if (kos.hargaPerBulan > _maxPrice!) {
          return false;
        }
      }

      // 3. Filter Fasilitas Tetap (US03-AC3: kos wajib memiliki seluruh fasilitas terpilih)
      if (_selectedFacilities.isNotEmpty) {
        for (final facility in _selectedFacilities) {
          if (!kos.fasilitas.contains(facility)) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  }

  /// Bernilai true jika database memiliki data kos tetapi hasil pencarian/filter nihil (US03-AC4).
  bool get isSearchEmpty =>
      _state == KosState.loaded &&
      _kosList.isNotEmpty &&
      filteredKosList.isEmpty;

  /// Mengambil daftar kos publik dari Supabase (US01-AC1, US01-AC2, US01-AC3).
  Future<void> fetchKosList() async {
    final requestId = ++_requestId;
    _state = KosState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final kosList = await _repository.getPublicKosList();
      if (requestId != _requestId) return;
      _kosList = kosList;
      _state = KosState.loaded;
    } catch (e) {
      if (requestId != _requestId) return;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _state = KosState.error;
    } finally {
      if (requestId == _requestId) notifyListeners();
    }
  }
}
