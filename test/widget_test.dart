import 'package:flutter_test/flutter_test.dart';
import 'package:abbitat_mobile/app.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const AbbitatApp());
    // Just verify it builds without errors
    expect(find.text('Abbitat'), findsAny);
  });
}
