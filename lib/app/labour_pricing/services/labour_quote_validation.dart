import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_method.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_project.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_section.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_section_calculator.dart';

class LabourQuoteValidation {
  LabourQuoteValidation._();

  static String? validateForCalculate(LabourQuoteProject project) {
    final quotableSections = <LabourRoofSection>[];
    final emptySections = <String>[];

    for (final section in project.sections) {
      if (_sectionQuotable(section)) {
        quotableSections.add(section);
      } else {
        emptySections.add(section.label);
      }
    }

    if (quotableSections.isEmpty) {
      if (emptySections.length == 1) {
        return 'Enter roof area, linear metres, ancillaries, or complexity '
            'measurements in "${emptySections.first}"';
      }
      return 'Enter quantities in at least one section '
          '(${emptySections.join(', ')})';
    }

    for (final section in quotableSections) {
      if (section.selectedMethod == LabourQuoteMethod.manualOverride) {
        final manual = section.manualOverrideGbp;
        if (manual == null || manual <= 0) {
          return 'Enter a manual labour cost for "${section.label}"';
        }
      }
    }

    if (emptySections.isNotEmpty && quotableSections.isNotEmpty) {
      return null;
    }

    return null;
  }

  static String? warningForSkippedSections(LabourQuoteProject project) {
    final emptySections = project.sections
        .where((section) => !_sectionQuotable(section))
        .map((section) => section.label)
        .toList();
    if (emptySections.isEmpty) return null;
    if (emptySections.length == 1) {
      return '"${emptySections.first}" has no quantities and was skipped';
    }
    return '${emptySections.length} sections skipped (no quantities): '
        '${emptySections.join(', ')}';
  }

  static bool _sectionQuotable(LabourRoofSection section) {
    final effective = LabourSectionCalculator.effectiveInput(section);
    if (effective.hasQuantities) return true;
    return LabourSectionCalculator.calcParams(section).additionalHours > 0;
  }
}