import 'package:roofgrid_uk/app/results/models/saved_result.dart';

const _verticalInputKeys = {
  'rafterHeights',
  'gutterOverhang',
  'useDryRidge',
};

const _horizontalInputKeys = {
  'widths',
  'useDryVerge',
  'abutmentSide',
  'useLHTile',
  'crossBonded',
};

bool _hasAnyKey(Map<String, dynamic> map, Set<String> keys) {
  return keys.any((key) => map.containsKey(key));
}

/// Normalizes legacy flat inputs to nested `vertical_inputs` / `horizontal_inputs`.
Map<String, dynamic> normalizeSavedResultInputsMap(
  CalculationType type,
  Map<String, dynamic> inputs,
) {
  final normalized = Map<String, dynamic>.from(inputs);

  if (type == CalculationType.combined) {
    if (normalized['vertical_inputs'] is Map<String, dynamic> &&
        normalized['horizontal_inputs'] is Map<String, dynamic>) {
      return normalized;
    }

    final vertical = <String, dynamic>{};
    final horizontal = <String, dynamic>{};

    for (final key in _verticalInputKeys) {
      if (normalized.containsKey(key)) {
        vertical[key] = normalized.remove(key);
      }
    }
    for (final key in _horizontalInputKeys) {
      if (normalized.containsKey(key)) {
        horizontal[key] = normalized.remove(key);
      }
    }

    if (vertical.isNotEmpty) {
      normalized['vertical_inputs'] = vertical;
    }
    if (horizontal.isNotEmpty) {
      normalized['horizontal_inputs'] = horizontal;
    }
    return normalized;
  }

  if (type == CalculationType.vertical) {
    if (normalized['vertical_inputs'] is Map<String, dynamic>) {
      return normalized;
    }
    if (_hasAnyKey(normalized, _verticalInputKeys)) {
      final vertical = <String, dynamic>{};
      for (final key in _verticalInputKeys) {
        if (normalized.containsKey(key)) {
          vertical[key] = normalized.remove(key);
        }
      }
      normalized['vertical_inputs'] = vertical;
    }
    return normalized;
  }

  if (normalized['horizontal_inputs'] is Map<String, dynamic>) {
    return normalized;
  }
  if (_hasAnyKey(normalized, _horizontalInputKeys)) {
    final horizontal = <String, dynamic>{};
    for (final key in _horizontalInputKeys) {
      if (normalized.containsKey(key)) {
        horizontal[key] = normalized.remove(key);
      }
    }
    normalized['horizontal_inputs'] = horizontal;
  }
  return normalized;
}

SavedResult normalizeSavedResult(SavedResult result) {
  final normalizedInputs =
      normalizeSavedResultInputsMap(result.type, result.inputs);
  if (identical(normalizedInputs, result.inputs) ||
      _mapsEqual(normalizedInputs, result.inputs)) {
    return result;
  }
  return SavedResult(
    id: result.id,
    userId: result.userId,
    projectName: result.projectName,
    type: result.type,
    timestamp: result.timestamp,
    inputs: normalizedInputs,
    outputs: result.outputs,
    tile: result.tile,
    createdAt: result.createdAt,
    updatedAt: result.updatedAt,
  );
}

bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

Map<String, dynamic> normalizeCalculationInputsForSave(
  String type,
  Map<String, dynamic> inputs,
) {
  switch (type) {
    case 'vertical':
      return normalizeSavedResultInputsMap(
        CalculationType.vertical,
        inputs,
      );
    case 'horizontal':
      return normalizeSavedResultInputsMap(
        CalculationType.horizontal,
        inputs,
      );
    case 'combined':
      return normalizeSavedResultInputsMap(
        CalculationType.combined,
        inputs,
      );
    default:
      return inputs;
  }
}