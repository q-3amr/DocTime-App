import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctime/screens/common/profile_screen.dart';

void main() {
  group('ProfileScreen Widget Tests', () {
    testWidgets('ProfileScreen should display profile fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
    });

    testWidgets('ProfileScreen should have save and delete buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Delete Account'), findsOneWidget);
    });

    testWidgets('ProfileScreen should show logout button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('ProfileScreen should show delete confirmation dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final deleteButton = find.text('Delete Account');
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      expect(find.text('Delete Account'), findsWidgets);
      expect(find.text('Are you sure?'), findsOneWidget);
    });
  });
}
