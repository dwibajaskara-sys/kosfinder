import 'package:flutter/foundation.dart';

import '../models/kos.dart';
import '../repositories/kos_repository.dart';

enum OwnerKosState { initial, loading, loaded, error }

/// Mengelola daftar kos milik pemilik yang sedang login.
class OwnerKosProvider extends ChangeNotifier {
  final KosRepository _repository;

  OwnerKosProvider({KosRepository? repository})
    : _repository = repository ?? KosRepository();

  OwnerKosState _state = OwnerKosState.initial;
  List<Kos> _kosList = [];
  String? _errorMessage;
  String? _pemilikId;
  int _requestId = 0;

  OwnerKosState get state => _state;
  List<Kos> get kosList => _kosList;
  String? get errorMessage => _errorMessage;
  String? get pemilikId => _pemilikId;
  bool get isLoading => _state == OwnerKosState.loading;
  bool get hasError => _state == OwnerKosState.error;
  bool get isEmpty => _state == OwnerKosState.loaded && _kosList.isEmpty;

  /// Membuat kos baru lalu memuat ulang daftar milik pemilik tersebut.
  Future<bool> createKos(Kos kos) async {
    final requestId = ++_requestId;
    _pemilikId = kos.pemilikId;
    _state = OwnerKosState.loading;
    _kosList = [];
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.createKos(kos);
    } catch (error) {
      if (requestId != _requestId) return false;
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      _state = OwnerKosState.error;
      notifyListeners();
      return false;
    }

    if (requestId == _requestId) {
      await fetchOwnerKosList(kos.pemilikId);
    }
    return true;
  }

  /// Updates one of the owner's kos and refreshes the owner's list.
  Future<bool> updateKos(Kos kos) async {
    final requestId = ++_requestId;
    _pemilikId = kos.pemilikId;
    _state = OwnerKosState.loading;
    _kosList = [];
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateKos(kos);
    } catch (error) {
      if (requestId != _requestId) return false;
      final message = error.toString();
      _errorMessage = _isAuthorizationError(error)
          ? 'Anda tidak berhak mengubah kos ini'
          : message.replaceFirst('Exception: ', '');
      _state = OwnerKosState.error;
      notifyListeners();
      return false;
    }

    if (requestId == _requestId) {
      await fetchOwnerKosList(kos.pemilikId);
    }
    return true;
  }

  /// Menghapus kos milik sendiri lalu memuat ulang daftar pemilik.
  Future<bool> deleteKos(Kos kos) async {
    final requestId = ++_requestId;
    _pemilikId = kos.pemilikId;
    _state = OwnerKosState.loading;
    _kosList = [];
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteKos(kos.id);
    } catch (error) {
      if (requestId != _requestId) return false;
      final message = error.toString();
      _errorMessage = _isAuthorizationError(error)
          ? 'Anda tidak berhak menghapus kos ini'
          : message.replaceFirst('Exception: ', '');
      _state = OwnerKosState.error;
      notifyListeners();
      return false;
    }

    if (requestId == _requestId) {
      await fetchOwnerKosList(kos.pemilikId);
    }
    return true;
  }

  /// Mengambil kos berdasarkan ID pemilik agar daftar tetap terbatas ke akunnya.
  Future<void> fetchOwnerKosList(String pemilikId) async {
    final requestId = ++_requestId;
    _pemilikId = pemilikId;
    _state = OwnerKosState.loading;
    _kosList = [];
    _errorMessage = null;
    notifyListeners();

    try {
      final kosList = await _repository.getOwnerKosList(pemilikId);
      if (requestId != _requestId) return;
      _kosList = kosList;
      _state = OwnerKosState.loaded;
    } catch (error) {
      if (requestId != _requestId) return;
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      _state = OwnerKosState.error;
    } finally {
      if (requestId == _requestId) notifyListeners();
    }
  }

  bool _isAuthorizationError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('42501') ||
        message.contains('pgrst116') ||
        message.contains('permission denied') ||
        message.contains('row-level security') ||
        message.contains('row level security');
  }
}
