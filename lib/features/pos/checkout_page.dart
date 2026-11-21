import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/format.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/sapore_theme.dart';
import '../orders/order_models.dart';
import '../orders/orders_repository.dart';
import '../orders/payment_method.dart';
import '../printing/printer_controller.dart';
import '../orders/pending_queue.dart';
import 'cart.dart';

enum _Stage { details, pay, done }

/// Alur: detail pesanan -> (server hitung total) -> pembayaran -> selesai.
/// Bila jaringan putus, pesanan disimpan ke antrean offline dan dikirim otomatis.
class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});
  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  String _uuid = const Uuid().v4();
  _Stage _stage = _Stage.details;
  String _orderType = 'dine_in';
  final _table = TextEditingController();
  final _notes = TextEditingController();
  final _cash = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;
  OrderDto? _order; // null di tahap pay = mode offline
  OrderDto? _paid;
  bool _queued = false;
  bool _offlineOffer = false;
  bool _busy = false;
  String? _error;

  int get _received => int.tryParse(_cash.text) ?? 0;

  @override
  void dispose() {
    _table.dispose();
    _notes.dispose();
    _cash.dispose();
    super.dispose();
  }

  OrderDraft _draft() => OrderDraft(
        uuid: _uuid,
        orderType: _orderType,
        tableLabel: _table.text.trim(),
        notes: _notes.text.trim(),
        items: [
          for (final l in ref.read(cartProvider).lines) {'type': l.item.type, 'id': l.item.id, 'qty': l.qty},
        ],
      );

  Map<String, dynamic> _payMap() => {
        'method': _method.code,
        if (_method == PaymentMethod.cash) 'amount_paid': _received,
      };

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
      _offlineOffer = false;
    });
    try {
      final order = await ref.read(ordersRepositoryProvider).create(_draft());
      if (mounted) setState(() { _order = order; _stage = _Stage.pay; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _offlineOffer = e.network; });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final order = _order;
    try {
      if (order == null) {
        await _enqueue();
        return;
      }
      final paid = await ref
          .read(ordersRepositoryProvider)
          .pay(order.uuid, _method.code, _method == PaymentMethod.cash ? _received : null);
      ref.read(cartProvider.notifier).clear();
      if (mounted) setState(() { _paid = paid; _stage = _Stage.done; });
    } on ApiException catch (e) {
      if (e.network) {
        await _enqueue(); // order sudah ada di server; kirim ulang idempoten lewat antrean
      } else if (mounted) {
        setState(() => _error = e.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enqueue() async {
    final payload = _draft().toJson(pay: _payMap());
    await ref.read(pendingQueueProvider.notifier).enqueue(payload);
    ref.read(cartProvider.notifier).clear();
    if (mounted) setState(() { _queued = true; _stage = _Stage.done; });
  }

  Future<void> _cancelOrder() async {
    final order = _order;
    if (order != null) {
      try {
        await ref.read(ordersRepositoryProvider).voidOrder(order.uuid);
      } on ApiException catch (_) {/* gagal void: order Open tersisa, bisa di-void dari panel */}
    }
    if (!mounted) return;
    setState(() {
      _order = null;
      _error = null;
      _offlineOffer = false;
      _cash.clear();
      _stage = _Stage.details;
      _uuid = const Uuid().v4(); // uuid lama sudah terpakai
    });
  }

  Future<void> _confirmBack() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Batalkan pembayaran?'),
        content: Text(_order == null ? 'Kembali ke detail pesanan.' : 'Order yang sudah dibuat akan di-void.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Tidak')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Ya, batalkan')),
        ],
      ),
    );
    if (ok == true) await _cancelOrder();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _stage != _Stage.pay,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmBack();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(switch (_stage) {
          _Stage.details => 'Detail Pesanan',
          _Stage.pay => 'Pembayaran',
          _Stage.done => 'Selesai',
        })),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: switch (_stage) {
            _Stage.details => _details(),
            _Stage.pay => _payment(),
            _Stage.done => _done(),
          },
        ),
      ),
    );
  }

  List<Widget> _errorBox() => [
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ];

  List<Widget> _details() {
    final cart = ref.watch(cartProvider);
    return [
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'dine_in', label: Text('Dine In'), icon: Icon(Icons.restaurant)),
          ButtonSegment(value: 'take_away', label: Text('Take Away'), icon: Icon(Icons.takeout_dining)),
        ],
        selected: {_orderType},
        onSelectionChanged: (s) => setState(() => _orderType = s.first),
      ),
      const SizedBox(height: 12),
      TextField(controller: _table, decoration: const InputDecoration(labelText: 'Nomor meja / nama (opsional)')),
      const SizedBox(height: 12),
      TextField(controller: _notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Catatan (opsional)')),
      const SizedBox(height: 16),
      for (final l in cart.lines)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(children: [
            Expanded(child: Text('${l.qty}× ${l.item.name}')),
            Text(rupiah.format(l.total)),
          ]),
        ),
      const Divider(height: 24),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Subtotal', style: TextStyle(fontWeight: FontWeight.w700)),
        Text(rupiah.format(cart.subtotal), style: const TextStyle(fontWeight: FontWeight.w700)),
      ]),
      ..._errorBox(),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: _busy || cart.isEmpty ? null : _create,
        child: _busy
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Lanjut ke Pembayaran'),
      ),
      if (_offlineOffer) ...[
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.cloud_off),
          label: const Text('Bayar Offline (simpan ke antrean)'),
          onPressed: () => setState(() { _error = null; _stage = _Stage.pay; }),
        ),
      ],
    ];
  }

  List<Widget> _payment() {
    final order = _order;
    final offline = order == null;
    final canConfirm = !_busy &&
        (_method != PaymentMethod.cash || (offline ? _received > 0 : _received >= order.total));

    return [
      if (offline)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: SaporeColors.terracotta.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Mode offline: total (pajak & service) baru dihitung server saat pesanan terkirim, '
            'jadi kembalian tidak bisa dihitung di app. Hitung manual dari total pesanan.',
            style: TextStyle(fontSize: 13),
          ),
        )
      else ...[
        _row('Subtotal', rupiah.format(order.subtotal)),
        _row('Pajak (${rateLabel(order.taxRate)}%)', rupiah.format(order.taxAmount)),
        _row('Service (${rateLabel(order.serviceRate)}%)', rupiah.format(order.serviceAmount)),
        const Divider(height: 24),
        _row('Total', rupiah.format(order.total), big: true),
      ],
      const SizedBox(height: 20),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final m in PaymentMethod.values)
          ChoiceChip(
            avatar: Icon(m.icon, size: 18, color: _method == m ? Colors.white : SaporeColors.navy),
            label: Text(m.label),
            selected: _method == m,
            selectedColor: SaporeColors.navy,
            labelStyle: TextStyle(color: _method == m ? Colors.white : SaporeColors.textDark),
            onSelected: (_) => setState(() => _method = m),
          ),
      ]),
      if (_method == PaymentMethod.cash) ...[
        const SizedBox(height: 16),
        TextField(
          controller: _cash,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'Uang diterima', prefixText: 'Rp '),
        ),
        if (!offline) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            for (final v in cashSuggestions(order.total))
              ActionChip(
                label: Text(v == order.total.ceil() ? 'Uang pas' : rupiah.format(v)),
                onPressed: () => setState(() => _cash.text = '$v'),
              ),
          ]),
          const SizedBox(height: 12),
          if (_cash.text.isNotEmpty)
            _received >= order.total
                ? _row('Kembalian', rupiah.format(_received - order.total), big: true, color: SaporeColors.sage)
                : _row('Kurang', rupiah.format(order.total - _received), color: Theme.of(context).colorScheme.error),
        ],
      ],
      ..._errorBox(),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: canConfirm ? _confirm : null,
        child: _busy
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(offline ? 'Simpan ke Antrean' : 'Konfirmasi Pembayaran'),
      ),
      const SizedBox(height: 8),
      OutlinedButton(onPressed: _busy ? null : _confirmBack, child: const Text('Batalkan')),
    ];
  }

  List<Widget> _done() {
    final paid = _paid;
    return [
      const SizedBox(height: 24),
      Icon(_queued ? Icons.cloud_upload_outlined : Icons.check_circle, size: 72,
          color: _queued ? SaporeColors.terracotta : SaporeColors.sage),
      const SizedBox(height: 12),
      Text(_queued ? 'Tersimpan di antrean offline' : 'Pembayaran berhasil',
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 16),
      if (_queued)
        const Text('Pesanan akan dikirim otomatis saat koneksi kembali. Pantau di ikon antrean pada layar kasir.',
            textAlign: TextAlign.center)
      else if (paid != null) ...[
        _row('No. Order', paid.number),
        _row('Total', rupiah.format(paid.total), big: true),
        _row('Metode', PaymentMethod.fromCode(paid.paymentMethod).label),
        if (paid.paymentMethod == 'cash') ...[
          _row('Diterima', rupiah.format(paid.amountPaid ?? 0)),
          _row('Kembalian', rupiah.format(paid.changeAmount ?? 0), big: true, color: SaporeColors.sage),
        ],
      ],
      const SizedBox(height: 24),
      if (!_queued && paid != null) ...[
        FilledButton.icon(
          icon: const Icon(Icons.print),
          label: const Text('Cetak Struk'),
          onPressed: () async {
            if (!ref.read(printerControllerProvider).isSet) {
              context.push('/printer');
              return;
            }
            final err = await ref.read(printerControllerProvider.notifier).printOrderReceipt(paid.uuid);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Struk dikirim ke printer')));
            }
          },
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.receipt_long),
          label: const Text('Lihat Struk'),
          onPressed: () => context.push('/orders/${paid.uuid}/receipt'),
        ),
        const SizedBox(height: 8),
      ],
      FilledButton(onPressed: () => context.pop(), child: const Text('Pesanan Baru')),
    ];
  }

  Widget _row(String l, String v, {bool big = false, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l, style: TextStyle(fontSize: big ? 18 : 14)),
          Text(v, style: TextStyle(fontSize: big ? 20 : 14, fontWeight: big ? FontWeight.w800 : FontWeight.w500, color: color)),
        ]),
      );
}
