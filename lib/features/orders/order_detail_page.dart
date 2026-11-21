import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/network/api_exception.dart';
import '../auth/auth_controller.dart';
import 'orders_history_page.dart';
import 'orders_providers.dart';
import 'orders_repository.dart';
import 'payment_method.dart';

class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({super.key, required this.uuid});
  final String uuid;

  Future<void> _void(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Void order ini?'),
        content: const Text('Order yang belum dibayar akan dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Tidak')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Ya, void')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(ordersRepositoryProvider).voidOrder(uuid);
      ref.invalidate(orderDetailProvider(uuid));
      ref.invalidate(orderListProvider);
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(orderDetailProvider(uuid));
    final canRefund = ref.watch(authControllerProvider).user?.canRefund ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Order')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('$e'))),
        data: (o) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Expanded(child: Text(o.order.number, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
              StatusBadge(o.order.status),
            ]),
            const SizedBox(height: 12),
            for (final i in o.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${i.qty.toInt()}× ${i.name}'),
                      if (i.returnedQty > 0)
                        Text('Diretur ${i.returnedQty.toInt()}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.error)),
                    ]),
                  ),
                  Text(rupiah.format(i.lineTotal)),
                ]),
              ),
            const Divider(height: 24),
            _row('Subtotal', rupiah.format(o.order.subtotal)),
            _row('Pajak (${rateLabel(o.order.taxRate)}%)', rupiah.format(o.order.taxAmount)),
            _row('Service (${rateLabel(o.order.serviceRate)}%)', rupiah.format(o.order.serviceAmount)),
            _row('Total', rupiah.format(o.order.total), bold: true),
            if (o.isPaid) ...[
              _row('Metode', PaymentMethod.fromCode(o.order.paymentMethod).label),
              if (o.order.paymentMethod == 'cash') ...[
                _row('Diterima', rupiah.format(o.order.amountPaid ?? 0)),
                _row('Kembalian', rupiah.format(o.order.changeAmount ?? 0)),
              ],
            ],
            if (o.returns.isNotEmpty) ...[
              const Divider(height: 24),
              const Text('Retur', style: TextStyle(fontWeight: FontWeight.w800)),
              for (final r in o.returns)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${r.number} · ${rupiah.format(r.totalRefund)}'),
                  subtitle: Text(r.reason),
                  trailing: IconButton(
                    tooltip: 'Struk retur',
                    icon: const Icon(Icons.receipt_long),
                    onPressed: () => context.push('/orders/$uuid/returns/${r.uuid}/receipt'),
                  ),
                ),
              _row('Total retur', rupiah.format(o.refundedTotal), bold: true),
            ],
            const SizedBox(height: 20),
            if (o.isPaid) ...[
              OutlinedButton.icon(
                icon: const Icon(Icons.receipt_long),
                label: const Text('Lihat Struk'),
                onPressed: () => context.push('/orders/$uuid/receipt'),
              ),
              if (canRefund && o.canStillReturn) ...[
                const SizedBox(height: 8),
                FilledButton(onPressed: () => context.push('/orders/$uuid/return'), child: const Text('Retur')),
              ],
            ],
            if (o.isOpen) ...[
              FilledButton(onPressed: () => context.push('/orders/$uuid/pay'), child: const Text('Bayar')),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: () => _void(context, ref), child: const Text('Void Order')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String l, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l),
          Text(v, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
        ]),
      );
}
