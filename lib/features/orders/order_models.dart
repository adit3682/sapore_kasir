/// Respons order dari API (angka dikirim server sebagai string desimal).
class OrderDto {
  OrderDto({
    required this.uuid,
    required this.number,
    required this.status,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.serviceRate,
    required this.serviceAmount,
    required this.total,
    this.paymentMethod,
    this.amountPaid,
    this.changeAmount,
  });

  final String uuid;
  final String number;
  final String status;
  final num subtotal, taxRate, taxAmount, serviceRate, serviceAmount, total;
  final String? paymentMethod;
  final num? amountPaid, changeAmount;

  static num _n(dynamic v) => num.parse('$v');
  static num? _nn(dynamic v) => v == null ? null : num.parse('$v');

  factory OrderDto.fromJson(Map<String, dynamic> j) => OrderDto(
        uuid: j['uuid'] as String,
        number: '${j['number']}',
        status: '${j['status']}',
        subtotal: _n(j['subtotal']),
        taxRate: _n(j['tax_rate']),
        taxAmount: _n(j['tax_amount']),
        serviceRate: _n(j['service_rate']),
        serviceAmount: _n(j['service_amount']),
        total: _n(j['total']),
        paymentMethod: j['payment_method'] as String?,
        amountPaid: _nn(j['amount_paid']),
        changeAmount: _nn(j['change_amount']),
      );
}

/// Isi pesanan dari keranjang. `uuid` dibuat klien (kunci idempotensi).
class OrderDraft {
  OrderDraft({
    required this.uuid,
    required this.orderType,
    required this.items,
    this.tableLabel = '',
    this.notes = '',
  });

  final String uuid;
  final String orderType; // dine_in | take_away
  final String tableLabel;
  final String notes;
  final List<Map<String, dynamic>> items; // {type, id, qty}

  Map<String, dynamic> toJson({Map<String, dynamic>? pay}) => {
        'uuid': uuid,
        'order_type': orderType,
        if (tableLabel.isNotEmpty) 'table_label': tableLabel,
        if (notes.isNotEmpty) 'notes': notes,
        'items': items,
        if (pay != null) 'pay': pay,
      };
}
