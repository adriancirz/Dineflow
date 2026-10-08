import 'package:intl/intl.dart';

/// Formats a numerical amount into Philippine Peso format (e.g. ₱1,234.50).
String formatPeso(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );
  return formatter.format(amount);
}
