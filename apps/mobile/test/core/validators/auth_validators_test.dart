import 'package:flutter_test/flutter_test.dart';
import 'package:meep/core/validators/auth_validators.dart';

void main() {
  group('AuthValidators.isEmailValid', () {
    test('chấp nhận email hợp lệ', () {
      expect(AuthValidators.isEmailValid('alice@example.com'), isTrue);
      expect(AuthValidators.isEmailValid('a.b+tag@sub.example.co'), isTrue);
    });

    test('trim trước khi check', () {
      expect(AuthValidators.isEmailValid('  alice@example.com  '), isTrue);
    });

    test('reject khi thiếu @', () {
      expect(AuthValidators.isEmailValid('aliceexample.com'), isFalse);
    });

    test('reject khi thiếu TLD', () {
      expect(AuthValidators.isEmailValid('alice@example'), isFalse);
    });

    test('reject TLD < 2 ký tự', () {
      expect(AuthValidators.isEmailValid('a@b.c'), isFalse);
    });

    test('reject empty + chỉ whitespace', () {
      expect(AuthValidators.isEmailValid(''), isFalse);
      expect(AuthValidators.isEmailValid('   '), isFalse);
    });

    test('reject khi có khoảng trắng giữa', () {
      expect(AuthValidators.isEmailValid('alice @example.com'), isFalse);
      expect(AuthValidators.isEmailValid('alice@exa mple.com'), isFalse);
    });
  });

  group('AuthValidators.isPasswordValid', () {
    test('đúng min length (8 ký tự)', () {
      expect(AuthValidators.isPasswordValid('12345678'), isTrue);
    });

    test('reject < min length', () {
      expect(AuthValidators.isPasswordValid('1234567'), isFalse);
      expect(AuthValidators.isPasswordValid(''), isFalse);
    });

    test('không trim password', () {
      // Password 7 chars padded với 1 space — vẫn 8 chars → valid
      expect(AuthValidators.isPasswordValid('1234567 '), isTrue);
    });
  });

  group('AuthValidators.isDisplayNameValid', () {
    test('chấp nhận tên ≥ 2 ký tự sau trim', () {
      expect(AuthValidators.isDisplayNameValid('Alice'), isTrue);
      expect(AuthValidators.isDisplayNameValid('Al'), isTrue);
    });

    test('trim trước khi check', () {
      expect(AuthValidators.isDisplayNameValid('  Al  '), isTrue);
      expect(AuthValidators.isDisplayNameValid('   A   '), isFalse);
    });

    test('reject empty / chỉ space', () {
      expect(AuthValidators.isDisplayNameValid(''), isFalse);
      expect(AuthValidators.isDisplayNameValid(' '), isFalse);
    });
  });

  group('AuthValidators.isUsernameFormatValid', () {
    test('chấp nhận lowercase alphanumeric + underscore, 3..20', () {
      expect(AuthValidators.isUsernameFormatValid('alice'), isTrue);
      expect(AuthValidators.isUsernameFormatValid('alice_123'), isTrue);
      expect(AuthValidators.isUsernameFormatValid('a_b'), isTrue);
      expect(AuthValidators.isUsernameFormatValid('a' * 20), isTrue);
    });

    test('reject < 3 ký tự', () {
      expect(AuthValidators.isUsernameFormatValid('ab'), isFalse);
    });

    test('reject > 20 ký tự', () {
      expect(AuthValidators.isUsernameFormatValid('a' * 21), isFalse);
    });

    test('reject uppercase', () {
      expect(AuthValidators.isUsernameFormatValid('Alice'), isFalse);
    });

    test('reject ký tự đặc biệt (dấu chấm, dấu gạch ngang, space)', () {
      expect(AuthValidators.isUsernameFormatValid('alice.nguyen'), isFalse);
      expect(AuthValidators.isUsernameFormatValid('alice-nguyen'), isFalse);
      expect(AuthValidators.isUsernameFormatValid('alice nguyen'), isFalse);
    });

    test('reject empty', () {
      expect(AuthValidators.isUsernameFormatValid(''), isFalse);
    });
  });
}
