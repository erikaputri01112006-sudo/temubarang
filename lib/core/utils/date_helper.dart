/// Utilitas format tanggal Bahasa Indonesia tanpa ketergantungan locale eksternal.
class DateHelper {
  DateHelper._();

  static const List<String> _months = [
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

  static const List<String> _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static String formatFullDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day} ${_months[local.month - 1]} ${local.year}';
  }

  static String formatShortDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day} ${_shortMonths[local.month - 1]} ${local.year}';
  }

  static String formatRelative(DateTime date) {
    final local = date.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return formatShortDate(local);
  }
}
