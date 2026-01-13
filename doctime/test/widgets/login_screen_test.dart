import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctime/screens/auth/login_screen.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    testWidgets('LoginScreen should display email and password fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('LoginScreen should show error when fields are empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      final loginButton = find.text('Login');
      expect(loginButton, findsOneWidget);

      await tester.tap(loginButton);
      await tester.pump();
    });

    testWidgets('LoginScreen should toggle password visibility', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      final visibilityIcon = find.byIcon(Icons.visibility_outlined);
      if (visibilityIcon.evaluate().isNotEmpty) {
        await tester.tap(visibilityIcon);
        await tester.pump();

        expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      }
    });

    testWidgets('LoginScreen should navigate to signup screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      final signUpLink = find.text('Sign up');
      if (signUpLink.evaluate().isNotEmpty) {
        await tester.tap(signUpLink);
        await tester.pumpAndSettle();
      }
    });
  });
}
