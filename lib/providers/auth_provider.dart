import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/auth_repository.dart';

/// Mengelola status autentikasi pemilik untuk UI.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  late final StreamSubscription<AuthState> _authSubscription;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({AuthRepository? repository})
    : _repository = repository ?? AuthRepository() {
    _user = _repository.currentUser;
    _authSubscription = _repository.authStateChanges.listen(
      _handleAuthState,
      onError: _handleAuthError,
    );
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<AuthResponse?> signUp(
    String email,
    String password,
    String nama,
  ) async {
    _startLoading();
    try {
      final response = await _repository.signUp(email, password, nama);
      _user = response.session?.user;
      return response;
    } catch (error) {
      _errorMessage = _formatError(error);
      return null;
    } finally {
      _finishLoading();
    }
  }

  Future<void> signIn(String email, String password) {
    return _runAuthAction(() => _repository.signIn(email, password));
  }

  Future<void> signOut() async {
    _startLoading();
    try {
      await _repository.signOut();
      _user = null;
    } catch (error) {
      _errorMessage = _formatError(error);
    } finally {
      _finishLoading();
    }
  }

  Future<void> _runAuthAction(Future<User?> Function() action) async {
    _startLoading();
    try {
      _user = await action();
    } catch (error) {
      _errorMessage = _formatError(error);
    } finally {
      _finishLoading();
    }
  }

  void _startLoading() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }

  void _finishLoading() {
    _isLoading = false;
    notifyListeners();
  }

  void _handleAuthState(AuthState authState) {
    _user = authState.event == AuthChangeEvent.signedOut
        ? null
        : authState.session?.user ?? _repository.currentUser;
    notifyListeners();
  }

  void _handleAuthError(Object error) {
    _errorMessage = _formatError(error);
    notifyListeners();
  }

  String _formatError(Object error) {
    if (error is AuthRetryableFetchException) {
      return 'Gagal terhubung. Periksa koneksi internet';
    }

    final message = error is AuthException ? error.message : error.toString();
    if (message.toLowerCase().contains('invalid login credentials')) {
      return 'Email atau kata sandi salah';
    }
    return message.replaceFirst('Exception: ', '');
  }

  @override
  void dispose() {
    unawaited(_authSubscription.cancel());
    super.dispose();
  }
}
