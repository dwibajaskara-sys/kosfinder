import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/main.dart';

void main() {
  testWidgets('KosFinderApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KosFinderApp());

    expect(find.text('KosFinder'), findsOneWidget);
  });
}
