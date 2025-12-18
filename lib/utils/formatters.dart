import 'package:intl/intl.dart';

class AppFormatters {
  static final NumberFormat gbp = NumberFormat.currency(locale: 'en_GB', symbol: '£', decimalDigits: 2);
  static final DateFormat date = DateFormat('dd MMM yyyy', 'en_GB');
  static final DateFormat month = DateFormat('MMM yyyy', 'en_GB');
  static final DateFormat monthKey = DateFormat('yyyy-MM', 'en_GB');
  static final DateFormat time = DateFormat('HH:mm', 'en_GB');

  static String moneyFromPence(int pence) => gbp.format(pence / 100.0);
}
