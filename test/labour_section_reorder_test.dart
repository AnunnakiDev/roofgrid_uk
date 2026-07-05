import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_mode.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_input.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_section.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';

LabourRoofSection _section(String id, String label) {
  return LabourRoofSection(
    id: id,
    label: label,
    input: const LabourQuoteInput(
      mode: LabourPricingMode.direct,
      roofType: LabourRoofType.traditionalPantile,
      roofAreaSqm: 10,
    ),
  );
}

void main() {
  test('section reorder moves item down by one position', () {
    final sections = [_section('section-1', 'Front'), _section('section-2', 'Rear')];
    const index = 0;
    const direction = 1;
    final target = index + direction;

    final item = sections.removeAt(index);
    sections.insert(target, item);

    expect(sections.map((section) => section.label).toList(), ['Rear', 'Front']);
  });
}