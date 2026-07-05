import 'package:csv/csv.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/material_category.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/material_price_entry.dart';

const materialCsvHeaders = [
  'Category',
  'Description',
  'Unit',
  'CoveragePerUnit',
  'WastePercent',
  'UnitPrice',
  'Notes',
];

class MaterialCsvImportResult {
  final int imported;
  final int updated;
  final int skipped;
  final List<String> errors;

  const MaterialCsvImportResult({
    this.imported = 0,
    this.updated = 0,
    this.skipped = 0,
    this.errors = const [],
  });

  bool get hasEntries => imported > 0 || updated > 0;

  int get totalProcessed => imported + updated + skipped;
}

class MaterialCsvService {
  MaterialCsvService._();

  static String exportCsv(List<MaterialPriceEntry> entries) {
    final sorted = [...entries]
      ..sort((a, b) {
        final category = a.category.label.compareTo(b.category.label);
        if (category != 0) return category;
        return a.description.compareTo(b.description);
      });

    final rows = <List<dynamic>>[
      materialCsvHeaders,
      ...sorted.map(
        (entry) => [
          entry.category.csvValue,
          entry.description,
          entry.unit,
          entry.coveragePerUnit,
          entry.wastePercent,
          entry.unitPrice,
          entry.notes,
        ],
      ),
    ];

    return const ListToCsvConverter().convert(rows);
  }

  static MaterialCsvParseResult parseImport(
    String csvContent, {
    required String idPrefix,
  }) {
    final normalized = csvContent
        .replaceFirst('\uFEFF', '')
        .replaceAll('\r\n', '\n')
        .trim();
    final rows = const CsvToListConverter(eol: '\n').convert(normalized);
    if (rows.isEmpty) {
      return MaterialCsvParseResult(
        errors: const ['CSV file is empty'],
      );
    }

    final headerIndex = _headerIndex(rows.first);
    if (headerIndex == null) {
      return MaterialCsvParseResult(
        errors: const ['Missing required columns in header row'],
      );
    }

    final parsed = <MaterialPriceEntry>[];
    final errors = <String>[];

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (_isEmptyRow(row)) continue;

      final lineNumber = i + 1;
      try {
        parsed.add(_entryFromRow(row, headerIndex, idPrefix, lineNumber));
      } catch (error) {
        errors.add('Row $lineNumber: $error');
      }
    }

    return MaterialCsvParseResult(entries: parsed, errors: errors);
  }

  static Map<String, int>? _headerIndex(List<dynamic> headerRow) {
    final normalized = headerRow
        .map((cell) => cell?.toString().trim().toLowerCase() ?? '')
        .toList();

    final index = <String, int>{};
    for (final required in [
      'category',
      'description',
      'unit',
      'coverageperunit',
      'unitprice',
    ]) {
      final found = normalized.indexOf(required);
      if (found < 0) return null;
      index[required] = found;
    }

    for (final optional in ['wastepercent', 'notes']) {
      final found = normalized.indexOf(optional);
      if (found >= 0) index[optional] = found;
    }

    return index;
  }

  static bool _isEmptyRow(List<dynamic> row) {
    return row.every((cell) => cell == null || cell.toString().trim().isEmpty);
  }

  static MaterialPriceEntry _entryFromRow(
    List<dynamic> row,
    Map<String, int> headerIndex,
    String idPrefix,
    int lineNumber,
  ) {
    String cell(String key) {
      final idx = headerIndex[key];
      if (idx == null || idx >= row.length) return '';
      return row[idx]?.toString().trim() ?? '';
    }

    final description = cell('description');
    if (description.isEmpty) {
      throw ArgumentError('Description is required');
    }

    final unit = cell('unit');
    if (unit.isEmpty) {
      throw ArgumentError('Unit is required');
    }

    final coverage = _parseRequiredDouble(cell('coverageperunit'), 'CoveragePerUnit');
    final unitPrice = _parseRequiredDouble(cell('unitprice'), 'UnitPrice');
    final wasteRaw = cell('wastepercent');
    final wastePercent = wasteRaw.isEmpty
        ? defaultMaterialWastePercent
        : _parseRequiredDouble(wasteRaw, 'WastePercent');

    return MaterialPriceEntry(
      id: '${idPrefix}_$lineNumber',
      category: materialCategoryFromCsv(cell('category')),
      description: description,
      unit: unit,
      coveragePerUnit: coverage,
      wastePercent: wastePercent,
      unitPrice: unitPrice,
      notes: cell('notes'),
    );
  }

  static double _parseRequiredDouble(String raw, String label) {
    final value = double.tryParse(raw.replaceAll(',', ''));
    if (value == null) {
      throw ArgumentError('$label must be a number');
    }
    return value;
  }
}

class MaterialCsvParseResult {
  final List<MaterialPriceEntry> entries;
  final List<String> errors;

  const MaterialCsvParseResult({
    this.entries = const [],
    this.errors = const [],
  });
}