import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sets up common test configurations
void setupTests() {
  TestWidgetsFlutterBinding.ensureInitialized();
}

/// Pumps a widget with MaterialApp wrapper for widget tests
Future<void> pumpTestWidget(
  WidgetTester tester,
  Widget widget,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: widget,
      ),
    ),
  );
}
