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

  @override
  Future<List<Kos>> getOwnerKosList(String pemilikId) async {
    requestedPemilikId = pemilikId;
    if (failure case final error?) throw error;
    return kosList.where((kos) => kos.pemilikId == pemilikId).toList();
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
  });
}
