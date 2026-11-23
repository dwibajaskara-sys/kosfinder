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
  Object? updateError;
  Kos? updatedKos;

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

  @override
  Future<Kos> updateKos(Kos kos) async {
    updatedKos = kos;
    if (updateError case final error?) throw error;

    final index = kosList.indexWhere((item) => item.id == kos.id);
    if (index >= 0) kosList[index] = kos;
    return kos;
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

    testWidgets('edit mode opens with the existing kos values', (tester) async {
      final existingKos = Kos(
        id: 'kos-1',
        createdAt: DateTime(2026),
        pemilikId: 'owner-1',
        nama: 'Kos Anggrek',
        area: 'Singaraja',
        hargaPerBulan: 900000,
        deskripsi: 'Dekat kampus',
        fasilitas: const ['WiFi', 'Parkir'],
        kontakPemilik: '081234567890',
        status: 'Penuh',
      );
      final repository = FakeKosRepository()..kosList.add(existingKos);
      await _pumpOwnerDashboard(tester, kosRepository: repository);

      await tester.tap(find.byKey(const Key('edit-kos-1')));
      await tester.pumpAndSettle();

      expect(find.text('Edit Kos'), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('kos-name')))
            .controller!
            .text,
        'Kos Anggrek',
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('kos-area')))
            .controller!
            .text,
        'Singaraja',
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('kos-price')))
            .controller!
            .text,
        '900000',
      );
      expect(
        tester
            .widget<CheckboxListTile>(find.byKey(const Key('facility-WiFi')))
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<CheckboxListTile>(find.byKey(const Key('facility-AC')))
            .value,
        isFalse,
      );
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byKey(const Key('kos-status')),
            )
            .initialValue,
        'Penuh',
      );
    });

    testWidgets('shows an authorization error when an update is rejected', (
      tester,
    ) async {
      final existingKos = Kos(
        id: 'kos-1',
        createdAt: DateTime(2026),
        pemilikId: 'owner-1',
        nama: 'Kos Anggrek',
        area: 'Singaraja',
        hargaPerBulan: 900000,
        deskripsi: 'Dekat kampus',
        fasilitas: const ['WiFi'],
        kontakPemilik: '081234567890',
        status: 'Tersedia',
      );
      final repository = FakeKosRepository()
        ..kosList.add(existingKos)
        ..updateError = Exception('permission denied for table kos (42501)');
      await _pumpOwnerDashboard(tester, kosRepository: repository);

      await tester.tap(find.byKey(const Key('edit-kos-1')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('kos-submit')));
      await tester.tap(find.byKey(const Key('kos-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Anda tidak berhak mengubah kos ini'), findsOneWidget);
      expect(repository.updatedKos?.id, 'kos-1');
      expect(find.byType(KosFormScreen), findsOneWidget);
    });
  });
}
