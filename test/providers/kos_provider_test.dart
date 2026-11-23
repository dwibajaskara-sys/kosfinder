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
  group('KosProvider Unit Tests', () {
    test('Initial state is KosState.initial and empty', () {
      final provider = KosProvider(repository: FakeSuccessKosRepository([]));

      expect(provider.state, KosState.initial);
      expect(provider.isLoading, isFalse);
      expect(provider.hasError, isFalse);
      expect(provider.kosList, isEmpty);
    });

    test('fetchKosList transitions to loaded with data on success', () async {
      final sampleKos = Kos(
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
      );

      final provider = KosProvider(
        repository: FakeSuccessKosRepository([sampleKos]),
      );

      await provider.fetchKosList();

      expect(provider.state, KosState.loaded);
      expect(provider.isLoading, isFalse);
      expect(provider.hasError, isFalse);
      expect(provider.kosList.length, 1);
      expect(provider.kosList.first.nama, 'Kos Mawar Indah');
      expect(provider.isEmpty, isFalse);
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
