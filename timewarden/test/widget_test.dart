import 'package:flutter_test/flutter_test.dart';

import 'package:timewarden/main.dart';

void main() {
  testWidgets('TimeWarden app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TimeWardenApp());

    // Verify that the app loads properly
    expect(find.text('TimeWarden'), findsOneWidget);
  });
}
