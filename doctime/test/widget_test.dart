import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doctime/main.dart';

void main() {
  testWidgets('DocTime app should initialize and show MaterialApp', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
