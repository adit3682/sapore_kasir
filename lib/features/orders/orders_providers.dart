import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'order_detail.dart';
import 'orders_repository.dart';

final historyStatusProvider = StateProvider.autoDispose<String?>((_) => null);
final historyDateProvider = StateProvider.autoDispose<DateTime>((_) => DateTime.now());

final orderListProvider = FutureProvider.autoDispose<List<OrderDetail>>((ref) {
  final status = ref.watch(historyStatusProvider);
  final date = ref.watch(historyDateProvider);
  return ref.watch(ordersRepositoryProvider).list(status: status, date: DateFormat('yyyy-MM-dd').format(date));
});

final orderDetailProvider = FutureProvider.autoDispose.family<OrderDetail, String>(
  (ref, uuid) => ref.watch(ordersRepositoryProvider).get(uuid),
);

typedef ReceiptKey = ({String uuid, String? returnUuid});

final receiptProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, ReceiptKey>(
  (ref, k) => ref.watch(ordersRepositoryProvider).receipt(k.uuid, returnUuid: k.returnUuid),
);
