import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sapore_kasir/core/network/api_exception.dart';
import 'package:sapore_kasir/features/auth/auth_controller.dart';
import 'package:sapore_kasir/features/orders/order_models.dart';
import 'package:sapore_kasir/features/orders/orders_repository.dart';
import 'package:sapore_kasir/features/orders/payment_method.dart';
import 'package:sapore_kasir/features/orders/pending_queue.dart';

class _FakeAuth extends AuthController {
  @override
  AuthState build() => const AuthState(AuthStatus.signedOut);
}

class _FakeRepo extends OrdersRepository {
  _FakeRepo(this.behavior) : super(Dio());
  final Future<OrderDto> Function() behavior;
  int calls = 0;
  @override
  Future<OrderDto> submitFull(Map<String, dynamic> payload) {
    calls++;
    return behavior();
  }
}

OrderDto _ok() => OrderDto.fromJson({
      'uuid': 'u', 'number': 'ORD-1', 'status': 'paid', 'subtotal': '100000.00', 'tax_rate': '10.00',
      'tax_amount': '10000.00', 'service_rate': '5.00', 'service_amount': '5000.00', 'total': '115000.00',
      'payment_method': 'cash', 'amount_paid': '120000.00', 'change_amount': '5000.00',
    });

Map<String, dynamic> _payload(String uuid) => {
      'uuid': uuid,
      'items': [{'type': 'menu', 'id': 1, 'qty': 2}],
      'pay': {'method': 'cash', 'amount_paid': 120000},
    };

ProviderContainer _container(_FakeRepo repo) => ProviderContainer(overrides: [
      authControllerProvider.overrideWith(_FakeAuth.new),
      ordersRepositoryProvider.overrideWithValue(repo),
    ]);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('cashSuggestions: uang pas lalu pembulatan tanpa duplikat', () {
    expect(cashSuggestions(267950), [267950, 270000, 300000]);
    expect(cashSuggestions(40000), [40000, 50000, 100000]);
  });

  test('OrderDto mem-parse angka string dan total server', () {
    final o = _ok();
    expect(o.total, 115000);
    expect(o.changeAmount, 5000);
    expect(o.taxRate, 10);
  });

  test('OrderDraft hanya menyertakan field terisi', () {
    final j = OrderDraft(uuid: 'x', orderType: 'dine_in', items: const [], tableLabel: '', notes: '').toJson();
    expect(j.containsKey('table_label'), isFalse);
    expect(j.containsKey('pay'), isFalse);
  });

  test('antrean: sukses -> dihapus', () async {
    final repo = _FakeRepo(() async => _ok());
    final c = _container(repo);
    addTearDown(c.dispose);
    final q = c.read(pendingQueueProvider.notifier);
    await q.enqueue(_payload('a'), autoFlush: false);
    expect(c.read(pendingQueueProvider).length, 1);
    await q.flush();
    expect(c.read(pendingQueueProvider), isEmpty);
  });

  test('antrean: jaringan putus -> tetap pending dan berhenti', () async {
    final repo = _FakeRepo(() async => throw ApiException('offline', network: true));
    final c = _container(repo);
    addTearDown(c.dispose);
    final q = c.read(pendingQueueProvider.notifier);
    await q.enqueue(_payload('a'), autoFlush: false);
    await q.enqueue(_payload('b'), autoFlush: false);
    await q.flush();
    expect(repo.calls, 1); // berhenti di kegagalan pertama
    expect(c.read(pendingQueueProvider).every((p) => p.status == PendingStatus.pending), isTrue);
  });

  test('antrean: ditolak server (422) -> needsAttention, tidak diulang', () async {
    final repo = _FakeRepo(() async => throw ApiException('Uang kurang', statusCode: 422));
    final c = _container(repo);
    addTearDown(c.dispose);
    final q = c.read(pendingQueueProvider.notifier);
    await q.enqueue(_payload('a'), autoFlush: false);
    await q.flush();
    final p = c.read(pendingQueueProvider).single;
    expect(p.status, PendingStatus.needsAttention);
    expect(p.error, 'Uang kurang');
    await q.flush();
    expect(repo.calls, 1);
  });

  test('antrean: uuid sama tidak dobel, dan tersimpan lintas restart', () async {
    final repo = _FakeRepo(() async => throw ApiException('offline', network: true));
    final c = _container(repo);
    final q = c.read(pendingQueueProvider.notifier);
    await q.enqueue(_payload('a'), autoFlush: false);
    await q.enqueue(_payload('a'), autoFlush: false);
    expect(c.read(pendingQueueProvider).length, 1);
    c.dispose();

    final c2 = _container(repo);
    addTearDown(c2.dispose);
    final q2 = c2.read(pendingQueueProvider.notifier);
    await q2.load();
    expect(c2.read(pendingQueueProvider).single.uuid, 'a');
  });
}
