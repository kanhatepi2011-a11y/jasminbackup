import 'package:intl/intl.dart';

class Formatters {
  const Formatters._();

  static final NumberFormat usd = NumberFormat.currency(symbol: r'$');
  static final NumberFormat khr = NumberFormat.currency(symbol: '៛', decimalDigits: 0);
  static final NumberFormat compact = NumberFormat.compact();
  static final DateFormat dateTime = DateFormat('dd MMM yyyy, HH:mm');
  static final DateFormat shortTime = DateFormat('HH:mm');

  static String moneyUsd(num value) => usd.format(value);
  static String moneyKhr(num value) => khr.format(value);
  static String number(num value) => compact.format(value);

  static String dateTimeOrDash(DateTime? value) {
    if (value == null) return '—';
    return dateTime.format(value);
  }

  static String statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
      case 'COMPLETED':
        return 'Completed';
      case 'PAID':
        return 'Paid';
      case 'PROCESSING':
        return 'Processing';
      case 'FAILED':
        return 'Failed';
      case 'CANCELLED':
        return 'Cancelled';
      case 'REFUNDED':
        return 'Refunded';
      case 'PENDING':
      default:
        return 'Pending';
    }
  }
}
