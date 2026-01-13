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

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Verify profile fields are present
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

      // Verify action buttons
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

      // Verify logout icon is present
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('ProfileScreen should show delete confirmation dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProfileScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap delete account button
      final deleteButton = find.text('Delete Account');
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.text('Delete Account'), findsWidgets);
      expect(find.text('Are you sure?'), findsOneWidget);
    });
  });
}
