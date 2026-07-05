import 'package:flutter_test/flutter_test.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_ancillary.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_item_money_rates.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_linear_item.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_roof_type_rate_set.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_defaults.dart';

void main() {
  test('rate set round-trips item money through json', () {
    final original = LabourDefaults.backendData2026
        .rateSetFor(LabourRoofType.traditionalPantile);
    final restored = LabourRoofTypeRateSet.fromJson(original.toJson());

    expect(
      restored.directItemMoney.linearRateFor(LabourLinearItem.leadBay),
      greaterThan(0),
    );
    expect(
      restored.directItemMoney.ancillaryRateFor(LabourAncillary.leadApron),
      greaterThan(0),
    );
  });

  test('LabourItemMoneyRates serializes maps', () {
    const rates = LabourItemMoneyRates(
      linearRatePerMetre: {LabourLinearItem.ridge: 6.88},
      ancillaryRateEach: {LabourAncillary.chimney: 110},
    );
    final restored = LabourItemMoneyRates.fromJson(rates.toJson());
    expect(restored.linearRateFor(LabourLinearItem.ridge), 6.88);
    expect(restored.ancillaryRateFor(LabourAncillary.chimney), 110);
  });
}