import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/utils/remember_me_storage.dart';

void main() {
  group('RememberMeStorage', () {
    test('isEnabled returns true only for stored true', () {
      expect(RememberMeStorage.isEnabled('true'), isTrue);
      expect(RememberMeStorage.isEnabled('false'), isFalse);
      expect(RememberMeStorage.isEnabled(null), isFalse);
      expect(RememberMeStorage.isEnabled(''), isFalse);
    });
  });
}