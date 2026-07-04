import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/utils/connectivity_utils.dart';

void main() {
  group('isOnlineFromResults', () {
    test('returns true when wifi is available', () {
      expect(isOnlineFromResults([ConnectivityResult.wifi]), isTrue);
    });

    test('returns true when mobile data is available', () {
      expect(isOnlineFromResults([ConnectivityResult.mobile]), isTrue);
    });

    test('returns false when only none is reported', () {
      expect(isOnlineFromResults([ConnectivityResult.none]), isFalse);
    });

    test('returns false when result list is empty', () {
      expect(isOnlineFromResults([]), isFalse);
    });
  });
}