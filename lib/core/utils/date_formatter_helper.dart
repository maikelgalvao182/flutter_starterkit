
/// Helper class para formatação de datas
class DateFormatterHelper {
  /// Formata a data de nascimento conforme o locale
  static String formatBirthday(DateTime date, String locale) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    // Formato americano
    if (locale.startsWith('en')) {
      return '$month-$day-$year';
    }

    // Formato brasileiro/português/espanhol
    return '$day-$month-$year';
  }

  /// Converte string formatada para DateTime
  static DateTime? parseFormattedDate(String formatted, String locale) {
    try {
      final parts = formatted.split('-');
      if (parts.length != 3) return null;

      int day, month, year;

      if (locale.startsWith('en')) {
        // MM-DD-YYYY
        month = int.parse(parts[0]);
        day = int.parse(parts[1]);
        year = int.parse(parts[2]);
      } else {
        // DD-MM-YYYY
        day = int.parse(parts[0]);
        month = int.parse(parts[1]);
        year = int.parse(parts[2]);
      }

      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }
}
