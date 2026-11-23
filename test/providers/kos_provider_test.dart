import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/providers/kos_provider.dart';
import 'package:kosfinder/repositories/kos_repository.dart';

class FakeSuccessKosRepository extends KosRepository {
  final List<Kos> dummyList;

  FakeSuccessKosRepository(this.dummyList);

  @override
  Future<List<Kos>> getPublicKosList() async {
    return dummyList;
  }
}

class FakeFailureKosRepository extends KosRepository {
  @override
  Future<List<Kos>> getPublicKosList() async {
    throw Exception('Gagal memuat data kos. Periksa koneksi internet Anda.');
  }
}

class DelayedKosRepository extends KosRepository {
  final List<Completer<List<Kos>>> requests = [];

  @override
  Future<List<Kos>> getPublicKosList() {
    final request = Completer<List<Kos>>();
    requests.add(request);
    return request.future;
  }
}

void main() {
  final sampleKosList = [
    Kos(
      id: '1',
      createdAt: DateTime.now(),
      pemilikId: 'owner-1',
      nama: 'Kos Mawar Indah',
      area: 'Singaraja',
      hargaPerBulan: 800000,
      deskripsi: 'Deskripsi A',
      fasilitas: const ['WiFi', 'AC'],
      kontakPemilik: '081234567890',
      status: 'Tersedia',
    ),
    Kos(
      id: '2',
      createdAt: DateTime.now(),
      pemilikId: 'owner-2',
      nama: 'Kos Kenanga',
      area: 'Denpasar Barat',
      hargaPerBulan: 1500000,
      deskripsi: 'Deskripsi B',
      fasilitas: const ['WiFi', 'Parkir', 'Kamar Mandi Dalam'],
      kontakPemilik: '089876543210',
      status: 'Tersedia',
    ),
    Kos(
      id: '3',
      createdAt: DateTime.now(),
      pemilikId: 'owner-3',
      nama: 'Kos Melati Murah',
      area: 'Singaraja',
      hargaPerBulan: 600000,
      deskripsi: 'Deskripsi C',
      fasilitas: const ['Parkir', 'Listrik'],
      kontakPemilik: '087777777777',
      status: 'Penuh',
    ),
  ];

  group('KosProvider Unit Tests', () {
    test('Initial state is KosState.initial and empty', () {
      final provider = KosProvider(repository: FakeSuccessKosRepository([]));

      expect(provider.state, KosState.initial);
      expect(provider.isLoading, isFalse);
      expect(provider.hasError, isFalse);
      expect(provider.kosList, isEmpty);
      expect(provider.searchQuery, isEmpty);
      expect(provider.maxPrice, isNull);
      expect(provider.selectedFacilities, isEmpty);
      expect(provider.isFilterActive, isFalse);
    });

    test('fetchKosList transitions to loaded with data on success', () async {
      final provider = KosProvider(
        repository: FakeSuccessKosRepository(sampleKosList),
      );

      await provider.fetchKosList();

      expect(provider.state, KosState.loaded);
      expect(provider.isLoading, isFalse);
      expect(provider.hasError, isFalse);
      expect(provider.kosList.length, 3);
      expect(provider.filteredKosList.length, 3);
      expect(provider.isEmpty, isFalse);
    });

    test('Search area is case-insensitive (US03-AC1)', () async {
      final provider = KosProvider(
        repository: FakeSuccessKosRepository(sampleKosList),
      );

      await provider.fetchKosList();

      // Cari 'singaraja' huruf kecil (ada 2: Kos Mawar Indah & Kos Melati Murah)
      provider.setSearchQuery('singaraja');
      expect(provider.filteredKosList.length, 2);

      // Cari 'Singaraja' huruf kapital
      provider.setSearchQuery('Singaraja');
      expect(provider.filteredKosList.length, 2);

      // Cari 'SINGARAJA' huruf besar semua
      provider.setSearchQuery('SINGARAJA');
      expect(provider.filteredKosList.length, 2);
    });

    test('Filter max price (US03-AC2)', () async {
      final provider = KosProvider(
        repository: FakeSuccessKosRepository(sampleKosList),
      );

      await provider.fetchKosList();

      // Filter harga maksimal Rp1.000.000: hanya kos 1 (800rb) dan kos 3 (600rb) yang tampil
      provider.setFilter(maxPrice: 1000000);
      expect(provider.isFilterActive, isTrue);
      expect(provider.filteredKosList.length, 2);
      expect(provider.filteredKosList.any((k) => k.id == '2'), isFalse);

      // Filter harga maksimal Rp700.000: hanya kos 3 (600rb) yang tampil
      provider.setFilter(maxPrice: 700000);
      expect(provider.filteredKosList.length, 1);
      expect(provider.filteredKosList.first.id, '3');
    });

    test('Filter facilities requires all selected facilities (US03-AC3)', () async {
      final provider = KosProvider(
        repository: FakeSuccessKosRepository(sampleKosList),
      );

      await provider.fetchKosList();

      // Filter fasilitas 'WiFi' (ada di kos 1 dan kos 2)
      provider.setFilter(facilities: ['WiFi']);
      expect(provider.filteredKosList.length, 2);

      // Filter fasilitas 'WiFi' AND 'AC' (hanya ada di kos 1)
      provider.setFilter(facilities: ['WiFi', 'AC']);
      expect(provider.filteredKosList.length, 1);
      expect(provider.filteredKosList.first.id, '1');

      // Filter fasilitas 'AC' AND 'Parkir' (tidak ada kos yang memiliki keduanya)
      provider.setFilter(facilities: ['AC', 'Parkir']);
      expect(provider.filteredKosList, isEmpty);
      expect(provider.isSearchEmpty, isTrue);
    });

    test('Combined search area, max price, and facility filter (US03)', () async {
      final provider = KosProvider(
        repository: FakeSuccessKosRepository(sampleKosList),
      );

      await provider.fetchKosList();

      // Cari area Singaraja + maks harga Rp1.000.000 + fasilitas WiFi -> hanya kos 1
      provider.setSearchQuery('Singaraja');
      provider.setFilter(maxPrice: 1000000, facilities: ['WiFi']);

      expect(provider.filteredKosList.length, 1);
      expect(provider.filteredKosList.first.nama, 'Kos Mawar Indah');

      // Reset semua
      provider.resetAll();
      expect(provider.filteredKosList.length, 3);
      expect(provider.searchQuery, isEmpty);
      expect(provider.isFilterActive, isFalse);
    });

    test('Search area with no matches returns empty filtered list and isSearchEmpty true (US03-AC4)', () async {
      final provider = KosProvider(
        repository: FakeSuccessKosRepository(sampleKosList),
      );

      await provider.fetchKosList();

      provider.setSearchQuery('Gianyar');
      expect(provider.filteredKosList, isEmpty);
      expect(provider.isSearchEmpty, isTrue);

      // Reset search
      provider.clearSearchQuery();
      expect(provider.filteredKosList.length, 3);
      expect(provider.isSearchEmpty, isFalse);
    });

    test('fetchKosList transitions to loaded and isEmpty is true when database empty', () async {
      final provider = KosProvider(repository: FakeSuccessKosRepository([]));

      await provider.fetchKosList();

      expect(provider.state, KosState.loaded);
      expect(provider.isEmpty, isTrue);
      expect(provider.hasError, isFalse);
    });

    test('fetchKosList transitions to error when repository fails', () async {
      final provider = KosProvider(repository: FakeFailureKosRepository());

      await provider.fetchKosList();

      expect(provider.state, KosState.error);
      expect(provider.hasError, isTrue);
      expect(provider.errorMessage, contains('Gagal memuat data kos'));
    });

    test('fetchKosList keeps the newest result when requests complete out of order', () async {
      final repository = DelayedKosRepository();
      final provider = KosProvider(repository: repository);

      final olderRequest = provider.fetchKosList();
      final newerRequest = provider.fetchKosList();

      repository.requests[1].complete([sampleKosList[1]]);
      await newerRequest;
      repository.requests[0].complete([sampleKosList[0]]);
      await olderRequest;

      expect(provider.state, KosState.loaded);
      expect(provider.kosList, [sampleKosList[1]]);
      expect(provider.errorMessage, isNull);
    });

    test('fetchKosList ignores errors from stale requests', () async {
      final repository = DelayedKosRepository();
      final provider = KosProvider(repository: repository);

      final olderRequest = provider.fetchKosList();
      final newerRequest = provider.fetchKosList();

      repository.requests[1].complete([sampleKosList[1]]);
      await newerRequest;
      repository.requests[0].completeError(Exception('stale request failed'));
      await olderRequest;

      expect(provider.state, KosState.loaded);
      expect(provider.kosList, [sampleKosList[1]]);
      expect(provider.errorMessage, isNull);
    });
  });
}
