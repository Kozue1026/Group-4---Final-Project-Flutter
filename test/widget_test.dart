import 'package:flutter_application_1/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EventHub app builds (with or without Firebase config)',
      (WidgetTester tester) async {
    await tester.pumpWidget(const EventHubApp());
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('EventHub'), findsWidgets);
  });
}
