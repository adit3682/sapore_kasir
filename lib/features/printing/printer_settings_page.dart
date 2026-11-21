import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/sapore_theme.dart';
import 'printer_controller.dart';

class PrinterSettingsPage extends ConsumerWidget {
  const PrinterSettingsPage({super.key});

  void _toast(BuildContext c, String m) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sel = ref.watch(printerControllerProvider);
    final devices = ref.watch(pairedPrintersProvider);
    final ctrl = ref.read(printerControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Printer Struk'),
        actions: [
          IconButton(tooltip: 'Muat ulang', icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(pairedPrintersProvider)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.print),
              title: Text(sel.isSet ? sel.name ?? sel.mac! : 'Belum ada printer dipilih'),
              subtitle: sel.isSet ? Text(sel.mac!) : null,
              trailing: sel.isSet ? IconButton(icon: const Icon(Icons.close), onPressed: ctrl.clear) : null,
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            icon: const Icon(Icons.receipt),
            label: const Text('Cetak Tes'),
            onPressed: sel.isSet
                ? () async {
                    final err = await ctrl.printTest();
                    if (context.mounted) _toast(context, err ?? 'Perintah cetak terkirim');
                  }
                : null,
          ),
          const SizedBox(height: 20),
          const Text('Printer yang sudah dipasangkan', style: TextStyle(fontWeight: FontWeight.w800, color: SaporeColors.navy)),
          const SizedBox(height: 4),
          const Text(
            'Pasangkan (pair) printer lebih dulu lewat Pengaturan Bluetooth HP, lalu muat ulang daftar ini.',
            style: TextStyle(fontSize: 12, color: SaporeColors.textMuted),
          ),
          const SizedBox(height: 8),
          devices.when(
            loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Padding(padding: const EdgeInsets.all(8), child: Text('$e')),
            data: (list) => list.isEmpty
                ? const Padding(padding: EdgeInsets.all(8), child: Text('Belum ada perangkat Bluetooth yang dipasangkan.'))
                : Column(children: [
                    for (final d in list)
                      RadioListTile<String>(
                        value: d.mac,
                        groupValue: sel.mac,
                        title: Text(d.name),
                        subtitle: Text(d.mac),
                        onChanged: (_) => ctrl.select(d),
                      ),
                  ]),
          ),
        ],
      ),
    );
  }
}
