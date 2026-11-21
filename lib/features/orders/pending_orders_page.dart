import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/sapore_theme.dart';
import 'payment_method.dart';
import 'pending_queue.dart';

class PendingOrdersPage extends ConsumerWidget {
  const PendingOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(pendingQueueProvider);
    final fmt = DateFormat('d MMM HH:mm', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Antrean Offline'),
        actions: [
          TextButton(
            onPressed: () => ref.read(pendingQueueProvider.notifier).flush(),
            child: const Text('Kirim sekarang', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: list.isEmpty
          ? const Center(child: Text('Tidak ada pesanan menunggu'))
          : ListView(
              children: [
                for (final p in list)
                  ListTile(
                    leading: Icon(
                      p.status == PendingStatus.pending ? Icons.schedule : Icons.error_outline,
                      color: p.status == PendingStatus.pending ? SaporeColors.terracotta : Theme.of(context).colorScheme.error,
                    ),
                    title: Text('${p.itemCount} item · ${PaymentMethod.fromCode(p.methodCode).label}'),
                    subtitle: Text(p.status == PendingStatus.pending
                        ? 'Menunggu dikirim · ${fmt.format(p.createdAt)}'
                        : 'Perlu tindakan: ${p.error}\nOrder tetap Open di server; buka Riwayat Order lalu pilih Bayar atau Void.'),
                    isThreeLine: p.status == PendingStatus.needsAttention,
                    trailing: p.status == PendingStatus.needsAttention
                        ? IconButton(
                            tooltip: 'Hapus dari antrean',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => ref.read(pendingQueueProvider.notifier).discard(p.uuid),
                          )
                        : null,
                  ),
              ],
            ),
    );
  }
}
