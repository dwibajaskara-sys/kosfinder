import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseAuth extends GoTrueClient {
  MockSupabaseAuth() : super(autoRefreshToken: false);

  final StreamController<AuthState> _authEvents =
      StreamController<AuthState>.broadcast(sync: true);
  User? _currentUser;
  Map<String, dynamic>? receivedSignUpData;
  String? receivedEmail;
  String? receivedPassword;
  AuthException? signInError;

  void restoreSession() {
    _currentUser = _user(email: 'owner@example.com');
  }

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<AuthState> get onAuthStateChange => _authEvents.stream;

  @override
  Future<AuthResponse> signUp({
    String? email,
    String? phone,
    required String password,
    String? emailRedirectTo,
    Map<String, dynamic>? data,
    String? captchaToken,
    OtpChannel channel = OtpChannel.sms,
  }) async {
    receivedEmail = email;
    receivedPassword = password;
    receivedSignUpData = data;
    _currentUser = _user(email: email, metadata: data);
    return AuthResponse(user: _currentUser);
  }

  @override
  Future<AuthResponse> signInWithPassword({
    String? email,
    String? phone,
    required String password,
    String? captchaToken,
  }) async {
    receivedEmail = email;
    receivedPassword = password;
    if (signInError case final error?) throw error;

    _currentUser = _user(email: email);
    _authEvents.add(AuthState(AuthChangeEvent.signedIn, null));
    return AuthResponse(user: _currentUser);
  }

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.local}) async {
    _currentUser = null;
    _authEvents.add(AuthState(AuthChangeEvent.signedOut, null));
  }

  User _user({String? email, Map<String, dynamic>? metadata}) {
    return User(
      id: 'owner-1',
      appMetadata: const {},
      userMetadata: metadata,
      aud: 'authenticated',
      email: email,
      createdAt: '2026-01-01T00:00:00.000Z',
    );
  }

  Future<void> close() => _authEvents.close();
}

class MockSupabaseClient extends SupabaseClient {
  MockSupabaseClient(this.mockAuth)
    : super(
        'http://localhost',
        'anon-key-for-tests',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      );

  final MockSupabaseAuth mockAuth;

  @override
  GoTrueClient get auth => mockAuth;
}

void main() {
  group('AuthRepository and AuthProvider', () {
    late MockSupabaseAuth mockAuth;
    late MockSupabaseClient mockClient;
    late AuthRepository repository;

    setUp(() {
      mockAuth = MockSupabaseAuth();
      mockClient = MockSupabaseClient(mockAuth);
      repository = AuthRepository(client: mockClient);
    });

    tearDown(() async {
      await mockAuth.close();
      await mockClient.dispose();
    });

    test(
      'signUp sends email, password, and full name as user metadata',
      () async {
        final response = await repository.signUp(
          'owner@example.com',
          'password123',
          'Pemilik Kos',
        );

        expect(response.user?.id, 'owner-1');
        expect(response.session, isNull);
        expect(mockAuth.receivedEmail, 'owner@example.com');
        expect(mockAuth.receivedPassword, 'password123');
        expect(mockAuth.receivedSignUpData, {'nama': 'Pemilik Kos'});
      },
    );

    test(
      'provider uses the current session and updates after sign in/out',
      () async {
        mockAuth.restoreSession();
        final provider = AuthProvider(repository: repository);
        expect(provider.user?.id, 'owner-1');

        await provider.signIn('owner@example.com', 'password123');
        expect(provider.user?.id, 'owner-1');
        expect(provider.isLoading, isFalse);
        expect(provider.errorMessage, isNull);

        await provider.signOut();
        expect(provider.user, isNull);

        provider.dispose();
      },
    );

    test('provider shows a friendly error when connection fails', () async {
      mockAuth.signInError = AuthRetryableFetchException();
      final provider = AuthProvider(repository: repository);

      await provider.signIn('owner@example.com', 'password123');

      expect(provider.isLoading, isFalse);
      expect(
        provider.errorMessage,
        'Gagal terhubung. Periksa koneksi internet',
      );

      provider.dispose();
    });

    test(
      'provider exposes a friendly error for invalid login credentials',
      () async {
        mockAuth.signInError = const AuthException('Invalid login credentials');
        final provider = AuthProvider(repository: repository);

        await provider.signIn('owner@example.com', 'wrong-password');

        expect(provider.user, isNull);
        expect(provider.isLoading, isFalse);
        expect(provider.errorMessage, 'Email atau kata sandi salah');

        provider.dispose();
      },
    );
  });
}
