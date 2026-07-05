/// Display/format helpers for in-progress decimal text fields.
String decimalInputDisplayText(double value) {
  if (value == 0) return '';
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toString();
}

/// Parses user text without forcing incomplete decimals (e.g. "12.") into the model.
void applyDecimalInputChange(String text, void Function(double value) onChanged) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    onChanged(0);
    return;
  }
  if (trimmed == '.' || trimmed.endsWith('.')) {
    return;
  }
  final parsed = double.tryParse(trimmed);
  if (parsed != null) {
    onChanged(parsed);
  }
}

String intInputDisplayText(int value) => value == 0 ? '' : value.toString();

void applyIntInputChange(String text, void Function(int value) onChanged) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    onChanged(0);
    return;
  }
  final parsed = int.tryParse(trimmed);
  if (parsed != null) {
    onChanged(parsed);
  }
}