import 'package:flutter_test/flutter_test.dart';
import 'package:sapore_kasir/features/orders/order_detail.dart';
import 'package:sapore_kasir/features/orders/receipt_text.dart';

Map<String, dynamic> orderJson() => {
      'uuid': 'u1', 'number': 'ORD-1', 'status': 'paid', 'order_type': 'dine_in', 'table_label': '07',
      'items': [
        {'order_item_id': 11, 'returned_qty': '1.00', 'type': 'menu', 'item_id': 1, 'name': 'Nasi Goreng Special',
         'unit_price': '40000.00', 'qty': '3.00', 'line_total': '120000.00'},
      ],
      'subtotal': '120000.00', 'tax_rate': '10.00', 'tax_amount': '12000.00', 'service_rate': '5.00',
      'service_amount': '6000.00', 'total': '138000.00', 'payment_method': 'cash', 'amount_paid': '150000.00',
      'change_amount': '12000.00', 'refunded_total': '46000.00',
      'returns': [
        {'uuid': 'r', 'number': 'RET-1', 'mode': 'waste', 'refund_method': 'cash', 'reason': 'Salah pesan',
         'total_refund': '46000.00', 'items': []},
      ],
      'created_at': '2026-11-20T10:15:00+07:00',
    };

Map<String, dynamic> receiptJson(int paper) => {
      'kind': 'order', 'business': 'SAPORÉ', 'branch': 'Cabang Sudirman', 'address': 'Jl. Jenderal Sudirman No. 1 Bandung',
      'phone': null, 'footer': 'Terima kasih atas kunjungan Anda', 'paper': paper,
      'number': 'ORD-1', 'date': '20/11/2026 10:15', 'cashier': 'Rina', 'table': '07', 'order_type': 'Dine In',
      'lines': [
        {'name': 'Nasi Goreng Special Dengan Telur Mata Sapi Ekstra Pedas', 'qty': '3', 'unit_price': '40000.00', 'line_total': '120000.00'},
      ],
      'subtotal': '120000.00', 'tax_rate': '10', 'tax': '12000.00', 'service_rate': '5', 'service': '6000.00',
      'total': '138000.00', 'payment_method': 'Tunai', 'amount_paid': '150000.00', 'change': '12000.00',
      'returns': [{'number': 'RET-1', 'total': '46000.00', 'date': '20/11/2026 11:00'}],
      'refunded_total': '46000.00', 'net_total': '92000.00',
    };

void main() {
  test('OrderDetail: sisa retur dan status', () {
    final o = OrderDetail.fromJson(orderJson());
    expect(o.items.single.remaining, 2);
    expect(o.isPaid, isTrue);
    expect(o.canStillReturn, isTrue);
    expect(o.returns.single.number, 'RET-1');
    expect(o.returns.single.uuid, 'r');
    expect(o.refundedTotal, 46000);
  });

  test('canStillReturn false bila semua item sudah diretur', () {
    final j = orderJson();
    (j['items'] as List).first['returned_qty'] = '3.00';
    expect(OrderDetail.fromJson(j).canStillReturn, isFalse);
  });

  test('formatReceipt: tidak ada baris melebihi lebar kertas', () {
    for (final paper in [58, 80]) {
      final width = paper == 58 ? 32 : 48;
      final text = formatReceipt(receiptJson(paper));
      for (final line in text.split('\n')) {
        expect(line.length <= width, isTrue, reason: '"$line" ($paper mm)');
      }
      expect(text, contains('138.000'));
      expect(text, contains('Total bersih'));
    }
  });
}
