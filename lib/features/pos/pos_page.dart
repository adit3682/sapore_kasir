import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/sapore_theme.dart';
import '../auth/auth_controller.dart';
import '../catalog/catalog_controller.dart';
import '../catalog/catalog_item.dart';
import '../orders/pending_queue.dart';
import 'cart.dart';

final _rupiah = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

final _searchProvider = StateProvider.autoDispose<String>((_) => '');
final _categoryProvider = StateProvider.autoDispose<String?>((_) => null);

class PosPage extends ConsumerWidget {
  const PosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final catalog = ref.watch(catalogControllerProvider);
    final cart = ref.watch(cartProvider);
    final pendingCount = ref.watch(pendingQueueProvider).length;
    final wide = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      appBar: AppBar(
        title: Text('SAPORÉ · Kasir${user?.branch != null ? ' · ${user!.branch}' : ''}'),
        actions: [
          IconButton(
            tooltip: 'Printer struk',
            icon: const Icon(Icons.print_outlined),
            onPressed: () => context.push('/printer'),
          ),
          IconButton(
            tooltip: 'Riwayat order',
            icon: const Icon(Icons.receipt_long),
            onPressed: () => context.push('/orders'),
          ),
          IconButton(
            tooltip: 'Antrean offline',
            icon: Badge(
              label: Text('$pendingCount'),
              isLabelVisible: pendingCount > 0,
              child: const Icon(Icons.cloud_upload_outlined),
            ),
            onPressed: () => context.push('/pending'),
          ),
          IconButton(
            tooltip: 'Sinkron katalog',
            icon: const Icon(Icons.sync),
            onPressed: () => ref.read(catalogControllerProvider.notifier).sync(),
          ),
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('$e'),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: () => ref.invalidate(catalogControllerProvider), child: const Text('Coba lagi')),
          ]),
        ),
        data: (state) => Column(
          children: [
            if (state.syncError != null)
              Container(
                width: double.infinity,
                color: SaporeColors.terracotta.withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text('Mode offline: memakai katalog tersimpan. ${state.syncError}',
                    style: const TextStyle(fontSize: 12)),
              ),
            Expanded(
              child: wide
                  ? Row(children: [
                      Expanded(child: _CatalogPane(items: state.items, categories: state.categories)),
                      const SizedBox(width: 340, child: _CartPanel()),
                    ])
                  : _CatalogPane(items: state.items, categories: state.categories),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide || cart.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: SaporeColors.warmCream,
                    builder: (_) => SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.8,
                      child: const _CartPanel(inSheet: true),
                    ),
                  ),
                  child: Text('Pesanan (${cart.count}) · ${_rupiah.format(cart.subtotal)}'),
                ),
              ),
            ),
    );
  }
}

class _CatalogPane extends ConsumerWidget {
  const _CatalogPane({required this.items, required this.categories});
  final List<CatalogItem> items;
  final List<String> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = ref.watch(_searchProvider).toLowerCase();
    final cat = ref.watch(_categoryProvider);
    final shown = items.where((i) {
      if (cat != null && (i.category ?? 'Lainnya') != cat) return false;
      return q.isEmpty || i.name.toLowerCase().contains(q) || i.code.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: TextField(
            onChanged: (v) => ref.read(_searchProvider.notifier).state = v,
            decoration: const InputDecoration(hintText: 'Cari menu...', prefixIcon: Icon(Icons.search), isDense: true),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              for (final c in [null, ...categories])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c ?? 'Semua'),
                    selected: cat == c,
                    selectedColor: SaporeColors.terracotta,
                    labelStyle: TextStyle(color: cat == c ? Colors.white : SaporeColors.textDark),
                    onSelected: (_) => ref.read(_categoryProvider.notifier).state = c,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: shown.isEmpty
              ? const Center(child: Text('Menu tidak ditemukan'))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    childAspectRatio: 1.45,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: shown.length,
                  itemBuilder: (_, i) => _MenuCard(item: shown[i]),
                ),
        ),
      ],
    );
  }
}

class _MenuCard extends ConsumerWidget {
  const _MenuCard({required this.item});
  final CatalogItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPackage = item.type == 'package';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ref.read(cartProvider.notifier).add(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 4, color: isPackage ? SaporeColors.terracotta : SaporeColors.navy),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Row(children: [
                      Expanded(
                        child: Text(_rupiah.format(item.price),
                            style: const TextStyle(color: SaporeColors.terracotta, fontWeight: FontWeight.w600)),
                      ),
                      const Icon(Icons.add_circle, color: SaporeColors.navy),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartPanel extends ConsumerWidget {
  const _CartPanel({this.inSheet = false});
  final bool inSheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);

    return Container(
      color: SaporeColors.warmCream,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Pesanan Saat Ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: SaporeColors.navy)),
          ),
          Expanded(
            child: cart.isEmpty
                ? const Center(child: Text('Belum ada item', style: TextStyle(color: SaporeColors.textMuted)))
                : ListView(
                    children: [
                      for (final l in cart.lines)
                        ListTile(
                          title: Text(l.item.name),
                          subtitle: Text('${_rupiah.format(l.item.price)} × ${l.qty}'),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => notifier.decrement(l.item.key)),
                            Text(_rupiah.format(l.total), style: const TextStyle(fontWeight: FontWeight.w700)),
                            IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => notifier.remove(l.item.key)),
                          ]),
                        ),
                    ],
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: SaporeColors.cardCream,
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Subtotal'),
                Text(_rupiah.format(cart.subtotal), style: const TextStyle(fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 4),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Pajak & service dihitung server saat pembayaran.',
                    style: TextStyle(fontSize: 11, color: SaporeColors.textMuted)),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: cart.isEmpty
                    ? null
                    : () {
                        final router = GoRouter.of(context);
                        if (inSheet) Navigator.of(context).pop();
                        router.push('/checkout');
                      },
                child: const Text('Bayar Sekarang'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: cart.isEmpty ? null : notifier.clear, child: const Text('Kosongkan')),
            ]),
          ),
        ],
      ),
    );
  }
}
