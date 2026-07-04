import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/utils/admin_utils.dart';

void main() {
  group('isDesignatedAdminEmail', () {
    test('returns true for designated admin emails', () {
      expect(isDesignatedAdminEmail('hgwarner1307@gmail.com'), isTrue);
      expect(isDesignatedAdminEmail('support@roofgrid.uk'), isTrue);
    });

    test('is case insensitive', () {
      expect(isDesignatedAdminEmail('HGWarner1307@Gmail.COM'), isTrue);
      expect(isDesignatedAdminEmail('SUPPORT@ROOFGRID.UK'), isTrue);
    });

    test('returns false for non-admin emails', () {
      expect(isDesignatedAdminEmail('user@example.com'), isFalse);
      expect(isDesignatedAdminEmail('admin@example.com'), isFalse);
    });

    test('returns false for null', () {
      expect(isDesignatedAdminEmail(null), isFalse);
    });
  });
}