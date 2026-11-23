import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/repositories/kos_repository.dart';

void main() {
  group('KosRepository Unit Tests', () {
    test('KosRepository can be instantiated', () {
      final repo = KosRepository();
      expect(repo, isNotNull);
    });

    test('getPublicKosList throws descriptive error when client is not initialized', () async {
      final repo = KosRepository();
      // Ketika Supabase.initialize belum dipanggil, pemanggilan getPublicKosList akan melempar error
      expect(
        () async => await repo.getPublicKosList(),
        throwsA(isA<Exception>()),
      );
    });

    test('getKosById throws descriptive error when client is not initialized', () async {
      final repo = KosRepository();
      expect(
        () async => await repo.getKosById('invalid-id'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
