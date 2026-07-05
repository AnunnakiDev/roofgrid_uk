import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/utils/decimal_input_utils.dart';

void main() {
  group('decimalInputDisplayText', () {
    test('empty for zero', () {
      expect(decimalInputDisplayText(0), '');
    });

    test('no trailing decimal for whole numbers', () {
      expect(decimalInputDisplayText(1), '1');
      expect(decimalInputDisplayText(40), '40');
    });

    test('keeps fractional values', () {
      expect(decimalInputDisplayText(12.5), '12.5');
    });
  });

  group('applyDecimalInputChange', () {
    test('defers updates while decimal point is trailing', () {
      double? latest;
      applyDecimalInputChange('12.', (value) => latest = value);
      expect(latest, isNull);
    });

    test('parses complete numbers', () {
      double? latest;
      applyDecimalInputChange('125', (value) => latest = value);
      expect(latest, 125);
    });
  });
}