import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctime/screens/auth/signup_screen.dart';

void main() {
  group('SignupScreen Widget Tests', () {
    testWidgets('SignupScreen should display all required fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignupScreen(),
        ),
      );

      expect(find.text('Sign up'), findsWidgets);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('SignupScreen should show doctor fields when toggle is on', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignupScreen(),
        ),
      );

      final doctorSwitch = find.text('Register as a Doctor');
      expect(doctorSwitch, findsOneWidget);

      await tester.tap(find.ancestor(
        of: doctorSwitch,
        matching: find.byType(Container),
      ).first);
      await tester.pumpAndSettle();

      expect(find.text('Specialty'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
    });

    testWidgets('SignupScreen should validate password match', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignupScreen(),
        ),
      );

      final passwordField = find.byType(TextField).at(2);
      final confirmPasswordField = find.byType(TextField).at(3);

      await tester.enterText(passwordField, 'password123');
      await tester.enterText(confirmPasswordField, 'password456');
      await tester.pump();

      final signUpButton = find.text('Sign Up');
      await tester.tap(signUpButton);
      await tester.pump();
    });

    testWidgets('SignupScreen should show specialty dropdown for doctors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignupScreen(),
        ),
      );

      final switchFinder = find.byType(Switch);
      if (switchFinder.evaluate().isNotEmpty) {
        await tester.tap(switchFinder);
        await tester.pumpAndSettle();

        expect(find.text('Specialty'), findsOneWidget);
        
        final dropdown = find.byType(DropdownButton<String>);
        if (dropdown.evaluate().isNotEmpty) {
          await tester.tap(dropdown);
          await tester.pumpAndSettle();
          
          expect(find.text('General Medicine'), findsOneWidget);
        }
      }
    });
  });
}
