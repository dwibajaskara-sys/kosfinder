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

void main() {
  final sampleKosList = [
    Kos(
      id: '1',
      createdAt: DateTime.now(),
      pemilikId: 'owner-1',
      nama: 'Kos Mawar Indah',
      area: 'Singaraja',
      hargaPerBulan: 800000,
      deskripsi: 'Deskripsi',
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
      hargaPerBulan: 1200000,
      deskripsi: 'Deskripsi',
      fasilitas: const ['WiFi', 'Parkir'],
      kontakPemilik: '089876543210',
      status: 'Tersedia',
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
    });

    test('fetchKosList transitions to loaded with data on success', () async {
      final provider = KosProvider(
        repository: FakeSuccessKosRepository(sampleKosList),
      );

      await provider.fetchKosList();

      expect(provider.state, KosState.loaded);
      expect(provider.isLoading, isFalse);
      expect(provider.hasError, isFalse);
      expect(provider.kosList.length, 2);
      expect(provider.filteredKosList.length, 2);
      expect(provider.isEmpty, isFalse);
    });

    test('Search area is case-insensitive (US03-AC1)', () async {
      final provider = KosProvider(
        repository: FakeSuccessKosRepository(sampleKosList),
      );

      await provider.fetchKosList();

      // Cari 'singaraja' huruf kecil
      provider.setSearchQuery('singaraja');
      expect(provider.filteredKosList.length, 1);
      expect(provider.filteredKosList.first.nama, 'Kos Mawar Indah');
      expect(provider.isSearchEmpty, isFalse);

      // Cari 'Singaraja' huruf kapital
      provider.setSearchQuery('Singaraja');
      expect(provider.filteredKosList.length, 1);
      expect(provider.filteredKosList.first.nama, 'Kos Mawar Indah');

      // Cari 'SINGARAJA' huruf besar semua
      provider.setSearchQuery('SINGARAJA');
      expect(provider.filteredKosList.length, 1);
      expect(provider.filteredKosList.first.nama, 'Kos Mawar Indah');
    });

    test('Search area with no matches returns empty filtered list and isSearchEmpty true (US03-AC4)', () async {
      final provider = KosProvider(
        repository: FakeSuccessKosRepository(sampleKosList),
      );

      await provider.fetchKosList();

      provider.setSearchQuery('Kuta');
      expect(provider.filteredKosList, isEmpty);
      expect(provider.isSearchEmpty, isTrue);

      // Reset search
      provider.clearSearchQuery();
      expect(provider.filteredKosList.length, 2);
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
  });
}
