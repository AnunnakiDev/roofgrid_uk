enum LabourPricingMode {
  direct,
  subContractor,
}

extension LabourPricingModeLabels on LabourPricingMode {
  String get label {
    switch (this) {
      case LabourPricingMode.direct:
        return 'Direct customer';
      case LabourPricingMode.subContractor:
        return 'Sub-contractor';
    }
  }
}