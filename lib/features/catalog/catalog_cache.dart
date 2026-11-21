import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'catalog_item.dart';

/// Cache katalog di perangkat agar kasir tetap bisa memilih menu saat offline.
class CatalogCache {
  static const _itemsKey = 'catalog_items_v1';
  static const _syncKey = 'catalog_server_time_v1';

  Future<({List<CatalogItem> items, String? serverTime})> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_itemsKey);
    final items = raw == null
        ? <CatalogItem>[]
        : (jsonDecode(raw) as List).map((e) => CatalogItem.fromJson(e as Map<String, dynamic>)).toList();
    return (items: items, serverTime: p.getString(_syncKey));
  }

  Future<void> save(List<CatalogItem> items, String serverTime) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_itemsKey, jsonEncode(items.map((e) => e.toJson()).toList()));
    await p.setString(_syncKey, serverTime);
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_itemsKey);
    await p.remove(_syncKey);
  }
}
