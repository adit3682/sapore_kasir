import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/sapore_theme.dart';
import 'order_detail.dart';
import 'orders_providers.dart';
import 'orders_repository.dart';
import 'payment_method.dart';

/// Retur (Owner/Manager). uuid retur dipertahankan sampai sukses, jadi
/// mengulang kirim setelah jaringan putus tidak membuat retur ganda.
class ReturnPage extends ConsumerStatefulWidget {
  const ReturnPage({super.key, required this.uuid});
  final String uuid;
  @override
  ConsumerState<ReturnPage> createState() => _ReturnPageState();
}

class _ReturnPageState extends ConsumerState<ReturnPage> {
  final _returnUuid = const Uuid().v4();
  final _reason = TextEditingController();
  final Map<int, int> _qty = {};
  String _mode = 'waste';
  PaymentMethod? _method;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool get _valid => _qty.values.any((q) => q > 0) && _reason.text.trim().length >= 3;

  Future<void> _submit(OrderDetail o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Proses retur?'),
        content: const Text('Retur tidak bisa dibatalkan. Nominal refund dihitung server.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Proses')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(ordersRepositoryProvider).refund(o.uuid, {
        'uuid': _returnUuid,
        'items': [
          for (final e in _qty.entries)
            if (e.value > 0) {'order_item_id': e.key, 'qty': e.value},
        ],
        'mode': _mode,
        'refund_method': (_method ?? PaymentMethod.fromCode(o.order.paymentMethod)).code,
        'reason': _reason.text.trim(),
      });
      ref.invalidate(orderDetailProvider(o.uuid));
      ref.invalidate(orderListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Retur berhasil diproses')));
      context.pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.network ? 'Koneksi terputus. Coba lagi (tidak akan terproses dobel).' : e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(orderDetailProvider(widget.uuid));
    return Scaffold(
      appBar: AppBar(title: const Text('Retur Order')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (o) {
          final method = _method ?? PaymentMethod.fromCode(o.order.paymentMethod);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(o.order.number, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final i in o.items.where((i) => i.remaining >= 1))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(i.name),
                  subtitle: Text('Bisa diretur: ${i.remaining.floor()}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: (_qty[i.orderItemId] ?? 0) > 0 ? () => setState(() => _qty[i.orderItemId] = _qty[i.orderItemId]! - 1) : null,
                    ),
                    Text('${_qty[i.orderItemId] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: (_qty[i.orderItemId] ?? 0) < i.remaining.floor()
                          ? () => setState(() => _qty[i.orderItemId] = (_qty[i.orderItemId] ?? 0) + 1)
                          : null,
                    ),
                  ]),
                ),
              const Divider(height: 24),
              const Text('Barang yang diretur', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'waste', label: Text('Dibuang')),
                  ButtonSegment(value: 'restock', label: Text('Kembali ke stok')),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
              const SizedBox(height: 16),
              const Text('Dana dikembalikan via', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final m in PaymentMethod.values)
                  ChoiceChip(
                    label: Text(m.label),
                    selected: method == m,
                    selectedColor: SaporeColors.navy,
                    labelStyle: TextStyle(color: method == m ? Colors.white : SaporeColors.textDark),
                    onSelected: (_) => setState(() => _method = m),
                  ),
              ]),
              const SizedBox(height: 16),
              TextField(
                controller: _reason,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Alasan retur (min. 3 karakter)'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _valid && !_busy ? () => _submit(o) : null,
                child: _busy
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Proses Retur'),
              ),
            ],
          );
        },
      ),
    );
  }
}
