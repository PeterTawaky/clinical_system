class HelperFunctions {
  static String? currentUserName;

  static String normalizeNumericInput(String value) {
    const arabicIndicDigits = {
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
      '۰': '0',
      '۱': '1',
      '۲': '2',
      '۳': '3',
      '۴': '4',
      '۵': '5',
      '۶': '6',
      '۷': '7',
      '۸': '8',
      '۹': '9',
      '٫': '.',
      ',': '.',
    };

    final normalized = value
        .split('')
        .map((char) => arabicIndicDigits[char] ?? char)
        .join()
        .replaceAll(' ', '');

    return normalized;
  }

  static double parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(normalizeNumericInput(value)) ?? 0.0;
    }
    return 0.0;
  }

  static int? parseToInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Converts a 24-hour time string (e.g. "14:30:00" or "09:00")
  /// to Arabic 12-hour format with ص/م (e.g. "2:30 م" / "9:00 ص").
  static String formatTimeArabic(String time) {
    final parts = time.split(':');
    if (parts.isEmpty) return time;
    final hour24 = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
    final isAm = hour24 < 12;
    final hour12 = hour24 == 0
        ? 12
        : hour24 > 12
            ? hour24 - 12
            : hour24;
    final period = isAm ? 'ص' : 'م';
    return '$hour12:$minute $period';
  }

  /// Converts a [DateTime] to Arabic 12-hour format (e.g. "9:05 ص").
  static String formatDateTimeArabic(DateTime dt) {
    final isAm = dt.hour < 12;
    final hour12 = dt.hour == 0
        ? 12
        : dt.hour > 12
            ? dt.hour - 12
            : dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = isAm ? 'ص' : 'م';
    return '$hour12:$minute $period';
  }
}
