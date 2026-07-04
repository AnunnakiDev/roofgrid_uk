import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/services/firebase_bootstrap.dart';

void main() {
  test('configureFirebaseForPlatform is defined for platform bootstrap', () {
    expect(configureFirebaseForPlatform, isA<Future<void> Function()>());
  });
}