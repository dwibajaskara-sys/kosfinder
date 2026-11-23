import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/screens/about_screen.dart';

void main() {
  group('AboutScreen Widget Tests', () {
    testWidgets('Displays KosFinder title and student identity correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutScreen(),
        ),
      );

      // Verifikasi judul aplikasi
      expect(find.text('KosFinder'), findsOneWidget);
      expect(find.text('Aplikasi Pencarian & Pengelolaan Kos'), findsOneWidget);

      // Verifikasi identitas mahasiswa sesuai AGENTS.md
      expect(find.text('2415051068 - I Kadek Dwi Bajaskara'), findsOneWidget);
      expect(find.text('Versi 1.0.0'), findsOneWidget);
    });
  });
}
