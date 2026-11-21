import 'package:intl/intl.dart';

final rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

/// "10.00" -> "10", "5.50" -> "5,5"
String rateLabel(num r) => r % 1 == 0 ? '${r.toInt()}' : r.toString().replaceAll('.', ',');
