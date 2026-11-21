import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/network/api_exception.dart';
import '../printing/printer_controller.dart';
import 'order_models.dart';
import 'orders_providers.dart';
import 'orders_repository.dart';
import 'payment_form.dart';
import 'payment_method.dart';

/// Melunasi order Open (mis. sisa dari antrean offline yang "Perlu tindakan").
/// Pembayaran idempoten di server, jadi mengulang setelah koneksi putus aman.
class PayOrderPage extends ConsumerStatefulWidget {
  const PayOrderPage({super.key, required this.uuid});
  final String uuid;
  @override
  ConsumerState<PayOrderPage> createState() => _PayOrderPageState();
}

class _PayOrderPageState extends ConsumerState<PayOrderPage> {
  bool _busy = false;
  String? _error;

  Future<void> _pay(PaymentMethod m, int received) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final paid = await ref
          .read(ordersRepositoryProvider)
          .pay(widget.uuid, m.code, m == PaymentMethod.cash ? received : null);
      ref.invalidate(orderDetailProvider(widget.uuid));
      ref.invalidate(orderListProvider);
      if (!mounted) return;
      await _showDone(paid);
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.network ? 'Koneksi terputus. Coba lagi; pembayaran tidak akan terproses dobel.' : e.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showDone(OrderDto paid) => showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Pembayaran berhasil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(paid.number),
              Text('Total ${rupiah.format(paid.total)}'),
              if (paid.paymentMethod == 'cash')
                Text('Kembalian ${rupiah.format(paid.changeAmount ?? 0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final err = await ref.read(printerControllerProvider.notifier).printOrderReceipt(paid.uuid);
                if (c.mounted) {
                  ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(err ?? 'Struk dikirim ke printer')));
                }
              },
              child: const Text('Cetak Struk'),
            ),
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Tutup')),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(orderDetailProvider(widget.uuid));
    return Scaffold(
      appBar: AppBar(title: const Text('Bayar Order')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('$e'))),
        data: (o) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(o.order.number, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            for (final i in o.items) Text('${i.qty.toInt()}× ${i.name}'),
            const SizedBox(height: 16),
            if (!o.isOpen)
              Text('Order ini sudah ${o.isPaid ? 'dibayar' : 'di-void'}.')
            else
              PaymentForm(order: o.order, busy: _busy, error: _error, onConfirm: _pay),
          ],
        ),
      ),
    );
  }
}
