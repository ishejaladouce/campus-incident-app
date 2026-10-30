import 'package:flutter_test/flutter_test.dart';
import 'package:campus_incident_app/utils/validators.dart';

void main() {
  group('Email validator', () {
    test('accepts ALU student emails', () {
      expect(Validators.aluEmail('ladouce@alustudent.com'), isNull);
    });

    test('accepts ALU staff emails', () {
      expect(Validators.aluEmail('staff@alueducation.com'), isNull);
    });

    test('rejects non-ALU emails', () {
      expect(Validators.aluEmail('someone@gmail.com'), isNotNull);
    });

    test('rejects empty email', () {
      expect(Validators.aluEmail(''), isNotNull);
    });
  });

  group('Password validator', () {
    test('rejects short passwords', () {
      expect(Validators.password('123'), isNotNull);
    });

    test('accepts passwords with 6+ characters', () {
      expect(Validators.password('secret123'), isNull);
    });
  });
}