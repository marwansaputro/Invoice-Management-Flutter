import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final NumberFormat _currency = NumberFormat.decimalPattern('id_ID');
  static final DateFormat _date = DateFormat('dd MMM yyyy');
  static final DateFormat _dateInput = DateFormat('dd/MM/yyyy');

  static String money(double value, {String symbol = 'Rp'}) {
    final rounded = value.round();
    return '$symbol${_currency.format(rounded)}';
  }

  /// Short form for tight spaces like chart labels, e.g. Rp1.8Jt, Rp450Rb.
  static String moneyCompact(double value, {String symbol = 'Rp'}) {
    final v = value.abs();
    String trimZero(double n) =>
        n % 1 == 0 ? n.toStringAsFixed(0) : n.toStringAsFixed(1);
    if (v >= 1000000000) return '$symbol${trimZero(value / 1000000000)}M';
    if (v >= 1000000) return '$symbol${trimZero(value / 1000000)}Jt';
    if (v >= 1000) return '$symbol${trimZero(value / 1000)}Rb';
    return '$symbol${value.toStringAsFixed(0)}';
  }

  static String date(DateTime date) => _date.format(date);
  static String dateInput(DateTime date) => _dateInput.format(date);
}
