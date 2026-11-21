import 'package:flutter/material.dart';

enum PaymentMethod {
  cash('cash', 'Tunai', Icons.payments_outlined),
  qris('qris', 'QRIS', Icons.qr_code_2),
  card('card', 'Kartu', Icons.credit_card),
  transfer('transfer', 'Transfer', Icons.account_balance_outlined);

  const PaymentMethod(this.code, this.label, this.icon);
  final String code;
  final String label;
  final IconData icon;

  static PaymentMethod fromCode(String? c) =>
      values.firstWhere((m) => m.code == c, orElse: () => PaymentMethod.cash);
}

/// Tombol cepat nominal tunai: uang pas lalu pembulatan ke atas (10rb, 50rb, 100rb).
List<int> cashSuggestions(num total) {
  final exact = total.ceil();
  final out = <int>[exact];
  for (final d in const [10000, 50000, 100000]) {
    final v = ((exact + d - 1) ~/ d) * d;
    if (!out.contains(v)) out.add(v);
  }
  return out;
}
