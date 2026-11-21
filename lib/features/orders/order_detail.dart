import 'order_models.dart';

class OrderItemDto {
  OrderItemDto({
    required this.orderItemId,
    required this.type,
    required this.itemId,
    required this.name,
    required this.unitPrice,
    required this.qty,
    required this.lineTotal,
    required this.returnedQty,
  });

  final int orderItemId; // dipakai untuk retur
  final String type;
  final int itemId; // id menu/paket di katalog
  final String name;
  final num unitPrice, qty, lineTotal, returnedQty;

  /// Sisa yang masih bisa diretur.
  num get remaining => qty - returnedQty;

  factory OrderItemDto.fromJson(Map<String, dynamic> j) => OrderItemDto(
        orderItemId: j['order_item_id'] as int,
        type: '${j['type']}',
        itemId: j['item_id'] as int,
        name: '${j['name']}',
        unitPrice: num.parse('${j['unit_price']}'),
        qty: num.parse('${j['qty']}'),
        lineTotal: num.parse('${j['line_total']}'),
        returnedQty: num.parse('${j['returned_qty'] ?? 0}'),
      );
}

class ReturnSummary {
  ReturnSummary({required this.uuid, required this.number, required this.mode, required this.refundMethod, required this.reason, required this.totalRefund});
  final String uuid, number, mode, refundMethod, reason;
  final num totalRefund;

  factory ReturnSummary.fromJson(Map<String, dynamic> j) => ReturnSummary(
        uuid: '${j['uuid']}',
        number: '${j['number']}',
        mode: '${j['mode']}',
        refundMethod: '${j['refund_method']}',
        reason: '${j['reason']}',
        totalRefund: num.parse('${j['total_refund']}'),
      );
}

/// Order lengkap (GET /orders, /orders/{uuid}, hasil retur).
class OrderDetail {
  OrderDetail({
    required this.order,
    required this.items,
    required this.returns,
    required this.refundedTotal,
    this.orderType,
    this.tableLabel,
    this.createdAt,
  });

  final OrderDto order;
  final List<OrderItemDto> items;
  final List<ReturnSummary> returns;
  final num refundedTotal;
  final String? orderType, tableLabel;
  final DateTime? createdAt;

  String get uuid => order.uuid;
  bool get isOpen => order.status == 'open';
  bool get isPaid => order.status == 'paid';
  bool get isVoid => order.status == 'void';
  bool get canStillReturn => isPaid && items.any((i) => i.remaining >= 1);

  factory OrderDetail.fromJson(Map<String, dynamic> j) => OrderDetail(
        order: OrderDto.fromJson(j),
        items: ((j['items'] as List?) ?? const []).map((e) => OrderItemDto.fromJson(e as Map<String, dynamic>)).toList(),
        returns: ((j['returns'] as List?) ?? const []).map((e) => ReturnSummary.fromJson(e as Map<String, dynamic>)).toList(),
        refundedTotal: num.parse('${j['refunded_total'] ?? 0}'),
        orderType: j['order_type'] as String?,
        tableLabel: j['table_label'] as String?,
        createdAt: j['created_at'] == null ? null : DateTime.parse(j['created_at'] as String).toLocal(),
      );
}
