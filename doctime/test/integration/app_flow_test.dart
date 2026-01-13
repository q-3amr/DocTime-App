import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doctime/screens/auth/login_screen.dart';
import 'package:doctime/screens/auth/signup_screen.dart';

void main() {
  group('App Integration Tests', () {
    testWidgets('LoginScreen should display correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('SignupScreen should display correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SignupScreen()));

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('Sign up'), findsWidgets);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
    });

    testWidgets('User can navigate from login to signup', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: LoginScreen()));

      await tester.pumpAndSettle();

      final signUpLink = find.text('Sign up');
      expect(signUpLink, findsOneWidget);

      await tester.ensureVisible(signUpLink);
      await tester.tap(signUpLink, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Sign up'), findsWidgets);
      expect(find.text('Create your new account'), findsOneWidget);
    });

    testWidgets('User can navigate from signup to login', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: SignupScreen()));

      await tester.pumpAndSettle();

      final loginLink = find.text('Login');
      expect(loginLink, findsOneWidget);

      await tester.ensureVisible(loginLink);
      await tester.tap(loginLink, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Log in'), findsOneWidget);
    });
  });
}
