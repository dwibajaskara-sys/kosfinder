import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/repositories/kos_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

    test(
      'public and owner list queries preserve PostgREST error messages',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        final subscription = server.listen((request) async {
          request.response
            ..statusCode = HttpStatus.badRequest
            ..headers.contentType = ContentType.json
            ..write(
              '{"code":"42501","message":"permission denied",'
              '"details":null,"hint":null}',
            );
          await request.response.close();
        });
        final client = SupabaseClient(
          'http://127.0.0.1:${server.port}',
          'test-anon-key',
          postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
        );
        final repository = KosRepository(client: client);

        try {
          for (final fetch in [
            repository.getPublicKosList,
            () => repository.getOwnerKosList('owner-1'),
          ]) {
            await expectLater(
              fetch(),
              throwsA(
                isA<Exception>().having(
                  (error) => error.toString(),
                  'message',
                  contains('Gagal memuat data kos: permission denied'),
                ),
              ),
            );
          }
        } finally {
          await subscription.cancel();
          await server.close(force: true);
          await client.dispose();
        }
      },
    );

    test('public and owner list queries report socket errors as connection failures', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;
      await server.close();

      final client = SupabaseClient(
        'http://127.0.0.1:$port',
        'test-anon-key',
        postgrestOptions: const PostgrestClientOptions(retryEnabled: false),
      );
      final repository = KosRepository(client: client);

      try {
        for (final fetch in [
          repository.getPublicKosList,
          () => repository.getOwnerKosList('owner-1'),
        ]) {
          await expectLater(
            fetch(),
            throwsA(
              isA<Exception>().having(
                (error) => error.toString(),
                'message',
                contains(
                  'Gagal memuat data kos. Periksa koneksi internet Anda.',
                ),
              ),
            ),
          );
        }
      } finally {
        await client.dispose();
      }
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
