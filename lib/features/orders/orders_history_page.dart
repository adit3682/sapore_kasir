import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../core/theme/sapore_theme.dart';
import 'order_detail.dart';
import 'orders_providers.dart';

const _statusLabels = {null: 'Semua', 'open': 'Open', 'paid': 'Lunas', 'void': 'Void'};

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'paid' => SaporeColors.sage,
      'open' => SaporeColors.terracotta,
      _ => SaporeColors.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(_statusLabels[status] ?? status, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class OrdersHistoryPage extends ConsumerWidget {
  const OrdersHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(historyStatusProvider);
    final date = ref.watch(historyDateProvider);
    final list = ref.watch(orderListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Order'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.calendar_today, size: 16, color: Colors.white),
            label: Text(DateFormat('d MMM yyyy', 'id_ID').format(date), style: const TextStyle(color: Colors.white)),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
              );
              if (picked != null) ref.read(historyDateProvider.notifier).state = picked;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final e in _statusLabels.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(e.value),
                      selected: status == e.key,
                      selectedColor: SaporeColors.terracotta,
                      labelStyle: TextStyle(color: status == e.key ? Colors.white : SaporeColors.textDark),
                      onSelected: (_) => ref.read(historyStatusProvider.notifier).state = e.key,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: list.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('$e'))),
              data: (orders) => RefreshIndicator(
                onRefresh: () async => ref.refresh(orderListProvider.future),
                child: orders.isEmpty
                    ? ListView(children: const [SizedBox(height: 120), Center(child: Text('Tidak ada order'))])
                    : ListView.separated(
                        itemCount: orders.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) => _OrderTile(o: orders[i]),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.o});
  final OrderDetail o;

  @override
  Widget build(BuildContext context) {
    final time = o.createdAt == null ? '' : DateFormat('HH:mm').format(o.createdAt!);
    final where = (o.tableLabel?.isNotEmpty ?? false) ? o.tableLabel! : (o.orderType == 'take_away' ? 'Take Away' : 'Dine In');
    return ListTile(
      onTap: () => context.push('/orders/${o.uuid}'),
      title: Text(o.order.number, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('$time · $where${o.refundedTotal > 0 ? ' · ada retur' : ''}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(rupiah.format(o.order.total), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          StatusBadge(o.order.status),
        ],
      ),
    );
  }
}
