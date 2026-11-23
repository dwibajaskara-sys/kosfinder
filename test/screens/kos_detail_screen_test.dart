import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos.dart';
import 'package:kosfinder/screens/kos_detail_screen.dart';

void main() {
  final testKos = Kos(
    id: 'kos-test-01',
    createdAt: DateTime.now(),
    pemilikId: 'owner-01',
    nama: 'Kos Danau Beratan',
    area: 'Singaraja',
    hargaPerBulan: 850000,
    deskripsi: 'Kamar mandi dalam, lingkungan bersih dan tenang.',
    fasilitas: const ['WiFi', 'AC', 'Kamar Mandi Dalam'],
    kontakPemilik: '081999888777',
    status: 'Tersedia',
  );

  group('KosDetailScreen Widget Tests', () {
    testWidgets('Displays all kos details properly (US02-AC1)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: KosDetailScreen(kos: testKos),
        ),
      );

      // Verifikasi nama dan area
      expect(find.text('Kos Danau Beratan'), findsWidgets);
      expect(find.text('Singaraja'), findsOneWidget);

      // Verifikasi format harga dan status badge
      expect(find.text('Rp 850.000 / bulan'), findsOneWidget);
      expect(find.text('Tersedia'), findsOneWidget);

      // Verifikasi fasilitas chips
      expect(find.text('WiFi'), findsOneWidget);
      expect(find.text('AC'), findsOneWidget);
      expect(find.text('Kamar Mandi Dalam'), findsOneWidget);

      // Scroll untuk memastikan deskripsi dan kontak terlihat
      await tester.ensureVisible(find.text('081999888777'));
      await tester.pumpAndSettle();

      expect(find.text('Kamar mandi dalam, lingkungan bersih dan tenang.'), findsOneWidget);
      expect(find.text('081999888777'), findsOneWidget);
    });

    testWidgets('Tapping contact copies number to clipboard and shows snackbar (US02-AC2)',
        (WidgetTester tester) async {
      final List<MethodCall> log = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        log.add(methodCall);
        return null;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: KosDetailScreen(kos: testKos),
        ),
      );

      // Scroll hingga kartu kontak terlihat di layar
      final contactFinder = find.text('081999888777');
      await tester.ensureVisible(contactFinder);
      await tester.pumpAndSettle();

      // Tap kontak pemilik
      await tester.tap(contactFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifikasi snackbar 'Nomor disalin' tampil
      expect(find.text('Nomor disalin'), findsOneWidget);

      // Verifikasi pemanggilan Clipboard API
      final clipboardCalls = log.where((call) => call.method == 'Clipboard.setData');
      expect(clipboardCalls, isNotEmpty);
      expect(clipboardCalls.first.arguments['text'], '081999888777');
    });
  });
}
