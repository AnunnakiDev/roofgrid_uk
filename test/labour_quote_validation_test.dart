import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_method.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_project.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_section.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_quote_validation.dart';

void main() {
  group('LabourQuoteValidation', () {
    const filledInput = LabourQuoteInput(
      mode: LabourPricingMode.direct,
      roofType: LabourRoofType.traditionalPantile,
      roofAreaSqm: 30,
    );
    const emptyInput = LabourQuoteInput(
      mode: LabourPricingMode.direct,
      roofType: LabourRoofType.traditionalPantile,
      roofAreaSqm: 0,
    );

    test('rejects project with no quotable sections', () {
      final message = LabourQuoteValidation.validateForCalculate(
        LabourQuoteProject(
          sections: [
            const LabourRoofSection(
              id: 'a',
              label: 'Empty bay',
              input: emptyInput,
            ),
          ],
        ),
      );

      expect(message, isNotNull);
      expect(message, contains('Empty bay'));
    });

    test('requires manual labour when manual override selected', () {
      final message = LabourQuoteValidation.validateForCalculate(
        LabourQuoteProject(
          sections: [
            const LabourRoofSection(
              id: 'a',
              label: 'Manual section',
              input: filledInput,
              selectedMethod: LabourQuoteMethod.manualOverride,
            ),
          ],
        ),
      );

      expect(message, contains('manual labour cost'));
    });

    test('allows calculate when at least one section has quantities', () {
      final message = LabourQuoteValidation.validateForCalculate(
        LabourQuoteProject(
          sections: [
            const LabourRoofSection(
              id: 'a',
              label: 'Empty bay',
              input: emptyInput,
            ),
            const LabourRoofSection(
              id: 'b',
              label: 'Main roof',
              input: filledInput,
            ),
          ],
        ),
      );

      expect(message, isNull);
    });

    test('warns when some sections are skipped', () {
      final warning = LabourQuoteValidation.warningForSkippedSections(
        LabourQuoteProject(
          sections: [
            const LabourRoofSection(
              id: 'a',
              label: 'Empty bay',
              input: emptyInput,
            ),
            const LabourRoofSection(
              id: 'b',
              label: 'Main roof',
              input: filledInput,
            ),
          ],
        ),
      );

      expect(warning, contains('Empty bay'));
      expect(warning, contains('skipped'));
    });
  });
}