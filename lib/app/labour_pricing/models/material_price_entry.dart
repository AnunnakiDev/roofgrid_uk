import 'package:roofgrid_uk/app/labour_pricing/models/material_category.dart';

const defaultMaterialWastePercent = 7.5;

/// One row in the user's personal material price list.
class MaterialPriceEntry {
  final String id;
  final MaterialCategory category;
  final String description;
  final String unit;
  final double coveragePerUnit;
  final double wastePercent;
  final double unitPrice;
  final String notes;

  const MaterialPriceEntry({
    required this.id,
    required this.category,
    required this.description,
    required this.unit,
    required this.coveragePerUnit,
    this.wastePercent = defaultMaterialWastePercent,
    required this.unitPrice,
    this.notes = '',
  });

  String get matchKey =>
      '${category.name}::${description.trim().toLowerCase()}';

  MaterialPriceEntry copyWith({
    String? id,
    MaterialCategory? category,
    String? description,
    String? unit,
    double? coveragePerUnit,
    double? wastePercent,
    double? unitPrice,
    String? notes,
  }) {
    return MaterialPriceEntry(
      id: id ?? this.id,
      category: category ?? this.category,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      coveragePerUnit: coveragePerUnit ?? this.coveragePerUnit,
      wastePercent: wastePercent ?? this.wastePercent,
      unitPrice: unitPrice ?? this.unitPrice,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'description': description,
        'unit': unit,
        'coveragePerUnit': coveragePerUnit,
        'wastePercent': wastePercent,
        'unitPrice': unitPrice,
        'notes': notes,
      };

  factory MaterialPriceEntry.fromJson(Map<String, dynamic> json) {
    return MaterialPriceEntry(
      id: json['id'] as String,
      category: materialCategoryFromName(json['category'] as String? ?? 'other'),
      description: json['description'] as String? ?? '',
      unit: json['unit'] as String? ?? 'each',
      coveragePerUnit: (json['coveragePerUnit'] as num?)?.toDouble() ?? 0,
      wastePercent:
          (json['wastePercent'] as num?)?.toDouble() ?? defaultMaterialWastePercent,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String? ?? '',
    );
  }
}