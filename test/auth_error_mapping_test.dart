import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/utils/auth_error_utils.dart';

void main() {
  test('mapFirebaseAuthError includes email link action code errors', () {
    expect(
      mapFirebaseAuthError('invalid-action-code'),
      contains('invalid'),
    );
    expect(
      mapFirebaseAuthError('expired-action-code'),
      contains('expired'),
    );
    expect(
      mapFirebaseAuthError('invalid-credential'),
      contains('link'),
    );
    expect(
      mapFirebaseAuthError('invalid-continue-uri'),
      contains('configuration'),
    );
    expect(
      mapFirebaseAuthError('unauthorized-domain'),
      contains('authorized'),
    );
  });
}