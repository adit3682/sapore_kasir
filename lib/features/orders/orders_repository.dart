import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import 'order_detail.dart';
import 'order_models.dart';

class OrdersRepository {
  OrdersRepository(this._dio);
  final Dio _dio;

  Future<OrderDto> _post(String path, Map<String, dynamic> body) async {
    try {
      final r = await _dio.post(path, data: body);
      return OrderDto.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Membuat order Open (belum dibayar) agar total + pajak + service dihitung server.
  Future<OrderDto> create(OrderDraft d) => _post('/orders', d.toJson());

  Future<OrderDto> pay(String uuid, String method, int? amountPaid) =>
      _post('/orders/$uuid/pay', {'method': method, if (amountPaid != null) 'amount_paid': amountPaid});

  /// Buat + bayar sekaligus. Idempoten: aman dikirim ulang dengan payload yang sama.
  Future<OrderDto> submitFull(Map<String, dynamic> payload) => _post('/orders', payload);

  Future<void> voidOrder(String uuid) => _post('/orders/$uuid/void', {});

  Future<List<OrderDetail>> list({String? status, String? date}) async {
    try {
      final r = await _dio.get('/orders', queryParameters: {
        if (status != null) 'status': status,
        if (date != null) 'date': date,
      });
      final d = r.data;
      final raw = d is List ? d : (d as Map)['data'] as List;
      return raw.map((e) => OrderDetail.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<OrderDetail> get(String uuid) async {
    try {
      final r = await _dio.get('/orders/$uuid');
      return OrderDetail.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Struk order, atau struk retur bila [returnUuid] diisi.
  Future<Map<String, dynamic>> receipt(String uuid, {String? returnUuid}) async {
    try {
      final r = await _dio.get(returnUuid == null ? '/orders/$uuid/receipt' : '/orders/$uuid/returns/$returnUuid/receipt');
      return Map<String, dynamic>.from((r.data as Map)['data'] as Map);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Retur (Owner/Manager). Idempoten per uuid retur.
  Future<OrderDetail> refund(String orderUuid, Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/orders/$orderUuid/returns', data: body);
      return OrderDetail.fromJson(r.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}

final ordersRepositoryProvider = Provider((ref) => OrdersRepository(ref.watch(dioProvider)));
