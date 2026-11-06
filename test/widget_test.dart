import 'package:flutter_test/flutter_test.dart';
import 'package:campus_incident_app/services/auth_service.dart';
import 'package:campus_incident_app/utils/validators.dart';

void main() {
  group('ALU email check (regex)', () {
    test('accepts any valid student or staff email', () {
      const validEmails = [
        'ladouce@alustudent.com',
        'j.mugisha@alustudent.com',
        'amani.k2@alustudent.com',
        'grace_uwase@alustudent.com',
        'p.niyonzima@alueducation.com',
      ];
      for (final email in validEmails) {
        expect(AuthService.isAluEmail(email), isTrue, reason: email);
      }
    });

    test('ignores capital letters and spaces around', () {
      expect(AuthService.isAluEmail('  J.Mugisha@ALUSTUDENT.com '), isTrue);
    });

    test('rejects other domains and tricks', () {
      const invalidEmails = [
        'someone@gmail.com',
        '@alustudent.com',
        'me@alustudent.com.fake.net',
        'me@alustudent.org',
      ];
      for (final email in invalidEmails) {
        expect(AuthService.isAluEmail(email), isFalse, reason: email);
      }
    });
  });

  group('Email validator', () {
    test('requires a value', () {
      expect(Validators.aluEmail(''), isNotNull);
    });

    test('rejects a badly formatted email', () {
      expect(Validators.aluEmail('j.mugisha.alustudent.com'), isNotNull);
      expect(Validators.aluEmail('j mugisha@alustudent.com'), isNotNull);
    });

    test('rejects a valid email that is not from ALU', () {
      expect(Validators.aluEmail('j.mugisha@gmail.com'), isNotNull);
    });

    test('accepts any valid ALU email', () {
      expect(Validators.aluEmail('j.mugisha@alustudent.com'), isNull);
      expect(Validators.aluEmail('p.niyonzima@alueducation.com'), isNull);
    });
  });

  group('Name validator', () {
    test('accepts normal names', () {
      expect(Validators.name('Isheja Ladouce'), isNull);
      expect(Validators.name('Jean Mugisha'), isNull);
      expect(Validators.name("Jean-Paul O'Neil"), isNull);
    });

    test('rejects empty, too short, or names with numbers', () {
      expect(Validators.name(''), isNotNull);
      expect(Validators.name('J'), isNotNull);
      expect(Validators.name('Jean123'), isNotNull);
    });
  });

  group('Password validators', () {
    test('new password needs 8+ characters with a letter and a number', () {
      expect(Validators.newPassword(''), isNotNull);
      expect(Validators.newPassword('abc12'), isNotNull);
      expect(Validators.newPassword('abcdefgh'), isNotNull);
      expect(Validators.newPassword('12345678'), isNotNull);
      expect(Validators.newPassword('secret123'), isNull);
    });

    test('login password only needs to be filled in', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('anything'), isNull);
    });

    test('confirm password must match', () {
      expect(Validators.confirmPassword('', 'secret123'), isNotNull);
      expect(Validators.confirmPassword('secret123', 'secret124'), isNotNull);
      expect(Validators.confirmPassword('secret123', 'secret123'), isNull);
    });
  });

  group('Text length validator', () {
    test('checks required, minimum and maximum length', () {
      expect(Validators.textLength('', fieldName: 'Title', max: 100), isNotNull);
      expect(Validators.textLength('   ', fieldName: 'Title', max: 100), isNotNull);
      expect(Validators.textLength('ab', fieldName: 'Title', min: 3, max: 100), isNotNull);
      expect(Validators.textLength('a' * 101, fieldName: 'Title', max: 100), isNotNull);
      expect(Validators.textLength('Broken chair', fieldName: 'Title', min: 3, max: 100), isNull);
    });
  });
}