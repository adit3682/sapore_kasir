import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sapore_kasir/features/catalog/catalog_controller.dart';
import 'package:sapore_kasir/features/catalog/catalog_item.dart';
import 'package:sapore_kasir/features/pos/cart.dart';

CatalogItem item(String type, int id, String name, num price, {bool active = true}) => CatalogItem(
    type: type, id: id, code: '$type$id', name: name, category: 'X', price: price, isActive: active);

void main() {
  test('menu dan paket ber-id sama tidak bertabrakan di keranjang', () {
    final c = ProviderContainer();
    final cart = c.read(cartProvider.notifier);
    cart.add(item('menu', 1, 'Nasi Goreng', 40000));
    cart.add(item('package', 1, 'Paket Family', 125000));
    cart.add(item('menu', 1, 'Nasi Goreng', 40000));
    final s = c.read(cartProvider);
    expect(s.lines.length, 2);
    expect(s.count, 3);
    expect(s.subtotal, 205000);
  });

  test('decrement menghapus baris saat qty habis', () {
    final c = ProviderContainer();
    final cart = c.read(cartProvider.notifier);
    cart.add(item('menu', 1, 'A', 1000));
    cart.decrement('menu-1');
    expect(c.read(cartProvider).isEmpty, isTrue);
  });

  test('mergeCatalog: upsert item aktif, hapus yang dinonaktifkan', () {
    final current = [item('menu', 1, 'A', 1000), item('menu', 2, 'B', 2000)];
    final changes = [item('menu', 1, 'A', 1500), item('menu', 2, 'B', 2000, active: false), item('package', 9, 'C', 9000)];
    final r = mergeCatalog(current, changes);
    expect(r.map((e) => e.key), ['menu-1', 'package-9']);
    expect(r.first.price, 1500);
  });
}
