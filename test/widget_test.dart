import 'package:flutter_test/flutter_test.dart';
import 'package:speakera/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SpeakeraApp());

    // Verify login screen is shown
    expect(find.text('Speakera'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
