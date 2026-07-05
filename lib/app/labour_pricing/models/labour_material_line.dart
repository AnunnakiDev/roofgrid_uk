/// A material line on a project or section quote (BoQ row).
class LabourMaterialLine {
  final String? priceListEntryId;
  final String description;
  final String unit;
  final double suggestedQty;
  final double? overrideQty;
  final double unitPrice;
  final String notes;

  const LabourMaterialLine({
    this.priceListEntryId,
    required this.description,
    required this.unit,
    this.suggestedQty = 0,
    this.overrideQty,
    required this.unitPrice,
    this.notes = '',
  });

  double get effectiveQty {
    if (overrideQty != null && overrideQty! >= 0) return overrideQty!;
    return suggestedQty;
  }

  double get lineTotalGbp => effectiveQty * unitPrice;

  bool get hasQuantity => effectiveQty > 0;

  LabourMaterialLine copyWith({
    String? priceListEntryId,
    bool clearPriceListEntryId = false,
    String? description,
    String? unit,
    double? suggestedQty,
    double? overrideQty,
    bool clearOverrideQty = false,
    double? unitPrice,
    String? notes,
  }) {
    return LabourMaterialLine(
      priceListEntryId: clearPriceListEntryId
          ? null
          : (priceListEntryId ?? this.priceListEntryId),
      description: description ?? this.description,
      unit: unit ?? this.unit,
      suggestedQty: suggestedQty ?? this.suggestedQty,
      overrideQty:
          clearOverrideQty ? null : (overrideQty ?? this.overrideQty),
      unitPrice: unitPrice ?? this.unitPrice,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        if (priceListEntryId != null) 'priceListEntryId': priceListEntryId,
        'description': description,
        'unit': unit,
        'suggestedQty': suggestedQty,
        if (overrideQty != null) 'overrideQty': overrideQty,
        'unitPrice': unitPrice,
        'notes': notes,
      };

  factory LabourMaterialLine.fromJson(Map<String, dynamic> json) {
    return LabourMaterialLine(
      priceListEntryId: json['priceListEntryId'] as String?,
      description: json['description'] as String? ?? '',
      unit: json['unit'] as String? ?? 'each',
      suggestedQty: (json['suggestedQty'] as num?)?.toDouble() ?? 0,
      overrideQty: (json['overrideQty'] as num?)?.toDouble(),
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String? ?? '',
    );
  }
}