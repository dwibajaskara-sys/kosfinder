import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/main.dart';

void main() {
  testWidgets('KosFinderApp smoke test displays app title', (WidgetTester tester) async {
    await tester.pumpWidget(const KosFinderApp());
    // Biarkan frame awal dan microtasks selesai
    await tester.pump();

    expect(find.text('KosFinder'), findsOneWidget);
  });
}
