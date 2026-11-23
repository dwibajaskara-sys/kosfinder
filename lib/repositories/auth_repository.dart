import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository untuk operasi autentikasi pemilik melalui Supabase Auth.
class AuthRepository {
  final SupabaseClient? client;

  AuthRepository({this.client});

  SupabaseClient get _effectiveClient {
    if (client != null) return client!;
    return Supabase.instance.client;
  }

  /// Mendaftarkan pemilik dan menyimpan nama lengkap pada metadata user.
  Future<AuthResponse> signUp(String email, String password, String nama) {
    return _effectiveClient.auth.signUp(
      email: email,
      password: password,
      data: {'nama': nama},
    );
  }

  /// Masuk menggunakan email dan password.
  Future<User?> signIn(String email, String password) async {
    final response = await _effectiveClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.user;
  }

  /// Menghapus sesi autentikasi aktif.
  Future<void> signOut() => _effectiveClient.auth.signOut();

  /// User pada sesi Supabase yang sedang aktif, atau null jika belum login.
  User? get currentUser => _effectiveClient.auth.currentUser;

  /// Perubahan autentikasi Supabase, termasuk pergantian sesi dan logout.
  Stream<AuthState> get authStateChanges =>
      _effectiveClient.auth.onAuthStateChange;
}
