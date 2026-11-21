import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import 'catalog_item.dart';

class CatalogRepository {
  CatalogRepository(this._dio);
  final Dio _dio;

  /// Tanpa [updatedSince]: semua item aktif. Dengan: item yang berubah (termasuk yang dinonaktifkan).
  Future<({String serverTime, List<CatalogItem> items})> fetch({String? updatedSince}) async {
    try {
      final r = await _dio.get('/catalog', queryParameters: {
        if (updatedSince != null) 'updated_since': updatedSince,
      });
      final list = (r.data['data'] as List)
          .map((e) => CatalogItem.fromJson(e as Map<String, dynamic>))
          .toList();
      return (serverTime: r.data['server_time'] as String, items: list);
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}

final catalogRepositoryProvider = Provider((ref) => CatalogRepository(ref.watch(dioProvider)));
