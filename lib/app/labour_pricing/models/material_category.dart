/// CSV / price-list categories for labour quote materials (spec §7).
enum MaterialCategory {
  tilesSlates,
  underlay,
  leadFlashings,
  ventilation,
  flatRoof,
  solar,
  structural,
  other,
}

extension MaterialCategoryLabels on MaterialCategory {
  String get label {
    switch (this) {
      case MaterialCategory.tilesSlates:
        return 'Tiles & slates';
      case MaterialCategory.underlay:
        return 'Underlay';
      case MaterialCategory.leadFlashings:
        return 'Lead & flashings';
      case MaterialCategory.ventilation:
        return 'Ventilation';
      case MaterialCategory.flatRoof:
        return 'Flat roof';
      case MaterialCategory.solar:
        return 'Solar';
      case MaterialCategory.structural:
        return 'Structural';
      case MaterialCategory.other:
        return 'Other';
    }
  }

  /// Spec CSV column value (PascalCase, no spaces).
  String get csvValue {
    switch (this) {
      case MaterialCategory.tilesSlates:
        return 'TilesSlates';
      case MaterialCategory.underlay:
        return 'Underlay';
      case MaterialCategory.leadFlashings:
        return 'LeadFlashings';
      case MaterialCategory.ventilation:
        return 'Ventilation';
      case MaterialCategory.flatRoof:
        return 'FlatRoof';
      case MaterialCategory.solar:
        return 'Solar';
      case MaterialCategory.structural:
        return 'Structural';
      case MaterialCategory.other:
        return 'Other';
    }
  }
}

MaterialCategory materialCategoryFromCsv(String raw) {
  final normalized = raw.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
  for (final category in MaterialCategory.values) {
    if (category.csvValue.toLowerCase() == normalized) return category;
    if (category.name.toLowerCase() == normalized) return category;
  }
  return MaterialCategory.other;
}

MaterialCategory materialCategoryFromName(String raw) {
  try {
    return MaterialCategory.values.byName(raw);
  } catch (_) {
    return materialCategoryFromCsv(raw);
  }
}