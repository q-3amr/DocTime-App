import 'package:flutter_test/flutter_test.dart';
import 'package:doctime/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  group('AuthService Tests', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    test('AuthService should be initialized', () {
      expect(authService, isNotNull);
      expect(authService.auth, isNotNull);
      expect(authService.firestore, isNotNull);
    });

    test('currentUser should return null when not logged in', () {
      expect(authService.currentUser, isNull);
    });

    test('authStateChanges should return a stream', () {
      expect(authService.authStateChanges, isA<Stream<User?>>());
    });
  });
}
