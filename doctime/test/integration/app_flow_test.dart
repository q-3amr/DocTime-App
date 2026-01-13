import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctime/main.dart';
import 'package:doctime/screens/auth/login_screen.dart';
import 'package:doctime/screens/auth/signup_screen.dart';

void main() {
  group('App Integration Tests', () {
    testWidgets('App should initialize and show guest home screen', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Verify app is running
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('User can navigate from login to signup', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Find sign up link
      final signUpLink = find.text('Sign up');
      expect(signUpLink, findsOneWidget);

      // Tap to navigate
      await tester.tap(signUpLink);
      await tester.pumpAndSettle();

      // Verify signup screen is shown
      expect(find.text('Sign up'), findsWidgets);
      expect(find.text('Create your new account'), findsOneWidget);
    });

    testWidgets('User can navigate from signup to login', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignupScreen(),
        ),
      );

      // Find login link
      final loginLink = find.text('Login');
      expect(loginLink, findsOneWidget);

      // Tap to navigate
      await tester.tap(loginLink);
      await tester.pumpAndSettle();

      // Verify login screen is shown
      expect(find.text('Log in'), findsOneWidget);
    });
  });
}
