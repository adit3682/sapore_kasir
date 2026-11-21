import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import 'catalog_cache.dart';
import 'catalog_item.dart';
import 'catalog_repository.dart';

/// Menggabungkan perubahan dari server ke daftar lokal.
/// Item yang dinonaktifkan di server dihapus dari daftar kasir.
List<CatalogItem> mergeCatalog(List<CatalogItem> current, List<CatalogItem> changes) {
  final map = {for (final i in current) i.key: i};
  for (final c in changes) {
    if (c.isActive) {
      map[c.key] = c;
    } else {
      map.remove(c.key);
    }
  }
  final list = map.values.toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return list;
}

class CatalogState {
  const CatalogState({this.items = const [], this.syncError});
  final List<CatalogItem> items;
  final String? syncError; // diisi bila sinkron gagal tapi cache tersedia (mode offline)

  List<String> get categories {
    final set = <String>{for (final i in items) i.category ?? 'Lainnya'};
    return set.toList()..sort();
  }
}

class CatalogController extends AsyncNotifier<CatalogState> {
  final _cache = CatalogCache();

  @override
  Future<CatalogState> build() async {
    final cached = await _cache.load();
    if (cached.items.isNotEmpty) {
      // Tampilkan cache dulu, sinkron di latar belakang.
      Future.microtask(sync);
      return CatalogState(items: cached.items);
    }
    return _sync(cached.items, cached.serverTime, throwOnError: true);
  }

  Future<void> sync() async {
    final current = state.valueOrNull?.items ?? const <CatalogItem>[];
    final cached = await _cache.load();
    state = AsyncData(await _sync(current, cached.serverTime));
  }

  Future<CatalogState> _sync(List<CatalogItem> current, String? since, {bool throwOnError = false}) async {
    try {
      final res = await ref.read(catalogRepositoryProvider).fetch(updatedSince: since);
      final merged = mergeCatalog(current, res.items);
      await _cache.save(merged, res.serverTime);
      return CatalogState(items: merged);
    } on ApiException catch (e) {
      if (throwOnError) rethrow;
      return CatalogState(items: current, syncError: e.message);
    }
  }
}

final catalogControllerProvider =
    AsyncNotifierProvider<CatalogController, CatalogState>(CatalogController.new);
