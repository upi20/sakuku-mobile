class DateFormatter {
  DateFormatter._();

  static const _dayNames = [
    '', // placeholder, weekday is 1-indexed (1=Monday)
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const _monthNames = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static String dayName(int weekday) => _dayNames[weekday];

  static String monthName(int month) => _monthNames[month];

  /// Formats "yyyy-MM" → "Januari 2024"
  static String formatYearMonth(String yearMonth) {
    final parts = yearMonth.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    return '${_monthNames[month]} $year';
  }

  /// Formats a date string "yyyy-MM-dd" → "15 Januari 2024"
  static String formatDate(String date) {
    final parts = date.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    return '$day ${_monthNames[month]} $year';
  }

  /// Formats a time string "HH:mm:ss" or "HH:mm" → "21:30"
  static String formatTime(String time) {
    final parts = time.split(':');
    return '${parts[0]}:${parts[1]}';
  }

  /// Returns current date as "yyyy-MM-dd"
  static String todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Returns current "yyyy-MM" string
  static String currentYearMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}
