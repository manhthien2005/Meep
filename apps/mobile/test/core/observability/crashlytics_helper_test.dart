import 'package:flutter_test/flutter_test.dart';
import 'package:meep/core/observability/crashlytics_helper.dart';

void main() {
  group('CrashlyticsHelper.scrub', () {
    test('redacts email addresses', () {
      final out = CrashlyticsHelper.scrub('login failed for thien@meep.dev');
      expect(out, isNot(contains('thien@meep.dev')));
      expect(out, contains('[EMAIL]'));
    });

    test('redacts caption key-value', () {
      final out =
          CrashlyticsHelper.scrub('post error caption="bi mat cua toi"');
      expect(out, isNot(contains('bi mat cua toi')));
      expect(out, contains('[REDACTED]'));
    });

    test('redacts displayName key-value', () {
      final out = CrashlyticsHelper.scrub('displayName: "Pham Thien"');
      expect(out, isNot(contains('Pham Thien')));
    });

    test('redacts fcm token', () {
      final out = CrashlyticsHelper.scrub('fcmToken=abc123APA91def');
      expect(out, isNot(contains('APA91def')));
      expect(out, contains('[REDACTED]'));
    });

    test('redacts phone numbers', () {
      final out = CrashlyticsHelper.scrub('contact +84 912 345 678 failed');
      expect(out, isNot(contains('912 345 678')));
      expect(out, contains('[PHONE]'));
    });

    test('keeps non-PII technical message intact', () {
      const msg = 'PERMISSION_DENIED: Missing or insufficient permissions';
      expect(CrashlyticsHelper.scrub(msg), msg);
    });
  });
}
