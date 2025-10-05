import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Basic widget test - Material App loads',
      (WidgetTester tester) async {
    // Build a simple Material app to test widget framework
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Test Widget'),
          ),
        ),
      ),
    );

    // Verify that the test widget loads properly
    expect(find.text('Test Widget'), findsOneWidget);
  });
}
