import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../printing/printer_controller.dart';
import 'orders_providers.dart';
import 'receipt_text.dart';

class ReceiptPage extends ConsumerWidget {
  const ReceiptPage({super.key, required this.uuid, this.returnUuid});
  final String uuid;
  final String? returnUuid; // diisi untuk struk retur

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipt = ref.watch(receiptProvider((uuid: uuid, returnUuid: returnUuid)));
    return Scaffold(
      appBar: AppBar(title: Text(returnUuid == null ? 'Struk' : 'Struk Retur')),
      body: receipt.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('$e'))),
        data: (data) {
          final text = formatReceipt(data);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SelectableText(text, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.35)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('Cetak Struk'),
                onPressed: () async {
                  if (!ref.read(printerControllerProvider).isSet) {
                    context.push('/printer');
                    return;
                  }
                  final err = await ref.read(printerControllerProvider.notifier).printReceipt(data);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Struk dikirim ke printer')));
                  }
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Salin teks struk'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Struk disalin')));
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
