/// Format struk jadi teks monospace (32 kolom untuk 58 mm, 48 untuk 80 mm).
/// Dipakai untuk tampilan layar dan bisa langsung dikirim ke printer thermal nanti.
String formatReceipt(Map<String, dynamic> d) {
  final width = (d['paper'] as num?) == 58 ? 32 : 48;
  final out = <String>[];

  String money(dynamic v) {
    final n = num.parse('$v').round();
    final s = n.abs().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
    return n < 0 ? '-$s' : s;
  }

  String rate(dynamic v) {
    final r = num.parse('$v');
    return r % 1 == 0 ? '${r.toInt()}' : '$r'.replaceAll('.', ',');
  }

  String center(String t) {
    final x = t.length >= width ? t : t.padLeft((width + t.length) ~/ 2).padRight(width);
    return x.trimRight();
  }

  String lr(String l, String r) {
    final room = width - r.length - 1;
    final left = l.length > room ? l.substring(0, room < 0 ? 0 : room) : l;
    return left.padRight(width - r.length) + r;
  }

  void wrap(String t, {bool centered = false}) {
    var rest = t.trim();
    while (rest.isNotEmpty) {
      final cut = rest.length <= width ? rest : rest.substring(0, width);
      out.add(centered ? center(cut) : cut);
      rest = rest.substring(cut.length).trimLeft();
    }
  }

  final dash = '-' * width;
  final isReturn = d['kind'] == 'return';

  wrap('${d['business'] ?? ''}', centered: true);
  if (d['branch'] != null) wrap('${d['branch']}', centered: true);
  if (d['address'] != null) wrap('${d['address']}', centered: true);
  if (d['phone'] != null) wrap('${d['phone']}', centered: true);
  out.add(dash);
  out.add(lr(isReturn ? 'Retur' : 'No', '${d['number']}'));
  if (isReturn && d['order_number'] != null) out.add(lr('Order', '${d['order_number']}'));
  out.add(lr('Tanggal', '${d['date']}'));
  if (d['cashier'] != null) out.add(lr('Kasir', '${d['cashier']}'));
  if (d['table'] != null) out.add(lr('Meja', '${d['table']}'));
  if (d['order_type'] != null) out.add(lr('Tipe', '${d['order_type']}'));
  out.add(dash);

  for (final l in (d['lines'] as List? ?? const [])) {
    wrap('${l['name']}');
    out.add(lr('  ${l['qty']} x ${money(l['unit_price'])}', money(l['line_total'])));
  }
  out.add(dash);

  out.add(lr('Subtotal', money(d['subtotal'])));
  if (!isReturn && d['tax'] != null) out.add(lr('Pajak (${rate(d['tax_rate'])}%)', money(d['tax'])));
  if (!isReturn && d['service'] != null) out.add(lr('Service (${rate(d['service_rate'])}%)', money(d['service'])));
  if (isReturn) {
    out.add(lr('Pajak', money(d['tax'])));
    out.add(lr('Service', money(d['service'])));
  }
  out.add(lr('TOTAL', money(d['total'])));
  out.add(dash);

  if (isReturn) {
    out.add(lr('Dana kembali via', '${d['refund_method']}'));
    out.add(lr('Barang', '${d['mode']}'));
    wrap('Alasan: ${d['reason']}');
  } else {
    out.add(lr('Bayar (${d['payment_method']})', money(d['amount_paid'])));
    if (d['payment_method'] == 'Tunai') out.add(lr('Kembali', money(d['change'])));
    final refunded = num.tryParse('${d['refunded_total'] ?? 0}') ?? 0;
    if (refunded > 0) {
      out.add(dash);
      for (final r in (d['returns'] as List? ?? const [])) {
        out.add(lr('Retur ${r['number']}', '-${money(r['total'])}'));
      }
      out.add(lr('Total bersih', money(d['net_total'])));
    }
  }
  out.add(dash);
  wrap('${d['footer'] ?? ''}', centered: true);
  return out.join('\n');
}
