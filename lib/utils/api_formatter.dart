// lib/utils/api_formatter.dart
class ApiFormatter {
  static String formatDateForApi(DateTime date) {
    return date.toUtc().toIso8601String();
  }

  static String formatDateForDisplay(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}