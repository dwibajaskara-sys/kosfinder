import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/providers/auth_provider.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/providers/owner_kos_provider.dart';
import 'package:kosfinder/repositories/auth_repository.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:kosfinder/screens/kos_list_screen.dart';
import 'package:kosfinder/screens/owner_dashboard_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeAuthRepository extends AuthRepository {
  int signOutCalls = 0;

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

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}

class FakeKosRepository extends KosRepository {
  FakeKosRepository(this.ownerKosList);

  final List<Kos> ownerKosList;
  String? requestedPemilikId;
  String? deletedKosId;
  Object? deleteFailure;

  @override
  Future<List<Kos>> getOwnerKosList(String pemilikId) async {
    requestedPemilikId = pemilikId;
    return ownerKosList.where((kos) => kos.pemilikId == pemilikId).toList();
  }

  @override
  Future<List<Kos>> getPublicKosList() async => [];

  @override
  Future<void> deleteKos(String kosId) async {
    deletedKosId = kosId;
    if (deleteFailure case final error?) throw error;
    ownerKosList.removeWhere((kos) => kos.id == kosId);
  }
}

Kos _sampleKos(String id, String pemilikId, String nama) {
  return Kos(
    id: id,
    createdAt: DateTime(2026),
    pemilikId: pemilikId,
    nama: nama,
    area: 'Singaraja',
    hargaPerBulan: 800000,
    deskripsi: 'Deskripsi kos',
    fasilitas: const ['WiFi'],
    kontakPemilik: '081234567890',
  );
}

Future<void> _pumpDashboard(
  WidgetTester tester, {
  required AuthProvider authProvider,
  required OwnerKosProvider ownerKosProvider,
  required KosRepository kosRepository,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<OwnerKosProvider>.value(value: ownerKosProvider),
        ChangeNotifierProvider(
          create: (_) => KosProvider(repository: kosRepository),
        ),
      ],
      child: const MaterialApp(home: OwnerDashboardScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('OwnerDashboardScreen', () {
    testWidgets('shows owner identity and only their kos with actions', (
      tester,
    ) async {
      final authRepository = FakeAuthRepository();
      final authProvider = AuthProvider(repository: authRepository);
      final kosRepository = FakeKosRepository([
        _sampleKos('1', 'owner-1', 'Kos Pemilik'),
        _sampleKos('2', 'owner-2', 'Kos Orang Lain'),
      ]);
      final ownerKosProvider = OwnerKosProvider(repository: kosRepository);
      addTearDown(authProvider.dispose);
      addTearDown(ownerKosProvider.dispose);

      await _pumpDashboard(
        tester,
        authProvider: authProvider,
        ownerKosProvider: ownerKosProvider,
        kosRepository: kosRepository,
      );

      expect(kosRepository.requestedPemilikId, 'owner-1');
      expect(find.text('Kara Pemilik'), findsOneWidget);
      expect(find.text('Kos Pemilik'), findsOneWidget);
      expect(find.text('Kos Orang Lain'), findsNothing);
      expect(find.text('Tambah Kos'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Hapus'), findsOneWidget);
    });

    testWidgets('shows the empty-owner message when no kos are available', (
      tester,
    ) async {
      final authProvider = AuthProvider(repository: FakeAuthRepository());
      final kosRepository = FakeKosRepository([]);
      final ownerKosProvider = OwnerKosProvider(repository: kosRepository);
      addTearDown(authProvider.dispose);
      addTearDown(ownerKosProvider.dispose);

      await _pumpDashboard(
        tester,
        authProvider: authProvider,
        ownerKosProvider: ownerKosProvider,
        kosRepository: kosRepository,
      );

      expect(find.text('Anda belum menambahkan kos'), findsOneWidget);
    });

    testWidgets('logout calls AuthProvider and returns to public list', (
      tester,
    ) async {
      final authRepository = FakeAuthRepository();
      final authProvider = AuthProvider(repository: authRepository);
      final kosRepository = FakeKosRepository([]);
      final ownerKosProvider = OwnerKosProvider(repository: kosRepository);
      addTearDown(authProvider.dispose);
      addTearDown(ownerKosProvider.dispose);

      await _pumpDashboard(
        tester,
        authProvider: authProvider,
        ownerKosProvider: ownerKosProvider,
        kosRepository: kosRepository,
      );

      await tester.tap(find.byTooltip('Logout'));
      await tester.pumpAndSettle();

      expect(authRepository.signOutCalls, 1);
      expect(find.byType(KosListScreen), findsOneWidget);
    });

    testWidgets('confirms deletion and calls the owner kos provider', (
      tester,
    ) async {
      final authProvider = AuthProvider(repository: FakeAuthRepository());
      final kosRepository = FakeKosRepository([
        _sampleKos('kos-1', 'owner-1', 'Kos Melati'),
      ]);
      final ownerKosProvider = OwnerKosProvider(repository: kosRepository);
      addTearDown(authProvider.dispose);
      addTearDown(ownerKosProvider.dispose);

      await _pumpDashboard(
        tester,
        authProvider: authProvider,
        ownerKosProvider: ownerKosProvider,
        kosRepository: kosRepository,
      );

      await tester.tap(find.byKey(const Key('delete-kos-1')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text('Hapus kos Kos Melati? Tindakan ini tidak bisa dibatalkan.'),
        findsOneWidget,
      );
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Hapus'), findsNWidgets(2));

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Hapus'),
        ),
      );
      await tester.pumpAndSettle();

      expect(kosRepository.deletedKosId, 'kos-1');
      expect(find.text('Kos berhasil dihapus'), findsOneWidget);
      expect(find.text('Kos Melati'), findsNothing);
    });

    testWidgets('shows an authorization error when deletion is rejected', (
      tester,
    ) async {
      final authProvider = AuthProvider(repository: FakeAuthRepository());
      final kosRepository = FakeKosRepository([
        _sampleKos('kos-1', 'owner-1', 'Kos Melati'),
      ])..deleteFailure = Exception('permission denied for table kos (42501)');
      final ownerKosProvider = OwnerKosProvider(repository: kosRepository);
      addTearDown(authProvider.dispose);
      addTearDown(ownerKosProvider.dispose);

      await _pumpDashboard(
        tester,
        authProvider: authProvider,
        ownerKosProvider: ownerKosProvider,
        kosRepository: kosRepository,
      );

      await tester.tap(find.byKey(const Key('delete-kos-1')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Hapus'),
        ),
      );
      await tester.pumpAndSettle();

      expect(kosRepository.deletedKosId, 'kos-1');
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('Anda tidak berhak menghapus kos ini'),
        ),
        findsOneWidget,
      );
    });
  });
}
