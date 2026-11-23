import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/providers/owner_kos_provider.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/kos_form_screen.dart';
import 'package:kosfinder/screens/owner_dashboard_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeAuthRepository extends AuthRepository {
  @override
  User? get currentUser => const User(
    id: 'owner-1',
    appMetadata: {},
    userMetadata: {'nama': 'Kara Pemilik'},
    aud: 'authenticated',
    email: 'owner@example.com',
    createdAt: '2026-01-01T00:00:00.000Z',
  );

  @override
  Stream<AuthState> get authStateChanges => const Stream<AuthState>.empty();
}

class FakeKosRepository extends KosRepository {
  final List<Kos> kosList = [];
  Kos? createdKos;
  int createCalls = 0;
  String? requestedPemilikId;
  Object? createError;

  @override
  Future<Kos> createKos(Kos kos) async {
    createCalls++;
    createdKos = kos;
    if (createError case final error?) throw error;

    final savedKos = kos.copyWith(id: 'saved-kos-id');
    kosList.add(savedKos);
    return savedKos;
  }

  @override
  Future<List<Kos>> getOwnerKosList(String pemilikId) async {
    requestedPemilikId = pemilikId;
    return kosList.where((kos) => kos.pemilikId == pemilikId).toList();
  }
}

Future<void> _pumpOwnerDashboard(
  WidgetTester tester, {
  required FakeKosRepository kosRepository,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(repository: FakeAuthRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => OwnerKosProvider(repository: kosRepository),
        ),
      ],
      child: const MaterialApp(home: OwnerDashboardScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openForm(WidgetTester tester) async {
  await tester.tap(find.text('Tambah Kos'));
  await tester.pumpAndSettle();
  expect(find.byType(KosFormScreen), findsOneWidget);
}

Future<void> _enterText(WidgetTester tester, String key, String value) async {
  final field = find.byKey(Key(key));
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
}

void main() {
  group('KosFormScreen', () {
    testWidgets('requires nama, area, harga, and kontak', (tester) async {
      final repository = FakeKosRepository();
      await _pumpOwnerDashboard(tester, kosRepository: repository);
      await _openForm(tester);

      await tester.ensureVisible(find.byKey(const Key('kos-submit')));
      await tester.tap(find.byKey(const Key('kos-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Nama kos wajib diisi'), findsOneWidget);
      expect(find.text('Area wajib diisi'), findsOneWidget);
      expect(find.text('Harga wajib diisi'), findsOneWidget);
      expect(find.text('Kontak pemilik wajib diisi'), findsOneWidget);
      expect(repository.createCalls, 0);
    });

    testWidgets('rejects a price of zero without creating a kos', (
      tester,
    ) async {
      final repository = FakeKosRepository();
      await _pumpOwnerDashboard(tester, kosRepository: repository);
      await _openForm(tester);

      await _enterText(tester, 'kos-name', 'Kos Melati');
      await _enterText(tester, 'kos-area', 'Singaraja');
      await _enterText(tester, 'kos-price', '0');
      await _enterText(tester, 'kos-contact', '081234567890');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('kos-submit')));
      await tester.tap(find.byKey(const Key('kos-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Harga harus lebih dari 0'), findsOneWidget);
      expect(repository.createCalls, 0);
    });

    testWidgets(
      'creates kos using the signed-in owner and refreshes dashboard',
      (tester) async {
        final repository = FakeKosRepository();
        await _pumpOwnerDashboard(tester, kosRepository: repository);
        await _openForm(tester);

        await _enterText(tester, 'kos-name', 'Kos Mawar');
        await _enterText(tester, 'kos-area', 'Singaraja');
        await _enterText(tester, 'kos-price', '850000');
        await _enterText(tester, 'kos-description', 'Dekat kampus');
        await _enterText(tester, 'kos-contact', '081234567890');
        tester.testTextInput.hide();
        await tester.pumpAndSettle();

        final wifi = find.byKey(const Key('facility-WiFi'));
        await tester.ensureVisible(wifi);
        await tester.tap(wifi);
        await tester.pumpAndSettle();

        final status = find.byKey(const Key('kos-status'));
        await tester.ensureVisible(status);
        await tester.tap(status);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Penuh').last);
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byKey(const Key('kos-submit')));
        await tester.tap(find.byKey(const Key('kos-submit')));
        await tester.pumpAndSettle();

        expect(repository.createCalls, 1);
        expect(repository.createdKos?.id, isEmpty);
        expect(repository.createdKos?.pemilikId, 'owner-1');
        expect(repository.createdKos?.nama, 'Kos Mawar');
        expect(repository.createdKos?.area, 'Singaraja');
        expect(repository.createdKos?.hargaPerBulan, 850000);
        expect(repository.createdKos?.deskripsi, 'Dekat kampus');
        expect(repository.createdKos?.fasilitas, ['WiFi']);
        expect(repository.createdKos?.kontakPemilik, '081234567890');
        expect(repository.createdKos?.status, 'Penuh');
        expect(repository.requestedPemilikId, 'owner-1');
        expect(find.byType(OwnerDashboardScreen), findsOneWidget);
        expect(find.text('Kos Mawar'), findsOneWidget);
      },
    );
  });
}
