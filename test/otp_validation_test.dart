import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:gruve_app/features/auth/validators/signup_validator.dart';

void main() {
  group('OTP Validation Tests', () {
    test('validateOtpRealTime returns error for empty OTP', () {
      final error = SignupValidator.validateOtpRealTime('');
      expect(error, equals('Please enter the OTP'));
    });

    test('validateOtpRealTime returns error for short OTP', () {
      final error = SignupValidator.validateOtpRealTime('12');
      expect(error, equals('Enter a valid 4 digit OTP'));
    });

    test('validateOtpRealTime returns error for non-digit OTP', () {
      final error = SignupValidator.validateOtpRealTime('12a4');
      expect(error, equals('Enter a valid 4 digit OTP'));
    });

    test('validateOtpRealTime returns null for valid 4-digit OTP', () {
      final error = SignupValidator.validateOtpRealTime('1234');
      expect(error, isNull);
    });

    test('TextEditingController clear operation empties all controllers', () {
      final controllers = List.generate(4, (_) => TextEditingController(text: '9'));
      for (final c in controllers) {
        expect(c.text, equals('9'));
      }

      for (final c in controllers) {
        c.clear();
      }

      for (final c in controllers) {
        expect(c.text, isEmpty);
      }
    });
  });
}
