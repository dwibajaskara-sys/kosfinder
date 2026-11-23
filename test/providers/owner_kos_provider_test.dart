import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/providers/owner_kos_provider.dart';
import 'package:kosfinder/repositories/kos_repository.dart';

class FakeKosRepository extends KosRepository {
  FakeKosRepository(this.kosList);

  final List<Kos> kosList;
  String? requestedPemilikId;
  Object? failure;
  Kos? updatedKos;
  Object? updateFailure;
  String? deletedKosId;
  Object? deleteFailure;

  @override
  Future<List<Kos>> getOwnerKosList(String pemilikId) async {
    requestedPemilikId = pemilikId;
    if (failure case final error?) throw error;
    return kosList.where((kos) => kos.pemilikId == pemilikId).toList();
  }

  @override
  Future<Kos> updateKos(Kos kos) async {
    updatedKos = kos;
    if (updateFailure case final error?) throw error;

    final index = kosList.indexWhere((item) => item.id == kos.id);
    if (index >= 0) kosList[index] = kos;
    return kos;
  }

  @override
  Future<void> deleteKos(String kosId) async {
    deletedKosId = kosId;
    if (deleteFailure case final error?) throw error;
    kosList.removeWhere((kos) => kos.id == kosId);
  }
}

class DelayedKosRepository extends KosRepository {
  final Map<String, Completer<List<Kos>>> requests = {};

  @override
  Future<List<Kos>> getOwnerKosList(String pemilikId) {
    return requests.putIfAbsent(pemilikId, Completer<List<Kos>>.new).future;
  }
}

Kos _sampleKos(String id, String pemilikId) {
  return Kos(
    id: id,
    createdAt: DateTime(2026),
    pemilikId: pemilikId,
    nama: 'Kos $id',
    area: 'Singaraja',
    hargaPerBulan: 800000,
    deskripsi: 'Deskripsi kos',
    fasilitas: const ['WiFi'],
    kontakPemilik: '081234567890',
  );
}

void main() {
  group('OwnerKosProvider', () {
    test('starts in initial state with an empty list', () {
      final provider = OwnerKosProvider(repository: FakeKosRepository([]));

      expect(provider.state, OwnerKosState.initial);
      expect(provider.isLoading, isFalse);
      expect(provider.hasError, isFalse);
      expect(provider.kosList, isEmpty);
      expect(provider.isEmpty, isFalse);
    });

    test('loads only kos belonging to the requested owner', () async {
      final repository = FakeKosRepository([
        _sampleKos('1', 'owner-1'),
        _sampleKos('2', 'owner-2'),
      ]);
      final provider = OwnerKosProvider(repository: repository);

      await provider.fetchOwnerKosList('owner-1');

      expect(repository.requestedPemilikId, 'owner-1');
      expect(provider.state, OwnerKosState.loaded);
      expect(provider.isLoading, isFalse);
      expect(provider.hasError, isFalse);
      expect(provider.kosList.map((kos) => kos.id), ['1']);
      expect(provider.isEmpty, isFalse);
    });

    test('marks loaded empty results as empty', () async {
      final provider = OwnerKosProvider(repository: FakeKosRepository([]));

      await provider.fetchOwnerKosList('owner-1');

      expect(provider.state, OwnerKosState.loaded);
      expect(provider.isEmpty, isTrue);
    });

    test('ignores a stale response for a previous owner', () async {
      final repository = DelayedKosRepository();
      final provider = OwnerKosProvider(repository: repository);
      final firstRequest = provider.fetchOwnerKosList('owner-1');
      final secondRequest = provider.fetchOwnerKosList('owner-2');

      repository.requests['owner-2']!.complete([_sampleKos('2', 'owner-2')]);
      await secondRequest;
      repository.requests['owner-1']!.complete([_sampleKos('1', 'owner-1')]);
      await firstRequest;

      expect(provider.pemilikId, 'owner-2');
      expect(provider.state, OwnerKosState.loaded);
      expect(provider.kosList.map((kos) => kos.pemilikId), ['owner-2']);
    });

    test('exposes an error when the repository request fails', () async {
      final repository = FakeKosRepository([])
        ..failure = Exception('Gagal memuat data kos pemilik.');
      final provider = OwnerKosProvider(repository: repository);

      await provider.fetchOwnerKosList('owner-1');

      expect(provider.state, OwnerKosState.error);
      expect(provider.isLoading, isFalse);
      expect(provider.hasError, isTrue);
      expect(provider.errorMessage, 'Gagal memuat data kos pemilik.');
    });

    test('updates a kos and refreshes the owner list', () async {
      final originalKos = _sampleKos('kos-1', 'owner-1');
      final repository = FakeKosRepository([originalKos]);
      final provider = OwnerKosProvider(repository: repository);
      final updatedKos = originalKos.copyWith(
        hargaPerBulan: 950000,
        status: 'Penuh',
      );

      final result = await provider.updateKos(updatedKos);

      expect(result, isTrue);
      expect(repository.updatedKos, same(updatedKos));
      expect(repository.requestedPemilikId, 'owner-1');
      expect(provider.state, OwnerKosState.loaded);
      expect(provider.kosList.single.hargaPerBulan, 950000);
      expect(provider.kosList.single.status, 'Penuh');
    });

    test(
      'maps an RLS update failure to a friendly authorization error',
      () async {
        final repository = FakeKosRepository([_sampleKos('kos-1', 'owner-1')])
          ..updateFailure = Exception(
            'PostgrestException: new row violates row-level security policy '
            '(code: 42501)',
          );
        final provider = OwnerKosProvider(repository: repository);

        final result = await provider.updateKos(
          _sampleKos('kos-1', 'owner-1').copyWith(nama: 'Kos diubah'),
        );

        expect(result, isFalse);
        expect(provider.state, OwnerKosState.error);
        expect(provider.hasError, isTrue);
        expect(provider.errorMessage, 'Anda tidak berhak mengubah kos ini');
      },
    );

    test('deletes a kos and refreshes the owner list', () async {
      final kos = _sampleKos('kos-1', 'owner-1');
      final repository = FakeKosRepository([kos]);
      final provider = OwnerKosProvider(repository: repository);

      final result = await provider.deleteKos(kos);

      expect(result, isTrue);
      expect(repository.deletedKosId, 'kos-1');
      expect(repository.requestedPemilikId, 'owner-1');
      expect(provider.state, OwnerKosState.loaded);
      expect(provider.kosList, isEmpty);
      expect(provider.isEmpty, isTrue);
    });

    test(
      'maps an RLS delete failure to a friendly authorization error',
      () async {
        final kos = _sampleKos('kos-1', 'owner-1');
        final repository = FakeKosRepository([kos])
          ..deleteFailure = Exception(
            'PostgrestException: permission denied for table kos (code: 42501)',
          );
        final provider = OwnerKosProvider(repository: repository);

        final result = await provider.deleteKos(kos);

        expect(result, isFalse);
        expect(repository.deletedKosId, 'kos-1');
        expect(provider.state, OwnerKosState.error);
        expect(provider.hasError, isTrue);
        expect(provider.errorMessage, 'Anda tidak berhak menghapus kos ini');
      },
    );
  });
}
