import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/kos_list_screen.dart';
import 'package:kosfinder/screens/login_screen.dart';
import 'package:kosfinder/screens/register_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeAuthRepository extends AuthRepository {
  int signInCalls = 0;
  int signUpCalls = 0;
  String? lastEmail;
  String? lastPassword;
  String? lastName;
  Object? failure;
  Completer<User?>? signInCompleter;
  User? currentSession;

  @override
  User? get currentUser => currentSession;

  @override
  Stream<AuthState> get authStateChanges => const Stream<AuthState>.empty();

  User get sampleUser => _user;

  @override
  Future<User?> signIn(String email, String password) async {
    signInCalls++;
    lastEmail = email;
    lastPassword = password;
    if (failure case final error?) throw error;
    if (signInCompleter != null) return signInCompleter!.future;
    return _user;
  }

  @override
  Future<User?> signUp(String email, String password, String nama) async {
    signUpCalls++;
    lastEmail = email;
    lastPassword = password;
    lastName = nama;
    if (failure case final error?) throw error;
    return _user;
  }

  User get _user => const User(
    id: 'owner-1',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-01-01T00:00:00.000Z',
  );
}

class FakeKosRepository extends KosRepository {
  @override
  Future<List<Kos>> getPublicKosList() async => [];
}

Future<void> _pumpAuthScreen(
  WidgetTester tester, {
  required Widget screen,
  required AuthProvider authProvider,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(
          create: (_) => KosProvider(repository: FakeKosRepository()),
        ),
      ],
      child: MaterialApp(home: screen),
    ),
  );
}

void main() {
  group('Auth screens', () {
    testWidgets('login validates email and password before calling provider', (
      tester,
    ) async {
      final repository = FakeAuthRepository();
      final authProvider = AuthProvider(repository: repository);
      addTearDown(authProvider.dispose);

      await _pumpAuthScreen(
        tester,
        screen: const LoginScreen(),
        authProvider: authProvider,
      );

      await tester.enterText(find.byKey(const Key('login-email')), 'invalid');
      await tester.enterText(find.byKey(const Key('login-password')), '12345');
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      expect(find.text('Email harus mengandung @'), findsOneWidget);
      expect(find.text('Password minimal 6 karakter'), findsOneWidget);
      expect(repository.signInCalls, 0);
    });

    testWidgets(
      'register validates email and password before calling provider',
      (tester) async {
        final repository = FakeAuthRepository();
        final authProvider = AuthProvider(repository: repository);
        addTearDown(authProvider.dispose);

        await _pumpAuthScreen(
          tester,
          screen: const RegisterScreen(),
          authProvider: authProvider,
        );

        await tester.enterText(
          find.byKey(const Key('register-name')),
          'Pemilik',
        );
        await tester.enterText(
          find.byKey(const Key('register-email')),
          'invalid',
        );
        await tester.enterText(
          find.byKey(const Key('register-password')),
          '12345',
        );
        await tester.tap(find.text('Daftar'));
        await tester.pumpAndSettle();

        expect(find.text('Email harus mengandung @'), findsOneWidget);
        expect(find.text('Password minimal 6 karakter'), findsOneWidget);
        expect(repository.signUpCalls, 0);
      },
    );

    testWidgets('login calls provider and navigates to KosListScreen', (
      tester,
    ) async {
      final repository = FakeAuthRepository();
      final authProvider = AuthProvider(repository: repository);
      addTearDown(authProvider.dispose);

      await _pumpAuthScreen(
        tester,
        screen: const LoginScreen(),
        authProvider: authProvider,
      );

      await tester.enterText(
        find.byKey(const Key('login-email')),
        'owner@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('login-password')),
        'password123',
      );
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      expect(repository.signInCalls, 1);
      expect(repository.lastEmail, 'owner@example.com');
      expect(repository.lastPassword, 'password123');
      expect(find.byType(KosListScreen), findsOneWidget);
    });

    testWidgets('register calls provider with full name and navigates home', (
      tester,
    ) async {
      final repository = FakeAuthRepository();
      final authProvider = AuthProvider(repository: repository);
      addTearDown(authProvider.dispose);

      await _pumpAuthScreen(
        tester,
        screen: const RegisterScreen(),
        authProvider: authProvider,
      );

      await tester.enterText(
        find.byKey(const Key('register-name')),
        'Pemilik Kos',
      );
      await tester.enterText(
        find.byKey(const Key('register-email')),
        'owner@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('register-password')),
        'password123',
      );
      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();

      expect(repository.signUpCalls, 1);
      expect(repository.lastName, 'Pemilik Kos');
      expect(find.byType(KosListScreen), findsOneWidget);
    });

    testWidgets('kos list explains when Supabase is not configured', (
      tester,
    ) async {
      final authProvider = AuthProvider(repository: FakeAuthRepository());
      addTearDown(authProvider.dispose);

      await _pumpAuthScreen(
        tester,
        screen: const KosListScreen(),
        authProvider: authProvider,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Login Pemilik'));
      await tester.pumpAndSettle();

      expect(
        find.text('Login memerlukan konfigurasi Supabase.'),
        findsOneWidget,
      );
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('shows provider errors and loading indicator', (tester) async {
      final repository = FakeAuthRepository()
        ..signInCompleter = Completer<User?>();
      repository.currentSession = repository.sampleUser;
      final authProvider = AuthProvider(repository: repository);
      addTearDown(authProvider.dispose);

      await _pumpAuthScreen(
        tester,
        screen: const LoginScreen(),
        authProvider: authProvider,
      );
      await tester.enterText(
        find.byKey(const Key('login-email')),
        'owner@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('login-password')),
        'password123',
      );
      await tester.tap(find.text('Masuk'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      repository.signInCompleter!.completeError(
        const AuthException('Invalid login credentials'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Email atau kata sandi salah'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
