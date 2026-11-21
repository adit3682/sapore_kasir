import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/format.dart';
import '../../core/theme/sapore_theme.dart';
import 'order_models.dart';
import 'payment_method.dart';

/// Rincian total + pilihan metode + input tunai/kembalian untuk order yang sudah ada di server.
class PaymentForm extends StatefulWidget {
  const PaymentForm({super.key, required this.order, required this.busy, required this.onConfirm, this.error});
  final OrderDto order;
  final bool busy;
  final String? error;
  final void Function(PaymentMethod method, int received) onConfirm;

  @override
  State<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  PaymentMethod _method = PaymentMethod.cash;
  final _cash = TextEditingController();

  int get _received => int.tryParse(_cash.text) ?? 0;

  @override
  void dispose() {
    _cash.dispose();
    super.dispose();
  }

  Widget _row(String l, String v, {bool big = false, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l, style: TextStyle(fontSize: big ? 18 : 14)),
          Text(v, style: TextStyle(fontSize: big ? 20 : 14, fontWeight: big ? FontWeight.w800 : FontWeight.w500, color: color)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final canConfirm = !widget.busy && (_method != PaymentMethod.cash || _received >= o.total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _row('Subtotal', rupiah.format(o.subtotal)),
        _row('Pajak (${rateLabel(o.taxRate)}%)', rupiah.format(o.taxAmount)),
        _row('Service (${rateLabel(o.serviceRate)}%)', rupiah.format(o.serviceAmount)),
        const Divider(height: 24),
        _row('Total', rupiah.format(o.total), big: true),
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
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            for (final v in cashSuggestions(o.total))
              ActionChip(
                label: Text(v == o.total.ceil() ? 'Uang pas' : rupiah.format(v)),
                onPressed: () => setState(() => _cash.text = '$v'),
              ),
          ]),
          const SizedBox(height: 12),
          if (_cash.text.isNotEmpty)
            _received >= o.total
                ? _row('Kembalian', rupiah.format(_received - o.total), big: true, color: SaporeColors.sage)
                : _row('Kurang', rupiah.format(o.total - _received), color: Theme.of(context).colorScheme.error),
        ],
        if (widget.error != null) ...[
          const SizedBox(height: 12),
          Text(widget.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: canConfirm ? () => widget.onConfirm(_method, _received) : null,
          child: widget.busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Konfirmasi Pembayaran'),
        ),
      ],
    );
  }
}
