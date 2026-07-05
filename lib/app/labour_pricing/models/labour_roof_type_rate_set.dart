import 'package:roofgrid_uk/app/labour_pricing/models/labour_item_money_rates.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_pricing_money_rates.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_rate_profile.dart';

/// Per-roof-type rates for Method A (£) and Method B (hours) calculations.
class LabourRoofTypeRateSet {
  final LabourPricingMoneyRates directMoney;
  final LabourPricingMoneyRates subMoney;
  final LabourItemMoneyRates directItemMoney;
  final LabourItemMoneyRates subItemMoney;
  final LabourRateProfile directTiming;
  final LabourRateProfile subTiming;

  const LabourRoofTypeRateSet({
    required this.directMoney,
    required this.subMoney,
    required this.directItemMoney,
    required this.subItemMoney,
    required this.directTiming,
    required this.subTiming,
  });

  LabourRoofTypeRateSet copyWith({
    LabourPricingMoneyRates? directMoney,
    LabourPricingMoneyRates? subMoney,
    LabourItemMoneyRates? directItemMoney,
    LabourItemMoneyRates? subItemMoney,
    LabourRateProfile? directTiming,
    LabourRateProfile? subTiming,
  }) {
    return LabourRoofTypeRateSet(
      directMoney: directMoney ?? this.directMoney,
      subMoney: subMoney ?? this.subMoney,
      directItemMoney: directItemMoney ?? this.directItemMoney,
      subItemMoney: subItemMoney ?? this.subItemMoney,
      directTiming: directTiming ?? this.directTiming,
      subTiming: subTiming ?? this.subTiming,
    );
  }

  Map<String, dynamic> toJson() => {
        'directMoney': directMoney.toJson(),
        'subMoney': subMoney.toJson(),
        'directItemMoney': directItemMoney.toJson(),
        'subItemMoney': subItemMoney.toJson(),
        'directTiming': directTiming.toJson(),
        'subTiming': subTiming.toJson(),
      };

  factory LabourRoofTypeRateSet.fromJson(Map<String, dynamic> json) {
    return LabourRoofTypeRateSet(
      directMoney: LabourPricingMoneyRates.fromJson(
        Map<String, dynamic>.from(json['directMoney'] as Map),
      ),
      subMoney: LabourPricingMoneyRates.fromJson(
        Map<String, dynamic>.from(json['subMoney'] as Map),
      ),
      directItemMoney: json['directItemMoney'] != null
          ? LabourItemMoneyRates.fromJson(
              Map<String, dynamic>.from(json['directItemMoney'] as Map),
            )
          : const LabourItemMoneyRates(
              linearRatePerMetre: {},
              ancillaryRateEach: {},
            ),
      subItemMoney: json['subItemMoney'] != null
          ? LabourItemMoneyRates.fromJson(
              Map<String, dynamic>.from(json['subItemMoney'] as Map),
            )
          : const LabourItemMoneyRates(
              linearRatePerMetre: {},
              ancillaryRateEach: {},
            ),
      directTiming: LabourRateProfile.fromJson(
        Map<String, dynamic>.from(json['directTiming'] as Map),
      ),
      subTiming: LabourRateProfile.fromJson(
        Map<String, dynamic>.from(json['subTiming'] as Map),
      ),
    );
  }
}