import 'package:intl/intl.dart';

final _savedDateFormat = DateFormat('dd MMM yyyy');
final _savedDateTimeFormat = DateFormat('dd MMMM yyyy, HH:mm');

String formatSavedDate(DateTime date) => _savedDateFormat.format(date);

String formatSavedDateTime(DateTime date) => _savedDateTimeFormat.format(date);

bool savedResultWasUpdated(DateTime createdAt, DateTime updatedAt) {
  return updatedAt.difference(createdAt).inMinutes.abs() > 1;
}

String? formatSavedUpdatedLine(DateTime createdAt, DateTime updatedAt) {
  if (!savedResultWasUpdated(createdAt, updatedAt)) return null;
  return 'Updated ${formatSavedDate(updatedAt)}';
}